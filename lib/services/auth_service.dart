import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;

class AuthUser {
  final String id;
  final String username;
  final String displayName;
  final String role;
  final String? schoolId;
  final String? learnerId;
  final String? grade;

  const AuthUser({
    required this.id,
    required this.username,
    required this.displayName,
    required this.role,
    this.schoolId,
    this.learnerId,
    this.grade,
  });

  factory AuthUser.fromJson(Map<String, dynamic> json) => AuthUser(
    id: json['id'] as String,
    username: json['username'] as String,
    displayName: json['displayName'] as String,
    role: json['role'] as String,
    schoolId: json['schoolId'] as String?,
    learnerId: json['learnerId'] as String?,
    grade: json['grade'] as String?,
  );
}

class AuthService {
  AuthService({
    FlutterSecureStorage? storage,
    http.Client? client,
  })  : _storage = storage ?? const FlutterSecureStorage(),
        _client = client ?? http.Client();

  static const _accessKey = 'offlineai_access_token';
  static const _refreshKey = 'offlineai_refresh_token';
  static const _expiresKey = 'offlineai_access_expires_at';

  final FlutterSecureStorage _storage;
  final http.Client _client;

  AuthUser? user;
  String? _accessToken;
  String? _refreshToken;
  DateTime? _accessExpiresAt;

  String get baseUrl => const String.fromEnvironment('OFFLINE_AI_API_URL', defaultValue: '');

  bool get isAuthenticated => _refreshToken != null;
  bool get isConfigured => baseUrl.isNotEmpty;

  Future<void> restore() async {
    _accessToken = await _storage.read(key: _accessKey);
    _refreshToken = await _storage.read(key: _refreshKey);
    final expires = await _storage.read(key: _expiresKey);
    _accessExpiresAt = expires == null ? null : DateTime.tryParse(expires);

    if (_accessToken == null && _refreshToken == null) return;

    try {
      final response = await _authorizedGet('/v1/auth/me');
      if (response.statusCode == 200) {
        final body = jsonDecode(response.body) as Map<String, dynamic>;
        user = AuthUser.fromJson(body['user'] as Map<String, dynamic>);
        return;
      }
      if (response.statusCode == 401) {
        await logout();
      }
    } catch (_) {
      // Preserve the local session during an offline launch. The next authenticated request
      // will refresh or reject the session when connectivity is available.
    }
  }

  Future<void> login(String username, String password) async {
    if (!isConfigured) throw StateError('This build has no sync server configured.');
    final response = await _client.post(
      Uri.parse('$baseUrl/v1/auth/login'),
      headers: const {'Content-Type': 'application/json'},
      body: jsonEncode({'username': username, 'password': password}),
    );
    await _acceptSession(response);
  }

  Future<void> register({
    required String username,
    required String password,
    required String displayName,
    required String grade,
    String? schoolCode,
  }) async {
    if (!isConfigured) throw StateError('This build has no sync server configured.');
    final response = await _client.post(
      Uri.parse('$baseUrl/v1/auth/register'),
      headers: const {'Content-Type': 'application/json'},
      body: jsonEncode({
        'username': username,
        'password': password,
        'displayName': displayName,
        'grade': grade,
        if (schoolCode != null && schoolCode.trim().isNotEmpty) 'schoolCode': schoolCode.trim(),
      }),
    );
    await _acceptSession(response);
  }

  Future<void> deleteMyData() async {
    if (!isConfigured || !isAuthenticated) {
      throw StateError('No authenticated online account is available.');
    }
    final token = await accessToken();
    if (token == null) throw StateError('Please sign in again.');
    final response = await _client.delete(
      Uri.parse('$baseUrl/v1/auth/me/data'),
      headers: {'Authorization': 'Bearer $token'},
    );
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw StateError('data_deletion_failed');
    }
    await logout();
  }

  Future<void> logout() async {
    if (_refreshToken != null && _accessToken != null && isConfigured) {
      try {
        await _client.post(
          Uri.parse('$baseUrl/v1/auth/logout'),
          headers: {'Authorization': 'Bearer $_accessToken', 'Content-Type': 'application/json'},
          body: jsonEncode({'refreshToken': _refreshToken}),
        );
      } catch (_) {}
    }
    _accessToken = null;
    _refreshToken = null;
    _accessExpiresAt = null;
    user = null;
    await _storage.delete(key: _accessKey);
    await _storage.delete(key: _refreshKey);
    await _storage.delete(key: _expiresKey);
  }

  Future<String?> accessToken() async {
    if (_accessToken == null && _refreshToken == null) return null;
    if (_accessToken != null &&
        _accessExpiresAt != null &&
        DateTime.now().isBefore(_accessExpiresAt!.subtract(const Duration(minutes: 1)))) {
      return _accessToken;
    }
    await _refresh();
    return _accessToken;
  }

  Future<http.Response> postAuthenticated(
    String path, {
    required Object body,
  }) async {
    final token = await accessToken();
    if (token == null) {
      throw StateError('Please sign in before synchronizing.');
    }

    var response = await _client.post(
      Uri.parse('$baseUrl$path'),
      headers: {'Authorization': 'Bearer $token', 'Content-Type': 'application/json'},
      body: jsonEncode(body),
    );

    if (response.statusCode == 401 && _refreshToken != null) {
      await _refresh();
      response = await _client.post(
        Uri.parse('$baseUrl$path'),
        headers: {'Authorization': 'Bearer $_accessToken', 'Content-Type': 'application/json'},
        body: jsonEncode(body),
      );
    }
    return response;
  }

  Future<http.Response> _authorizedGet(String path) async {
    final token = await accessToken();
    if (token == null) return http.Response('', 401);
    return _client.get(
      Uri.parse('$baseUrl$path'),
      headers: {'Authorization': 'Bearer $token'},
    );
  }

  Future<void> _refresh() async {
    if (_refreshToken == null || !isConfigured) {
      await logout();
      throw StateError('Session expired. Please sign in again.');
    }

    final response = await _client.post(
      Uri.parse('$baseUrl/v1/auth/refresh'),
      headers: const {'Content-Type': 'application/json'},
      body: jsonEncode({'refreshToken': _refreshToken}),
    );
    await _acceptSession(response);
  }

  Future<void> _acceptSession(http.Response response) async {
    final body = response.body.isEmpty
        ? <String, dynamic>{}
        : jsonDecode(response.body) as Map<String, dynamic>;
    if (response.statusCode < 200 || response.statusCode >= 300) {
      final error = body['error'] ?? 'authentication_failed';
      throw StateError(error.toString());
    }

    _accessToken = body['accessToken'] as String;
    _refreshToken = body['refreshToken'] as String;
    final expiresIn = (body['expiresIn'] as num?)?.toInt() ?? 900;
    _accessExpiresAt = DateTime.now().add(Duration(seconds: expiresIn));
    user = AuthUser.fromJson(body['user'] as Map<String, dynamic>);

    await _storage.write(key: _accessKey, value: _accessToken);
    await _storage.write(key: _refreshKey, value: _refreshToken);
    await _storage.write(key: _expiresKey, value: _accessExpiresAt!.toIso8601String());
  }

  void dispose() => _client.close();
}
