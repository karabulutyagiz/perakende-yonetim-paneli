import 'dart:io' show Platform;

import 'package:flutter/foundation.dart' show kReleaseMode;

class ApiConfig {
  static const _androidHost = '10.0.2.2:8000';
  static const _localHost = '127.0.0.1:8000';

  // Production kökü. Release build'lerde --dart-define unutulsa bile uygulama
  // localhost yerine gerçek API'ye gider (aksi halde App Store'da cihazda
  // hem giriş hem kayıt 127.0.0.1'e bağlanmaya çalışıp başarısız olur).
  static const _prodBase = 'https://toptanperakende.online/api/v1';
  static const _prodWs = 'wss://toptanperakende.online/api/v1/ws';

  // Android emülatöründe 10.0.2.2, iOS simulator'da localhost kullanılmalı.
  static String get _defaultHost =>
      Platform.isAndroid ? _androidHost : _localHost;

  static const baseUrl = String.fromEnvironment(
    'API_BASE',
    defaultValue: '',
  );

  static String get resolvedBaseUrl {
    if (baseUrl.isNotEmpty) return baseUrl;
    return kReleaseMode ? _prodBase : 'http://$_defaultHost/api/v1';
  }

  static const wsUrl = String.fromEnvironment(
    'WS_BASE',
    defaultValue: '',
  );

  static String get resolvedWsUrl {
    if (wsUrl.isNotEmpty) return wsUrl;
    return kReleaseMode ? _prodWs : 'ws://$_defaultHost/api/v1/ws';
  }
}
