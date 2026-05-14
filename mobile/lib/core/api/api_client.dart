import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../auth/token_storage.dart';
import 'api_config.dart';

final apiClientProvider = Provider<Dio>((ref) {
  final storage = ref.watch(tokenStorageProvider);
  final dio = Dio(
    BaseOptions(
      baseUrl: ApiConfig.resolvedBaseUrl,
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 20),
      headers: {'Accept': 'application/json'},
    ),
  );

  dio.interceptors.add(
    InterceptorsWrapper(
      onRequest: (options, handler) async {
        final token = await storage.readAccessToken();
        if (token != null && token.isNotEmpty) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        handler.next(options);
      },
      onError: (err, handler) async {
        // 401 olduğunda refresh dene
        if (err.response?.statusCode == 401) {
          final refresh = await storage.readRefreshToken();
          if (refresh != null) {
            try {
              final resp =
                  await Dio(BaseOptions(baseUrl: ApiConfig.resolvedBaseUrl))
                      .post(
                '/auth/refresh',
                data: {'refresh_token': refresh},
              );
              final newAccess = resp.data['access_token'] as String;
              final newRefresh = resp.data['refresh_token'] as String;
              await storage.saveTokens(access: newAccess, refresh: newRefresh);
              final req = err.requestOptions;
              req.headers['Authorization'] = 'Bearer $newAccess';
              final retry = await dio.fetch(req);
              return handler.resolve(retry);
            } catch (_) {
              await storage.clear();
            }
          }
        }
        handler.next(err);
      },
    ),
  );

  return dio;
});
