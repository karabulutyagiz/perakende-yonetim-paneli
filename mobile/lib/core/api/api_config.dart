class ApiConfig {
  // Android emülatöründe 10.0.2.2, fiziksel cihazda bilgisayarın LAN IP'si olmalı
  static const baseUrl = String.fromEnvironment(
    'API_BASE',
    defaultValue: 'http://10.0.2.2:8000/api/v1',
  );
  static const wsUrl = String.fromEnvironment(
    'WS_BASE',
    defaultValue: 'ws://10.0.2.2:8000/api/v1/ws',
  );
}
