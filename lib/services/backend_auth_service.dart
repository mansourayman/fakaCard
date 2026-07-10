import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../models/backend_user.dart';

class BackendAuthException implements Exception {
  BackendAuthException(this.message, {this.statusCode});

  final String message;
  final int? statusCode;

  @override
  String toString() => message;
}

class BackendAuthService {
  BackendAuthService({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;

  static const baseUrl = String.fromEnvironment(
    'BACKEND_BASE_URL',
    defaultValue: 'https://mansourayman.pythonanywhere.com',
  );

  static const _tokenKey = 'backend_access_token';
  static const _usernameKey = 'backend_username';
  static const _roleKey = 'backend_role';

  Future<BackendAuthSession> login({
    required String username,
    required String password,
  }) async {
    final response = await _client.post(
      Uri.parse('$baseUrl/auth/login'),
      headers: const {'Content-Type': 'application/json'},
      body: jsonEncode({
        'username': username,
        'password': password,
      }),
    );

    Map<String, dynamic>? data;
    try {
      data = jsonDecode(response.body) as Map<String, dynamic>;
    } catch (_) {
      data = null;
    }

    if (response.statusCode != 200) {
      throw BackendAuthException(
        data?['message']?.toString() ?? 'فشل تسجيل الدخول',
        statusCode: response.statusCode,
      );
    }

    final token = data?['accessToken']?.toString();
    final userMap = data?['user'];
    if (token == null || token.isEmpty || userMap is! Map<String, dynamic>) {
      throw BackendAuthException('رد السيرفر غير مكتمل');
    }

    final session = BackendAuthSession(
      accessToken: token,
      user: BackendUser.fromMap(userMap),
    );

    await saveSession(session);
    return session;
  }

  Future<void> saveSession(BackendAuthSession session) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, session.accessToken);
    await prefs.setString(_usernameKey, session.user.username);
    await prefs.setString(_roleKey, session.user.role);
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
    await prefs.remove(_usernameKey);
    await prefs.remove(_roleKey);
  }
}
