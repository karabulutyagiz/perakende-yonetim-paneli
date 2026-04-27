import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _defaultApi = 'http://localhost:8000/api/v1';
final apiBase = const String.fromEnvironment('API_BASE', defaultValue: _defaultApi);

String get wsBase {
  // API_BASE http(s)://.../api/v1 → ws(s)://.../api/v1/ws
  final uri = Uri.parse(apiBase);
  final scheme = uri.scheme == 'https' ? 'wss' : 'ws';
  return uri.replace(scheme: scheme, path: '${uri.path}/ws').toString();
}

const _kAccess = 'gokce.admin.access';
const _kRefresh = 'gokce.admin.refresh';

class AuthTokens {
  const AuthTokens({this.access, this.refresh});
  final String? access;
  final String? refresh;

  bool get isAuthenticated => access != null && access!.isNotEmpty;

  Map<String, dynamic>? get claims {
    final t = access;
    if (t == null || t.isEmpty) return null;
    final parts = t.split('.');
    if (parts.length != 3) return null;
    try {
      var payload = parts[1];
      payload += '=' * ((4 - payload.length % 4) % 4);
      return jsonDecode(utf8.decode(base64Url.decode(payload))) as Map<String, dynamic>;
    } catch (_) {
      return null;
    }
  }

  String? get role => claims?['role'] as String?;
  bool get isPlatformOwner => role == 'platform_owner';
}

class AuthNotifier extends StateNotifier<AuthTokens> {
  AuthNotifier() : super(const AuthTokens());

  /// main.dart bootstrap'ında SharedPreferences'ten yüklenmiş token'larla başlat.
  AuthNotifier.seeded(AuthTokens initial) : super(initial);

  Future<void> setTokens({required String access, required String refresh}) async {
    state = AuthTokens(access: access, refresh: refresh);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kAccess, access);
    await prefs.setString(_kRefresh, refresh);
  }

  Future<void> clear() async {
    state = const AuthTokens();
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_kAccess);
    await prefs.remove(_kRefresh);
  }
}

final tokensProvider =
    StateNotifierProvider<AuthNotifier, AuthTokens>((_) => AuthNotifier());

final dioProvider = Provider<Dio>((ref) {
  final dio = Dio(
    BaseOptions(
      baseUrl: apiBase,
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 20),
    ),
  );

  dio.interceptors.add(InterceptorsWrapper(
    onRequest: (opts, handler) {
      final t = ref.read(tokensProvider).access;
      if (t != null && t.isNotEmpty) {
        opts.headers['Authorization'] = 'Bearer $t';
      }
      handler.next(opts);
    },
    onError: (e, handler) async {
      // 401 → refresh ile tek seferlik yeniden dene
      final already = e.requestOptions.extra['retried'] == true;
      if (e.response?.statusCode != 401 || already) {
        if (kDebugMode) debugPrint('API error: ${e.message}');
        return handler.next(e);
      }
      final refresh = ref.read(tokensProvider).refresh;
      if (refresh == null) {
        await ref.read(tokensProvider.notifier).clear();
        return handler.next(e);
      }
      try {
        final bare = Dio(BaseOptions(baseUrl: apiBase));
        final resp = await bare.post(
          '/auth/refresh',
          data: {'refresh_token': refresh},
        );
        final newAccess = resp.data['access_token'] as String;
        final newRefresh = resp.data['refresh_token'] as String;
        await ref
            .read(tokensProvider.notifier)
            .setTokens(access: newAccess, refresh: newRefresh);

        final req = e.requestOptions;
        req.headers['Authorization'] = 'Bearer $newAccess';
        req.extra['retried'] = true;
        final retry = await dio.fetch(req);
        return handler.resolve(retry);
      } catch (_) {
        await ref.read(tokensProvider.notifier).clear();
        return handler.next(e);
      }
    },
  ));
  return dio;
});
