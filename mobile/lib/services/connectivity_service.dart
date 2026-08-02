import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';

/// Singleton service that monitors network connectivity.
/// Exposes [isOnline] and a [statusStream] for reactive UI updates.
class ConnectivityService extends ChangeNotifier {
  static final ConnectivityService _instance = ConnectivityService._internal();
  factory ConnectivityService() => _instance;
  ConnectivityService._internal() {
    _init();
  }

  bool _isOnline = true;
  bool get isOnline => _isOnline;

  StreamSubscription<List<ConnectivityResult>>? _subscription;

  void _init() {
    // Check initial state
    Connectivity().checkConnectivity().then(_handleResults);

    // Listen for changes
    _subscription = Connectivity()
        .onConnectivityChanged
        .listen(_handleResults);
  }

  void _handleResults(List<ConnectivityResult> results) {
    final wasOnline = _isOnline;
    _isOnline = results.any((r) =>
        r == ConnectivityResult.mobile ||
        r == ConnectivityResult.wifi ||
        r == ConnectivityResult.ethernet);
    if (_isOnline != wasOnline) {
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}
