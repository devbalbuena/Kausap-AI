import 'dart:async';
import 'dart:io';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';

/// Monitors both network interface availability AND actual internet reachability.
/// Exposes [isOnline], [connectionType], and [lastChecked] for reactive UI updates.
class ConnectivityService extends ChangeNotifier {
  static final ConnectivityService _instance = ConnectivityService._internal();
  factory ConnectivityService() => _instance;
  ConnectivityService._internal() {
    _init();
  }

  bool _isOnline = true;
  String _connectionType = 'unknown'; // 'wifi' | 'mobile' | 'ethernet' | 'offline'
  DateTime? _lastChecked;
  int _failedChecks = 0;

  bool get isOnline => _isOnline;
  String get connectionType => _connectionType;
  DateTime? get lastChecked => _lastChecked;

  StreamSubscription<List<ConnectivityResult>>? _subscription;
  Timer? _pingTimer;

  void _init() {
    // Check initial state
    Connectivity().checkConnectivity().then(_handleResults);

    // Listen for interface-level changes
    _subscription = Connectivity()
        .onConnectivityChanged
        .listen(_handleResults);

    // Periodic real internet reachability check every 15s
    _pingTimer = Timer.periodic(const Duration(seconds: 15), (_) => _pingCheck());
  }

  void _handleResults(List<ConnectivityResult> results) {
    final hasInterface = results.any((r) =>
        r == ConnectivityResult.mobile ||
        r == ConnectivityResult.wifi ||
        r == ConnectivityResult.ethernet);

    if (!hasInterface) {
      _setStatus(false, 'offline');
    } else {
      // Interface up — confirm with real ping
      _pingCheck();
      final type = results.contains(ConnectivityResult.wifi)
          ? 'wifi'
          : results.contains(ConnectivityResult.mobile)
              ? 'mobile'
              : 'ethernet';
      _connectionType = type;
    }
  }

  /// Attempts a DNS lookup to confirm real internet access.
  Future<void> _pingCheck() async {
    try {
      final result = await InternetAddress.lookup('google.com')
          .timeout(const Duration(seconds: 5));
      if (result.isNotEmpty && result[0].rawAddress.isNotEmpty) {
        _failedChecks = 0;
        _setStatus(true, _connectionType == 'offline' ? 'wifi' : _connectionType);
      } else {
        _failedChecks++;
        if (_failedChecks >= 2) _setStatus(false, 'offline');
      }
    } on SocketException {
      _failedChecks++;
      if (_failedChecks >= 2) _setStatus(false, 'offline');
    } on TimeoutException {
      _failedChecks++;
      if (_failedChecks >= 2) _setStatus(false, 'offline');
    } catch (_) {
      // Don't change status on unknown errors
    }
  }

  void _setStatus(bool online, String type) {
    final changed = _isOnline != online || _connectionType != type;
    _isOnline = online;
    _connectionType = type;
    _lastChecked = DateTime.now();
    if (changed) notifyListeners();
  }

  @override
  void dispose() {
    _subscription?.cancel();
    _pingTimer?.cancel();
    super.dispose();
  }
}
