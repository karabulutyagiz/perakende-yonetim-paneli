import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _kAccess = 'gokce.access_token';
const _kRefresh = 'gokce.refresh_token';

abstract class TokenStorage {
  Future<String?> readAccessToken();
  Future<String?> readRefreshToken();
  Future<void> saveTokens({required String access, required String refresh});
  Future<void> clear();
}

class _SecureTokenStorage implements TokenStorage {
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  @override
  Future<String?> readAccessToken() => _storage.read(key: _kAccess);
  @override
  Future<String?> readRefreshToken() => _storage.read(key: _kRefresh);
  @override
  Future<void> saveTokens({required String access, required String refresh}) async {
    await _storage.write(key: _kAccess, value: access);
    await _storage.write(key: _kRefresh, value: refresh);
  }

  @override
  Future<void> clear() async {
    await _storage.delete(key: _kAccess);
    await _storage.delete(key: _kRefresh);
  }
}

class _WebTokenStorage implements TokenStorage {
  String? _accessCache;
  String? _refreshCache;

  @override
  Future<String?> readAccessToken() async {
    if (_accessCache != null) return _accessCache;
    final prefs = await SharedPreferences.getInstance();
    _accessCache = prefs.getString(_kAccess);
    return _accessCache;
  }

  @override
  Future<String?> readRefreshToken() async {
    if (_refreshCache != null) return _refreshCache;
    final prefs = await SharedPreferences.getInstance();
    _refreshCache = prefs.getString(_kRefresh);
    return _refreshCache;
  }

  @override
  Future<void> saveTokens({required String access, required String refresh}) async {
    _accessCache = access;
    _refreshCache = refresh;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kAccess, access);
    await prefs.setString(_kRefresh, refresh);
  }

  @override
  Future<void> clear() async {
    _accessCache = null;
    _refreshCache = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_kAccess);
    await prefs.remove(_kRefresh);
  }
}

final tokenStorageProvider = Provider<TokenStorage>(
  (_) => kIsWeb ? _WebTokenStorage() : _SecureTokenStorage(),
);
