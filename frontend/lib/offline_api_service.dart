import 'dart:convert';
import 'package:http/http.dart' as http;
import 'api_config.dart';
import 'local_storage.dart';
import 'user_session.dart';
import 'connectivity_service.dart';

/// Smart API layer that automatically falls back to local cache when offline.
class OfflineApiService {
  static const _timeout = Duration(seconds: 6);
  static final Map<String, String> _headers = {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
    'Bypass-Tunnel-Reminder': 'true',
  };

  // ─────────────────────────────────────────
  // HEALTH CHECK
  // ─────────────────────────────────────────

  static Future<bool> checkHealth() async {
    try {
      final res = await http
          .get(Uri.parse('${ApiConfig.baseUrl}/api/health'), headers: _headers)
          .timeout(_timeout);
      return res.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  // ─────────────────────────────────────────
  // AUTH
  // ─────────────────────────────────────────

  static Future<Map<String, dynamic>> login(String email, String password) async {
    // Attempt online login first
    if (ConnectivityService.instance.isOnlineNow) {
      try {
        final res = await http
            .post(
              Uri.parse('${ApiConfig.baseUrl}/login'),
              headers: _headers,
              body: jsonEncode({'email': email, 'password': password}),
            )
            .timeout(_timeout);

        final decoded = jsonDecode(res.body);
        if (res.statusCode == 200) {
          // Save session locally for offline access
          final user = decoded['user'] ?? {'email': email};
          await LocalStorage.saveSession(user);
          await LocalStorage.saveOfflineCredentials(email);
          await LocalStorage.saveLastSync();
          if (decoded['user'] != null) {
            UserSession.currentUser = User.fromJson(decoded['user']);
          }
          return {'success': true, 'message': decoded['message'] ?? 'Login successful', 'offline': false};
        } else {
          return {'success': false, 'error': decoded['error'] ?? 'Invalid credentials', 'offline': false};
        }
      } catch (_) {
        // Network error → fall through to offline check
      }
    }

    // Offline fallback: check saved session
    final savedSession = await LocalStorage.loadSession();
    if (savedSession != null && await LocalStorage.verifyOfflineEmail(email)) {
      UserSession.currentUser = User.fromJson(savedSession);
      return {
        'success': true,
        'offline': true,
        'message': 'You\'re offline. Showing your saved data.',
      };
    }

    return {
      'success': false,
      'offline': true,
      'error': 'No internet connection. First-time login requires internet access.',
    };
  }

  static Future<Map<String, dynamic>> signup({
    required String name,
    required String email,
    required String phone,
    required String password,
    required String confirmPassword,
    String? state,
  }) async {
    if (!ConnectivityService.instance.isOnlineNow) {
      return {'success': false, 'error': 'Internet connection required to create a new account.'};
    }
    try {
      final res = await http
          .post(
            Uri.parse('${ApiConfig.baseUrl}/signup'),
            headers: _headers,
            body: jsonEncode({
              'name': name,
              'email': email,
              'phone': phone,
              'password': password,
              'confirm_password': confirmPassword,
              'state': state,
            }),
          )
          .timeout(_timeout);

      final decoded = jsonDecode(res.body);
      if (res.statusCode == 200 || res.statusCode == 201) {
        return {'success': true, 'message': decoded['message'] ?? 'Account created successfully'};
      }
      return {'success': false, 'error': decoded['error'] ?? 'Signup failed'};
    } catch (e) {
      return {'success': false, 'error': 'Connection failed. Please try again.'};
    }
  }

  // ─────────────────────────────────────────
  // GENERIC CACHED GET
  // ─────────────────────────────────────────

  /// Fetches data from [endpoint], caches it under [cacheKey].
  /// Returns data with `fromCache: true` when offline.
  static Future<Map<String, dynamic>> getCached(String endpoint, String cacheKey) async {
    if (ConnectivityService.instance.isOnlineNow) {
      try {
        final res = await http
            .get(Uri.parse('${ApiConfig.baseUrl}$endpoint'), headers: _headers)
            .timeout(_timeout);

        if (res.statusCode == 200) {
          final data = jsonDecode(res.body);
          await LocalStorage.saveCache(cacheKey, data);
          await LocalStorage.saveLastSync();
          return {'success': true, 'data': data, 'fromCache': false};
        }
      } catch (_) {
        // Fall through to cache
      }
    }

    // Return cached data
    final cached = await LocalStorage.loadCache(cacheKey);
    if (cached != null) {
      return {'success': true, 'data': cached, 'fromCache': true};
    }
    return {'success': false, 'data': null, 'fromCache': true, 'error': 'No data available offline'};
  }

  // ─────────────────────────────────────────
  // SPECIFIC ENDPOINTS (using getCached)
  // ─────────────────────────────────────────

  static Future<Map<String, dynamic>> getPestAlerts({String? region}) async {
    final ep = region != null ? '/pest_alerts?region=${Uri.encodeComponent(region)}' : '/pest_alerts';
    return getCached(ep, 'pest_alerts_${region ?? "all"}');
  }

  static Future<Map<String, dynamic>> getMarketPrices({String? mandi, String? category}) async {
    var ep = '/market_prices';
    if (mandi != null || category != null) {
      final params = <String>[];
      if (mandi != null) params.add('mandi=${Uri.encodeComponent(mandi)}');
      if (category != null) params.add('category=${Uri.encodeComponent(category)}');
      ep += '?${params.join('&')}';
    }
    return getCached(ep, 'market_prices_${mandi ?? ""}_${category ?? ""}');
  }

  static Future<Map<String, dynamic>> getNewsArticles() async =>
      getCached('/news_articles', 'news_articles');

  static Future<Map<String, dynamic>> getFarmingTips() async =>
      getCached('/farming_tips', 'farming_tips');

  static Future<Map<String, dynamic>> getMandis() async =>
      getCached('/mandis', 'mandis');

  static Future<Map<String, dynamic>> getCropAdvisories(int userId, String crop) async =>
      getCached('/crop_advisories/$userId?crop=${Uri.encodeComponent(crop)}', 'crop_advisory_$crop');

  static Future<Map<String, dynamic>> getTreatments() async =>
      getCached('/treatments', 'treatments');

  static Future<Map<String, dynamic>> getCurrentUser() async =>
      getCached('/get_current_user', 'current_user');
}
