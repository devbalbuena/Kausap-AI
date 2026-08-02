import 'package:flutter/foundation.dart';

/// Global service to track if any network request is currently retrying,
/// so the UI can display a "Retrying..." banner.
class RetryService extends ChangeNotifier {
  static final RetryService _instance = RetryService._internal();
  factory RetryService() => _instance;
  RetryService._internal();

  bool _isRetrying = false;
  String _retryMessage = '';

  bool get isRetrying => _isRetrying;
  String get retryMessage => _retryMessage;

  void startRetry(String message) {
    _isRetrying = true;
    _retryMessage = message;
    notifyListeners();
  }

  void stopRetry() {
    if (!_isRetrying) return;
    _isRetrying = false;
    _retryMessage = '';
    notifyListeners();
  }
}
