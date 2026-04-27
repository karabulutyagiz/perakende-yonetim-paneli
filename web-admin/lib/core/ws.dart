import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

import 'api.dart';

class WsEvent {
  const WsEvent(this.event, this.data);
  final String event;
  final Map<String, dynamic> data;
}

class WsClient {
  WsClient(this._ref) {
    _ref.listen<AuthTokens>(tokensProvider, (prev, next) {
      if (next.access != prev?.access) {
        // Platform owner WS'e bağlanmaz (backend zaten reddeder)
        if (next.isAuthenticated && !next.isPlatformOwner) {
          _connect();
        } else {
          _disconnect();
        }
      }
    }, fireImmediately: true);
  }

  final Ref _ref;
  WebSocketChannel? _channel;
  StreamSubscription? _sub;
  Timer? _retry;
  final _controller = StreamController<WsEvent>.broadcast();
  bool _disposed = false;

  Stream<WsEvent> get stream => _controller.stream;

  void _connect() {
    if (_disposed) return;
    final token = _ref.read(tokensProvider).access;
    if (token == null || token.isEmpty) return;
    _disconnect();
    try {
      final uri = Uri.parse('$wsBase?token=$token');
      final ch = WebSocketChannel.connect(uri);
      _channel = ch;
      _sub = ch.stream.listen(
        (raw) {
          try {
            final decoded = jsonDecode(raw as String) as Map<String, dynamic>;
            _controller.add(WsEvent(
              decoded['event'] as String,
              (decoded['data'] as Map).cast<String, dynamic>(),
            ));
          } catch (e) {
            if (kDebugMode) debugPrint('WS parse error: $e');
          }
        },
        onDone: _scheduleReconnect,
        onError: (e) {
          if (kDebugMode) debugPrint('WS error: $e');
          _scheduleReconnect();
        },
        cancelOnError: true,
      );
    } catch (e) {
      if (kDebugMode) debugPrint('WS connect failed: $e');
      _scheduleReconnect();
    }
  }

  void _scheduleReconnect() {
    _retry?.cancel();
    if (_disposed) return;
    final authed = _ref.read(tokensProvider).isAuthenticated;
    if (!authed) return;
    _retry = Timer(const Duration(seconds: 3), _connect);
  }

  void _disconnect() {
    _retry?.cancel();
    _retry = null;
    _sub?.cancel();
    _sub = null;
    _channel?.sink.close();
    _channel = null;
  }

  void dispose() {
    _disposed = true;
    _disconnect();
    _controller.close();
  }
}

final wsClientProvider = Provider<WsClient>((ref) {
  final client = WsClient(ref);
  ref.onDispose(client.dispose);
  return client;
});

/// Helper: verilen event prefix'leri geldiğinde callback tetikler.
/// Caller `StreamSubscription`'ı tutar ve `dispose()` içinde cancel eder.
StreamSubscription<WsEvent> listenWsEvents(
  WidgetRef ref,
  List<String> prefixes,
  void Function(WsEvent) onEvent,
) {
  return ref.read(wsClientProvider).stream.listen((event) {
    if (prefixes.any((p) => event.event.startsWith(p))) {
      onEvent(event);
    }
  });
}
