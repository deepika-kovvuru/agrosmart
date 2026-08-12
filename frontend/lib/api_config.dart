import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

/// Central API configuration. All screens use [baseUrl] for backend requests.
/// The URL is auto-resolved at app startup via [resolveBaseUrl].
class ApiConfig {
  // Primary: public localtunnel URL (update this when starting a new tunnel)
  static const String _primaryUrl = 'https://agrosmart-app-service.onrender.com';

  // Fallback candidates for local development / BlueStacks
  static const List<String> _fallbacks = [
    'http://172.20.10.2:5000',   // Host Wi-Fi IP (hotspot)
    'http://172.23.23.155:5000', // Previous host Wi-Fi IP
    'http://10.0.2.2:5000',      // Android emulator localhost
    'http://localhost:5000',     // Web / desktop
  ];

  static String _baseUrl = _primaryUrl;

  /// The resolved backend base URL. Use this in all API calls.
  static String get baseUrl => _baseUrl;

  /// Tests candidates in order and picks the first responsive one.
  /// Falls back to primary URL if none respond.
  static Future<void> resolveBaseUrl() async {
    if (kIsWeb) {
      _baseUrl = 'https://agrosmart-app-service.onrender.com';
      return;
    }

    final candidates = [_primaryUrl, ..._fallbacks];

    for (final url in candidates) {
      try {
        final res = await http
            .get(
              Uri.parse('$url/api/health'),
              headers: {'Bypass-Tunnel-Reminder': 'true'},
            )
            .timeout(const Duration(milliseconds: 2000));

        if (res.statusCode == 200) {
          _baseUrl = url;
          debugPrint('[ApiConfig] Connected to: $_baseUrl');
          return;
        }
      } catch (_) {
        // Try next candidate
      }
    }

    debugPrint('[ApiConfig] No backend reachable. Using default: $_baseUrl');
  }
}
