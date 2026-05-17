import 'dart:async';
import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

import '../api/api_config.dart';
import '../auth/auth_controller.dart';
import '../auth/token_storage.dart';

class WsEvent {
  const WsEvent(this.event, this.data);
  final String event;
  final Map<String, dynamic> data;
}

class WsClient {
  WsClient(this._ref) {
    _ref.listen<AuthState>(authControllerProvider, (prev, next) {
      final shouldConnect =
          next.status == AuthStatus.authenticated && next.isTenantOwner;
      if (shouldConnect) {
        connect();
      } else {
        _disconnect();
      }
    }, fireImmediately: true);
  }

  final Ref _ref;
  WebSocketChannel? _channel;
  StreamSubscription? _sub;
  Timer? _retry;
  final _controller = StreamController<WsEvent>.broadcast();
  bool _disposed = false;
  bool _connecting = false;

  Stream<WsEvent> get stream => _controller.stream;

  Future<void> connect() async {
    if (_disposed || _connecting || _channel != null) return;
    final auth = _ref.read(authControllerProvider);
    if (!auth.isTenantOwner) return;

    final token = await _ref.read(tokenStorageProvider).readAccessToken();
    if (token == null) return;
    _connecting = true;
    try {
      // Uri.parse bazı yapılandırmalarda port=0 ile dönebiliyor; port'u açıkça
      // ws→80, wss→443 olarak set et.
      final parsed = Uri.parse('${ApiConfig.resolvedWsUrl}?token=$token');
      final port = parsed.hasPort && parsed.port != 0
          ? parsed.port
          : (parsed.scheme == 'wss' ? 443 : 80);
      final uri = parsed.replace(port: port);
      final channel = WebSocketChannel.connect(uri);
      _channel = channel;
      _sub = channel.stream.listen(
        (raw) {
          try {
            final decoded = jsonDecode(raw as String) as Map<String, dynamic>;
            _controller.add(WsEvent(
              decoded['event'] as String,
              (decoded['data'] as Map).cast<String, dynamic>(),
            ));
          } catch (_) {}
        },
        onDone: _handleDisconnect,
        onError: (_) => _handleDisconnect(),
        cancelOnError: true,
      );
    } catch (_) {
      _channel = null;
      _reconnectSoon();
    } finally {
      _connecting = false;
    }
  }

  void _handleDisconnect() {
    _sub?.cancel();
    _sub = null;
    _channel = null;
    _reconnectSoon();
  }

  void _reconnectSoon() {
    if (_disposed) return;
    final auth = _ref.read(authControllerProvider);
    if (auth.status != AuthStatus.authenticated || !auth.isTenantOwner) {
      return;
    }
    _retry?.cancel();
    _retry = Timer(const Duration(seconds: 3), () {
      if (!_disposed) connect();
    });
  }

  void _disconnect() {
    _retry?.cancel();
    _retry = null;
    _sub?.cancel();
    _sub = null;
    _channel?.sink.close();
    _channel = null;
    _connecting = false;
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
