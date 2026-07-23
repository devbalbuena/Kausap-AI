import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../services/api_client.dart'; // To catch 401s if needed

class AuthProvider extends ChangeNotifier {
  final AuthService _authService = AuthService();
  
  bool _isAuthenticated = false;
  Map<String, dynamic>? _currentUser;
  bool _isLoading = true;

  bool get isAuthenticated => _isAuthenticated;
  Map<String, dynamic>? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  bool get isAdmin => _currentUser?['role'] == 'admin';

  AuthProvider() {
    _checkLoginStatus();
  }

  Future<void> _checkLoginStatus() async {
    _isLoading = true;
    notifyListeners();

    try {
      final user = await _authService.getCurrentUser();
      _currentUser = user;
      _isAuthenticated = true;
    } catch (e) {
      if (e is ApiException && e.statusCode == 401) {
        await _authService.logout();
      }
      _currentUser = null;
      _isAuthenticated = false;
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> login(String email, String password) async {
    _isLoading = true;
    notifyListeners();

    try {
      await _authService.login(email, password);
      // Fetch user details after successful login
      final user = await _authService.getCurrentUser();
      _currentUser = user;
      _isAuthenticated = true;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> register(Map<String, dynamic> payload) async {
    _isLoading = true;
    notifyListeners();

    try {
      await _authService.register(payload);
      // Auto-login after successful registration
      await login(payload['email'], payload['password']);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> logout() async {
    await _authService.logout();
    _currentUser = null;
    _isAuthenticated = false;
    notifyListeners();
  }

  Future<void> forgotPassword(String email) async {
    _isLoading = true;
    notifyListeners();
    try {
      await _authService.forgotPassword(email);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<Map<String, dynamic>> verifyCode(String email, String code) async {
    _isLoading = true;
    notifyListeners();
    try {
      return await _authService.verifyCode(email, code);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> resetPassword(String resetToken, String newPassword) async {
    _isLoading = true;
    notifyListeners();
    try {
      await _authService.resetPassword(resetToken, newPassword);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
