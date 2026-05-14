import 'dart:io' show Platform;

class ApiConfig {
  static const _androidHost = '10.0.2.2:8000';
  static const _localHost = '127.0.0.1:8000';

  // Android emülatöründe 10.0.2.2, iOS simulator'da localhost kullanılmalı.
  static String get _defaultHost =>
      Platform.isAndroid ? _androidHost : _localHost;

  static const baseUrl = String.fromEnvironment(
    'API_BASE',
    defaultValue: '',
  );

  static String get resolvedBaseUrl =>
      baseUrl.isNotEmpty ? baseUrl : 'http://$_defaultHost/api/v1';

  static const wsUrl = String.fromEnvironment(
    'WS_BASE',
    defaultValue: '',
  );

  static String get resolvedWsUrl =>
      wsUrl.isNotEmpty ? wsUrl : 'ws://$_defaultHost/api/v1/ws';
}
