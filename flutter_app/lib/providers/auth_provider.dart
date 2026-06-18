// providers/auth_provider.dart
//
// Central auth state. Holds current user, token, and loading state.
// Screens read from this provider instead of hardcoding user_id.

import 'package:flutter/foundation.dart';

import '../models/user_model.dart';
import '../services/auth_service.dart';

class AuthProvider extends ChangeNotifier {
  final AuthService _authService = AuthService();

  UserModel? _currentUser;
  String? _token;
  bool _isLoading = false;
  String? _errorMessage;

  // ── Getters ───────────────────────────────────────────────────────────────

  UserModel? get currentUser => _currentUser;
  String? get token => _token;
  bool get isLoggedIn => _token != null && _currentUser != null;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get hasError => _errorMessage != null;

  int get userId => _currentUser?.id ?? 0;

  // ── Private helpers ───────────────────────────────────────────────────────

  void _setLoading(bool v) {
    _isLoading = v;
    notifyListeners();
  }

  void _setError(String? msg) {
    _errorMessage = msg;
    notifyListeners();
  }

  void clearError() => _setError(null);

  // ── Auto-login on app start ───────────────────────────────────────────────

  /// Called from AuthWrapper on startup. Returns true if auto-login succeeded.
  Future<bool> tryAutoLogin() async {
    final token = await _authService.getStoredToken();
    if (token == null) return false;

    try {
      final user = await _authService.getMe(token);
      _token = token;
      _currentUser = user;
      notifyListeners();
      return true;
    } catch (_) {
      // Token invalid or expired — clear it
      await _authService.clearCredentials();
      return false;
    }
  }

  // ── Signup ────────────────────────────────────────────────────────────────

  Future<bool> signup({
    required String email,
    required String password,
    String? name,
  }) async {
    _setLoading(true);
    _setError(null);
    try {
      final data = await _authService.signup(
        email: email,
        password: password,
        name: name,
      );
      _token = data['token'] as String;
      // Fetch full profile
      _currentUser = await _authService.getMe(_token!);
      notifyListeners();
      return true;
    } catch (e) {
      _setError(e.toString().replaceFirst('Exception: ', ''));
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // ── Login ─────────────────────────────────────────────────────────────────

  Future<bool> login({
    required String email,
    required String password,
  }) async {
    _setLoading(true);
    _setError(null);
    try {
      final data = await _authService.login(
        email: email,
        password: password,
      );
      _token = data['token'] as String;
      _currentUser = await _authService.getMe(_token!);
      notifyListeners();
      return true;
    } catch (e) {
      _setError(e.toString().replaceFirst('Exception: ', ''));
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // ── Complete onboarding ───────────────────────────────────────────────────

  Future<bool> completeOnboarding({
    required String name,
    required String goal,
    required String gender,
    required double weightKg,
    required double heightCm,
    required String weeklyEffort,
  }) async {
    if (_token == null || _currentUser == null) return false;
    _setLoading(true);
    _setError(null);
    try {
      _currentUser = await _authService.completeOnboarding(
        userId: _currentUser!.id,
        token: _token!,
        name: name,
        goal: goal,
        gender: gender,
        weightKg: weightKg,
        heightCm: heightCm,
        weeklyEffort: weeklyEffort,
      );
      notifyListeners();
      return true;
    } catch (e) {
      _setError(e.toString().replaceFirst('Exception: ', ''));
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // ── Update profile ────────────────────────────────────────────────────────

  Future<bool> updateProfile({
    String? name,
    String? goal,
    String? gender,
    double? weightKg,
    double? heightCm,
    String? weeklyEffort,
  }) async {
    if (_token == null) return false;
    _setLoading(true);
    _setError(null);
    try {
      _currentUser = await _authService.updateProfile(
        token: _token!,
        name: name,
        goal: goal,
        gender: gender,
        weightKg: weightKg,
        heightCm: heightCm,
        weeklyEffort: weeklyEffort,
      );
      notifyListeners();
      return true;
    } catch (e) {
      _setError(e.toString().replaceFirst('Exception: ', ''));
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // ── Logout ────────────────────────────────────────────────────────────────

  Future<void> logout() async {
    await _authService.clearCredentials();
    _token = null;
    _currentUser = null;
    _errorMessage = null;
    notifyListeners();
  }
}
