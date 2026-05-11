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


class MeInfo {
  const MeInfo({
    required this.email,
    required this.fullName,
    required this.role,
    this.tenantId,
    this.tenantName,
    this.tenantLogoUrl,
  });

  final String email;
  final String fullName;
  final String role;
  final String? tenantId;
  final String? tenantName;
  final String? tenantLogoUrl;

  factory MeInfo.fromJson(Map<String, dynamic> j) {
    final tenant = j['tenant'] as Map<String, dynamic>?;
    return MeInfo(
      email: j['email'] as String,
      fullName: j['full_name'] as String,
      role: j['role'] as String,
      tenantId: tenant?['id'] as String?,
      tenantName: tenant?['name'] as String?,
      tenantLogoUrl: tenant?['logo_url'] as String?,
    );
  }
}


/// /auth/me'yi çağırır; auth state değiştiğinde otomatik yenilenir.
final meProvider = FutureProvider<MeInfo?>((ref) async {
  final auth = ref.watch(authControllerProvider);
  if (auth.status != AuthStatus.authenticated) return null;
  final dio = ref.read(apiClientProvider);
  final resp = await dio.get('/auth/me');
  return MeInfo.fromJson(resp.data as Map<String, dynamic>);
});
