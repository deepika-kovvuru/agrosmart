import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';

/// Singleton service that monitors network connectivity in real time.
class ConnectivityService {
  ConnectivityService._();
  static final ConnectivityService instance = ConnectivityService._();

  /// True when the device has an active network connection.
  final ValueNotifier<bool> isOnline = ValueNotifier<bool>(true);

  /// Call once at app startup to begin watching connectivity.
  Future<void> initialize() async {
    // Check initial state
    final result = await Connectivity().checkConnectivity();
    isOnline.value = _isConnected(result);

    // Listen for changes
    Connectivity().onConnectivityChanged.listen((results) {
      isOnline.value = _isConnected(results);
    });
  }

  bool _isConnected(List<ConnectivityResult> results) {
    return results.any((r) =>
        r == ConnectivityResult.mobile ||
        r == ConnectivityResult.wifi ||
        r == ConnectivityResult.ethernet);
  }

  bool get isOnlineNow => isOnline.value;
}
