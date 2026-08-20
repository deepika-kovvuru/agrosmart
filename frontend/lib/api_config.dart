import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

/// Central API configuration. All screens use [baseUrl] for backend requests.
/// The URL is auto-resolved at app startup via [resolveBaseUrl].
class ApiConfig {
  static const String _primaryUrl = 'http://127.0.0.1:5000';

  static const List<String> _fallbacks = [
    'https://agrosmart-app-service.onrender.com',
    'http://localhost:5000',
    'http://127.0.0.1:5000',
    'http://172.20.10.2:5000',
    'http://10.0.2.2:5000',
  ];

  static String _baseUrl = _primaryUrl;

  /// The resolved backend base URL. Use this in all API calls.
  static String get baseUrl {
    if (kIsWeb) {
      try {
        final origin = Uri.base.origin;
        if (origin.isNotEmpty && !origin.contains('null') && !origin.contains('file://')) {
          final isLocalDev = (origin.contains('localhost') || origin.contains('127.0.0.1')) && !origin.contains(':5000');
          if (!isLocalDev) {
            return origin;
          }
        }
      } catch (_) {}
    }
    return _baseUrl;
  }

  /// Tests candidates in order and picks the first responsive one.
  static Future<void> resolveBaseUrl() async {
    final candidates = <String>[
      'http://127.0.0.1:5000',
      'http://localhost:5000',
    ];
    if (kIsWeb) {
      try {
        final origin = Uri.base.origin;
        if (origin.isNotEmpty && !origin.contains('null') && !origin.contains('file://')) {
          final isLocalDev = (origin.contains('localhost') || origin.contains('127.0.0.1')) && !origin.contains(':5000');
          if (!isLocalDev) {
            candidates.insert(0, origin);
          }
        }
      } catch (_) {}
    }

    candidates.addAll(_fallbacks);

    for (final url in candidates) {
      if (url.isEmpty) continue;
      try {
        final res = await http
            .get(
              Uri.parse('$url/api/health'),
              headers: {'Bypass-Tunnel-Reminder': 'true'},
            )
            .timeout(const Duration(milliseconds: 1500));

        if (res.statusCode == 200 && res.body.contains('AGROSMART')) {
          _baseUrl = url;
          debugPrint('[ApiConfig] Connected to: $_baseUrl');
          return;
        }
      } catch (_) {
        // Try next candidate
      }
    }

    _baseUrl = 'http://127.0.0.1:5000';
    debugPrint('[ApiConfig] Using fallback base URL: $_baseUrl');
  }
}
