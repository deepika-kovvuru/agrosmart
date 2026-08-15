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

  static Future<Map<String, dynamic>> getStates() async =>
      getCached('/api/states', 'states');

  static Future<Map<String, dynamic>> getMandisByState(String state) async =>
      getCached('/api/mandis?state=${Uri.encodeComponent(state)}', 'mandis_$state');

  static Future<Map<String, dynamic>> getMarketPricesByState({
    String? state,
    String? mandi,
    String? crop,
  }) async {
    var ep = '/api/market-prices';
    final params = <String>[];
    if (state != null && state.isNotEmpty) {
      params.add('state=${Uri.encodeComponent(state)}');
    }
    if (mandi != null && mandi.isNotEmpty) {
      params.add('mandi=${Uri.encodeComponent(mandi)}');
    }
    if (crop != null && crop.isNotEmpty) {
      params.add('crop=${Uri.encodeComponent(crop)}');
    }
    if (params.isNotEmpty) {
      ep += '?${params.join('&')}';
    }
    return getCached(ep, 'market_prices_state_${state ?? "all"}_${mandi ?? ""}_${crop ?? ""}');
  }

  static Future<Map<String, dynamic>> getPriceHistory(String mandi, String crop, {int days = 30}) async {
    final ep = '/api/price-history?mandi=${Uri.encodeComponent(mandi)}&crop=${Uri.encodeComponent(crop)}&days=$days';
    return getCached(ep, 'price_history_${mandi}_${crop}_$days');
  }

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

  static Future<Map<String, dynamic>> askAI(String message) async {
    if (ConnectivityService.instance.isOnlineNow) {
      try {
        final res = await http
            .post(
              Uri.parse('${ApiConfig.baseUrl}/api/ask-ai'),
              headers: _headers,
              body: jsonEncode({'message': message}),
            )
            .timeout(_timeout);
        final decoded = jsonDecode(res.body);
        if (res.statusCode == 200) {
          return {'success': true, 'response': decoded['response'], 'offline': false};
        }
      } catch (_) {}
    }

    // Offline fallback expert responses
    final msg = message.toLowerCase();
    String responseText = "";
    if (msg.contains("chilli") || msg.contains("pepper")) {
      if (msg.contains("pest") || msg.contains("insect") || msg.contains("disease") || msg.contains("control")) {
        responseText = "For red chilli, common pests are thrips, mites, and pod borers. I recommend spraying Neem Oil 10,000 PPM @ 2ml/L, or Fipronil 5% SC @ 2ml/L for thrips control. Ensure yellow and blue sticky traps are installed in your field.";
      } else {
        responseText = "Red chilli grows best in well-drained loamy soil with a pH of 6.0-7.0. Popular high-yielding varieties include Teja, Guntur Sannam, and Byadagi. Keep the soil moist but avoid logging.";
      }
    } else if (msg.contains("paddy") || msg.contains("rice")) {
      if (msg.contains("pest") || msg.contains("insect") || msg.contains("disease") || msg.contains("control")) {
        responseText = "In paddy fields, watch out for Brown Planthopper (BPH) and Stem Borer. Spray Imidacloprid 17.8% SL @ 0.3ml/L water for BPH, or apply Cartap Hydrochloride 4G granules @ 10kg/acre to control stem borers.";
      } else {
        responseText = "Paddy thrives in clayey loam soils that retain moisture. High-yielding varieties include Swarna, Samba Mahsuri, and IR64. Maintain shallow standing water during early growth.";
      }
    } else if (msg.contains("cotton")) {
      responseText = "For cotton crops, major threats are Whiteflies and Pink Bollworm. Spray Acetamiprid 20% SP @ 0.2g/L or use pheromone traps (5 per acre) for Pink Bollworms.";
    } else if (msg.contains("hello") || msg.contains("hi") || msg.contains("hey")) {
      responseText = "Hello! I am your Agrosmart AI Assistant. How can I help you with your crop health, fertilizer scheduling, irrigation, or pest protection today?";
    } else {
      responseText = "I am currently offline. I can provide general advice on Paddy, Cotton, or Chilli, but for custom queries, please connect to the internet.";
    }

    return {
      'success': true,
      'response': responseText + "\n\n*(Showing cached/offline advisory recommendation)*",
      'offline': true
    };
  }
}
