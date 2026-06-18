// services/auth_service.dart
//
// Handles all auth-related API calls and local token persistence.
// Uses SharedPreferences to store token and user_id across app restarts.

import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../config/api_config.dart';
import '../models/user_model.dart';

// Keys for SharedPreferences
const _kToken = 'auth_token';
const _kUserId = 'user_id';

class AuthService {
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  final http.Client _client = http.Client();
  static const Duration _timeout = Duration(seconds: 20);

  // ── Local persistence ─────────────────────────────────────────────────────

  Future<String?> getStoredToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_kToken);
  }

  Future<int?> getStoredUserId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_kUserId);
  }

  Future<void> _saveCredentials(String token, int userId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kToken, token);
    await prefs.setInt(_kUserId, userId);
  }

  Future<void> clearCredentials() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_kToken);
    await prefs.remove(_kUserId);
  }

  // ── Helper ────────────────────────────────────────────────────────────────

  String _parseError(http.Response response) {
    try {
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      return body['detail']?.toString() ?? 'Server error ${response.statusCode}';
    } catch (_) {
      return 'Server error ${response.statusCode}';
    }
  }

  // ── POST /auth/signup ─────────────────────────────────────────────────────

  Future<Map<String, dynamic>> signup({
    required String email,
    required String password,
    String? name,
  }) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}${ApiConfig.authSignup}');
    try {
      final response = await _client
          .post(
            uri,
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'email': email,
              'password': password,
              if (name != null && name.isNotEmpty) 'name': name,
            }),
          )
          .timeout(_timeout);

      if (response.statusCode == 201) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        await _saveCredentials(data['token'] as String, data['user_id'] as int);
        return data;
      }
      throw Exception(_parseError(response));
    } on SocketException {
      throw Exception('Cannot reach server. Check your connection.');
    }
  }

  // ── POST /auth/login ──────────────────────────────────────────────────────

  Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}${ApiConfig.authLogin}');
    try {
      final response = await _client
          .post(
            uri,
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'email': email, 'password': password}),
          )
          .timeout(_timeout);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        await _saveCredentials(data['token'] as String, data['user_id'] as int);
        return data;
      }
      throw Exception(_parseError(response));
    } on SocketException {
      throw Exception('Cannot reach server. Check your connection.');
    }
  }

  // ── POST /auth/onboarding ─────────────────────────────────────────────────

  Future<UserModel> completeOnboarding({
    required int userId,
    required String token,
    required String name,
    required String goal,
    required String gender,
    required double weightKg,
    required double heightCm,
    required String weeklyEffort,
  }) async {
    final uri = Uri.parse(
      '${ApiConfig.baseUrl}${ApiConfig.authOnboarding}?user_id=$userId',
    );
    try {
      final response = await _client
          .post(
            uri,
            headers: {
              'Content-Type': 'application/json',
              'x-auth-token': token,
            },
            body: jsonEncode({
              'name': name,
              'goal': goal,
              'gender': gender,
              'weight_kg': weightKg,
              'height_cm': heightCm,
              'weekly_effort': weeklyEffort,
            }),
          )
          .timeout(_timeout);

      if (response.statusCode == 200) {
        return UserModel.fromJson(
            jsonDecode(response.body) as Map<String, dynamic>);
      }
      throw Exception(_parseError(response));
    } on SocketException {
      throw Exception('Cannot reach server. Check your connection.');
    }
  }

  // ── GET /users/me ─────────────────────────────────────────────────────────

  Future<UserModel> getMe(String token) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}${ApiConfig.usersMe}');
    try {
      final response = await _client
          .get(uri, headers: {'x-auth-token': token})
          .timeout(_timeout);

      if (response.statusCode == 200) {
        return UserModel.fromJson(
            jsonDecode(response.body) as Map<String, dynamic>);
      }
      throw Exception(_parseError(response));
    } on SocketException {
      throw Exception('Cannot reach server. Check your connection.');
    }
  }

  // ── PATCH /users/me ───────────────────────────────────────────────────────

  Future<UserModel> updateProfile({
    required String token,
    String? name,
    String? goal,
    String? gender,
    double? weightKg,
    double? heightCm,
    String? weeklyEffort,
  }) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}${ApiConfig.usersMe}');
    final body = <String, dynamic>{};
    if (name != null) body['name'] = name;
    if (goal != null) body['goal'] = goal;
    if (gender != null) body['gender'] = gender;
    if (weightKg != null) body['weight_kg'] = weightKg;
    if (heightCm != null) body['height_cm'] = heightCm;
    if (weeklyEffort != null) body['weekly_effort'] = weeklyEffort;

    try {
      final response = await _client
          .patch(
            uri,
            headers: {
              'Content-Type': 'application/json',
              'x-auth-token': token,
            },
            body: jsonEncode(body),
          )
          .timeout(_timeout);

      if (response.statusCode == 200) {
        return UserModel.fromJson(
            jsonDecode(response.body) as Map<String, dynamic>);
      }
      throw Exception(_parseError(response));
    } on SocketException {
      throw Exception('Cannot reach server. Check your connection.');
    }
  }
}
