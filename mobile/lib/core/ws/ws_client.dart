import 'dart:async';
import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

import '../api/api_config.dart';
import '../auth/token_storage.dart';

class WsEvent {
  const WsEvent(this.event, this.data);
  final String event;
  final Map<String, dynamic> data;
}

class WsClient {
  WsClient(this._ref);
  final Ref _ref;
  WebSocketChannel? _channel;
  final _controller = StreamController<WsEvent>.broadcast();

  Stream<WsEvent> get stream => _controller.stream;

  Future<void> connect() async {
    final token = await _ref.read(tokenStorageProvider).readAccessToken();
    if (token == null) return;
    // Uri.parse bazı yapılandırmalarda port=0 ile dönebiliyor; port'u açıkça
    // ws→80, wss→443 olarak set et.
    final parsed = Uri.parse('${ApiConfig.resolvedWsUrl}?token=$token');
    final port = parsed.hasPort && parsed.port != 0
        ? parsed.port
        : (parsed.scheme == 'wss' ? 443 : 80);
    final uri = parsed.replace(port: port);
    _channel = WebSocketChannel.connect(uri);
    _channel!.stream.listen(
      (raw) {
        try {
          final decoded = jsonDecode(raw as String) as Map<String, dynamic>;
          _controller.add(WsEvent(
            decoded['event'] as String,
            (decoded['data'] as Map).cast<String, dynamic>(),
          ));
        } catch (_) {}
      },
      onDone: () => _reconnectSoon(),
      onError: (_) => _reconnectSoon(),
    );
  }

  void _reconnectSoon() {
    Future.delayed(const Duration(seconds: 3), connect);
  }

  void dispose() {
    _channel?.sink.close();
    _controller.close();
  }
}

final wsClientProvider = Provider<WsClient>((ref) {
  final client = WsClient(ref);
  ref.onDispose(client.dispose);
  return client;
});
