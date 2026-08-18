import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../services/auth_service.dart';
import '../services/api_client.dart'; // To catch 401s if needed

class AuthProvider extends ChangeNotifier {
  final AuthService _authService = AuthService();
  static const _storage = FlutterSecureStorage();
  
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
      final avatarOverride = await _storage.read(key: 'user_avatar_override');
      if (avatarOverride != null && avatarOverride.isNotEmpty) {
        user['avatar_url'] = avatarOverride;
      }
      _currentUser = user;
      _isAuthenticated = true;
      await _storage.write(key: 'cached_user_profile', value: jsonEncode(user));
    } catch (e) {
      if (e is ApiException && e.statusCode == 401) {
        await _authService.logout();
        _currentUser = null;
        _isAuthenticated = false;
      } else {
        // Try loading cached profile if network is down
        final cached = await _storage.read(key: 'cached_user_profile');
        if (cached != null) {
          try {
            _currentUser = Map<String, dynamic>.from(jsonDecode(cached));
            _isAuthenticated = true;
          } catch (_) {
            _currentUser = null;
            _isAuthenticated = false;
          }
        }
      }
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
      final avatarOverride = await _storage.read(key: 'user_avatar_override');
      if (avatarOverride != null && avatarOverride.isNotEmpty) {
        user['avatar_url'] = avatarOverride;
      }
      _currentUser = user;
      _isAuthenticated = true;
      await _storage.write(key: 'cached_user_profile', value: jsonEncode(user));
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
    await _storage.delete(key: 'cached_user_profile');
    await _storage.delete(key: 'user_avatar_override');
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

  Future<void> updateProfile(Map<String, dynamic> data) async {
    _isLoading = true;

    // 1. Immediately apply changes in-memory for zero-latency UI updates
    final merged = Map<String, dynamic>.from(_currentUser ?? {});
    data.forEach((key, value) {
      if (value != null) merged[key] = value;
    });

    // 2. Persist avatar and user cache locally
    if (data.containsKey('avatar_url')) {
      final av = data['avatar_url'] as String?;
      if (av != null && av.isNotEmpty) {
        await _storage.write(key: 'user_avatar_override', value: av);
      }
    }
    await _storage.write(key: 'cached_user_profile', value: jsonEncode(merged));
    _currentUser = merged;
    notifyListeners();

    // 3. Send update to backend server
    try {
      final updated = await _authService.updateProfile(data);
      final avatarOverride = await _storage.read(key: 'user_avatar_override');
      if (avatarOverride != null && avatarOverride.isNotEmpty) {
        updated['avatar_url'] = avatarOverride;
      }
      _currentUser = updated;
      await _storage.write(key: 'cached_user_profile', value: jsonEncode(updated));
    } catch (_) {
      // Backend error or offline — local state was already updated
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Re-fetches the current user from the server and notifies all listeners.
  /// Call this after any profile update to sync the UI immediately.
  Future<void> refreshUser() async {
    try {
      final user = await _authService.getCurrentUser();
      final avatarOverride = await _storage.read(key: 'user_avatar_override');
      if (avatarOverride != null && avatarOverride.isNotEmpty) {
        user['avatar_url'] = avatarOverride;
      }
      _currentUser = user;
      await _storage.write(key: 'cached_user_profile', value: jsonEncode(user));
      notifyListeners();
    } catch (_) {
      // Silently ignore refresh errors
    }
  }
}
