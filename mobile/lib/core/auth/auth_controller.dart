import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../api/api_client.dart';
import 'token_storage.dart';

enum AuthStatus { loading, unauthenticated, authenticated }

class AuthState {
  const AuthState(this.status, {this.errorMessage});
  final AuthStatus status;
  final String? errorMessage;
}

class AuthController extends StateNotifier<AuthState> {
  AuthController(this._ref) : super(const AuthState(AuthStatus.loading)) {
    _bootstrap();
  }

  final Ref _ref;

  Future<void> _bootstrap() async {
    final token = await _ref.read(tokenStorageProvider).readAccessToken();
    state = AuthState(
      token != null && token.isNotEmpty ? AuthStatus.authenticated : AuthStatus.unauthenticated,
    );
  }

  Future<bool> login(String email, String password) async {
    try {
      final dio = _ref.read(apiClientProvider);
      final resp = await dio.post(
        '/auth/login',
        data: {'email': email, 'password': password},
      );
      await _ref.read(tokenStorageProvider).saveTokens(
            access: resp.data['access_token'] as String,
            refresh: resp.data['refresh_token'] as String,
          );
      state = const AuthState(AuthStatus.authenticated);
      return true;
    } on DioException catch (e) {
      String msg = 'Giriş başarısız: e-posta veya parola hatalı';
      final data = e.response?.data;
      if (data is Map && data['detail'] is String) {
        msg = data['detail'] as String;
      }
      state = AuthState(AuthStatus.unauthenticated, errorMessage: msg);
      return false;
    } catch (_) {
      state = const AuthState(
        AuthStatus.unauthenticated,
        errorMessage: 'Giriş başarısız',
      );
      return false;
    }
  }

  Future<void> logout() async {
    try {
      await _ref.read(apiClientProvider).post('/auth/logout');
    } catch (_) {
      // backend ulaşılamıyorsa bile lokal token'ı temizle
    }
    await _ref.read(tokenStorageProvider).clear();
    state = const AuthState(AuthStatus.unauthenticated);
  }
}

final authControllerProvider =
    StateNotifierProvider<AuthController, AuthState>((ref) => AuthController(ref));
