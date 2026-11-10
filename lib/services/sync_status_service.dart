import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

class SyncStatusService extends ChangeNotifier {
  bool _isOnline = true;
  bool get isOnline => _isOnline;

  StreamSubscription<List<ConnectivityResult>>? _subscription;

  SyncStatusService() {
    _init();
  }

  Future<void> _init() async {
    final connectivity = Connectivity();
    try {
      final results = await connectivity.checkConnectivity();
      _updateStatus(results);
    } catch (e) {
      debugPrint("SyncStatusService init error: $e");
    }

    _subscription = connectivity.onConnectivityChanged.listen((results) {
      _updateStatus(results);
    });
  }

  void _updateStatus(List<ConnectivityResult> results) {
    // If the list only contains 'none', we are offline.
    bool online = results.isNotEmpty && !results.every((r) => r == ConnectivityResult.none);
    if (_isOnline != online) {
      _isOnline = online;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}
