import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../api/api_config.dart';
import '../marketing/marketing_capture.dart';
import 'token_storage.dart';

enum AuthStatus { loading, unauthenticated, authenticated }

enum AuthRole { tenantOwner, customer, platformOwner, unknown }

class AuthState {
  const AuthState(this.status,
      {this.role = AuthRole.unknown, this.errorMessage});
  final AuthStatus status;
  final AuthRole role;
  final String? errorMessage;

  bool get isCustomer => role == AuthRole.customer;
  bool get isTenantOwner => role == AuthRole.tenantOwner;
}

class AuthController extends StateNotifier<AuthState> {
  AuthController(this._ref) : super(const AuthState(AuthStatus.loading)) {
    _bootstrap();
  }

  AuthController.marketing()
      : _ref = null,
        super(const AuthState(
          AuthStatus.authenticated,
          role: AuthRole.tenantOwner,
        ));

  final Ref? _ref;

  Dio _dio({String? accessToken}) {
    return Dio(
      BaseOptions(
        baseUrl: ApiConfig.resolvedBaseUrl,
        connectTimeout: const Duration(seconds: 15),
        receiveTimeout: const Duration(seconds: 20),
        headers: {
          'Accept': 'application/json',
          if (accessToken != null && accessToken.isNotEmpty)
            'Authorization': 'Bearer $accessToken',
        },
      ),
    );
  }

  Future<void> _bootstrap() async {
    if (kMarketingCapture) {
      state = const AuthState(
        AuthStatus.authenticated,
        role: AuthRole.tenantOwner,
      );
      return;
    }
    try {
      final storage = _ref!.read(tokenStorageProvider);
      final token = await storage
          .readAccessToken()
          .timeout(const Duration(seconds: 3), onTimeout: () => null);
      if (_isTokenUsable(token)) {
        state = AuthState(
          AuthStatus.authenticated,
          role: _roleFromToken(token),
        );
        return;
      }
      try {
        await storage.clear().timeout(const Duration(seconds: 2));
      } catch (_) {}
    } catch (_) {
      // Keychain/SharedPreferences erişimi başarısız olursa bile login'e düş;
      // aksi halde app açılışında sonsuza kadar loading'de takılır.
    }
    state = const AuthState(AuthStatus.unauthenticated);
  }

  Future<void> applyTokens({
    required String access,
    required String refresh,
  }) async {
    await _ref!.read(tokenStorageProvider).saveTokens(
          access: access,
          refresh: refresh,
        );
    state = AuthState(
      AuthStatus.authenticated,
      role: _roleFromToken(access),
    );
  }

  Future<void> clearSession({String? errorMessage}) async {
    await _ref!.read(tokenStorageProvider).clear();
    state = AuthState(
      AuthStatus.unauthenticated,
      errorMessage: errorMessage,
    );
  }

  Future<bool> login(String email, String password) async {
    try {
      final resp = await _dio().post(
        '/auth/login',
        data: {'email': email, 'password': password},
      );
      await applyTokens(
        access: resp.data['access_token'] as String,
        refresh: resp.data['refresh_token'] as String,
      );
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
    final accessToken =
        await _ref!.read(tokenStorageProvider).readAccessToken();
    try {
      await _dio(accessToken: accessToken).post('/auth/logout');
    } catch (_) {
      // backend ulaşılamıyorsa bile lokal token'ı temizle
    }
    await clearSession();
  }

  /// Apple 5.1.1(v) + Google Play account deletion gereği uygulama içinden
  /// kalıcı hesap silme. TENANT_OWNER ise tüm tenant verisi silinir.
  /// Başarıda lokal oturum temizlenir ve true döner.
  Future<({bool ok, String? error})> deleteAccount({
    required String password,
    required String confirm,
  }) async {
    final accessToken =
        await _ref!.read(tokenStorageProvider).readAccessToken();
    try {
      await _dio(accessToken: accessToken).delete(
        '/auth/account',
        data: {'password': password, 'confirm': confirm},
      );
      await clearSession();
      return (ok: true, error: null);
    } on DioException catch (e) {
      String msg = 'Hesap silinemedi';
      final data = e.response?.data;
      if (data is Map && data['detail'] is String) {
        msg = data['detail'] as String;
      }
      return (ok: false, error: msg);
    } catch (_) {
      return (ok: false, error: 'Sunucuya ulaşılamadı');
    }
  }

  AuthRole _roleFromToken(String? token) {
    final data = _claimsFromToken(token);
    if (data == null) return AuthRole.unknown;
    try {
      return switch (data['role']) {
        'tenant_owner' => AuthRole.tenantOwner,
        'customer' => AuthRole.customer,
        'platform_owner' => AuthRole.platformOwner,
        _ => AuthRole.unknown,
      };
    } catch (_) {
      return AuthRole.unknown;
    }
  }

  Map<String, dynamic>? _claimsFromToken(String? token) {
    if (token == null || token.isEmpty) return null;
    final parts = token.split('.');
    if (parts.length != 3) return null;
    try {
      var payload = parts[1];
      payload += '=' * ((4 - payload.length % 4) % 4);
      return jsonDecode(utf8.decode(base64Url.decode(payload)))
          as Map<String, dynamic>;
    } catch (_) {
      return null;
    }
  }

  bool _isTokenUsable(String? token) {
    final claims = _claimsFromToken(token);
    if (claims == null) return false;
    final exp = claims['exp'];
    if (exp is! num) return false;
    final expiry = DateTime.fromMillisecondsSinceEpoch(
      exp.toInt() * 1000,
      isUtc: true,
    );
    return expiry.isAfter(DateTime.now().toUtc());
  }
}

final authControllerProvider = StateNotifierProvider<AuthController, AuthState>(
    (ref) => AuthController(ref));

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
  final token = await ref.read(tokenStorageProvider).readAccessToken();
  if (token == null || token.isEmpty) return null;
  try {
    final resp = await Dio(
      BaseOptions(
        baseUrl: ApiConfig.resolvedBaseUrl,
        headers: {'Authorization': 'Bearer $token'},
      ),
    ).get('/auth/me');
    return MeInfo.fromJson(resp.data as Map<String, dynamic>);
  } on DioException catch (e) {
    if (e.response?.statusCode == 401) {
      await ref.read(authControllerProvider.notifier).clearSession();
      return null;
    }
    rethrow;
  }
});
