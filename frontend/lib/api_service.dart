import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:path/path.dart' as path;
import 'api_config.dart';
import 'user_session.dart';


class ApiService {
  static final Map<String, String> _headers = {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
    'Bypass-Tunnel-Reminder': 'true',
  };

  // ─────────────────────────────────────────
  // AUTHENTICATION APIs
  // ─────────────────────────────────────────

  static Future<Map<String, dynamic>> login(String email, String password) async {
    try {
      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/login'),
        headers: _headers,
        body: jsonEncode({
          'email': email,
          'password': password,
        }),
      );

      final decoded = jsonDecode(response.body);
      if (response.statusCode == 200) {
        if (decoded['user'] != null) {
          UserSession.currentUser = User.fromJson(decoded['user']);
        }
        return {'success': true, 'message': decoded['message'] ?? 'Login successful'};
      } else {
        return {'success': false, 'error': decoded['error'] ?? 'Invalid credentials'};
      }
    } catch (e) {
      return {'success': false, 'error': 'Connection failed: $e'};
    }
  }

  static Future<Map<String, dynamic>> signup({
    required String name,
    required String email,
    required String phone,
    required String password,
    required String confirmPassword,
    String? state,
  }) async {
    try {
      final response = await http.post(
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
      );

      final decoded = jsonDecode(response.body);
      if (response.statusCode == 201) {
        return {'success': true, 'message': decoded['message'] ?? 'User registered successfully'};
      } else {
        return {'success': false, 'error': decoded['error'] ?? 'Registration failed'};
      }
    } catch (e) {
      return {'success': false, 'error': 'Connection failed: $e'};
    }
  }

  static Future<Map<String, dynamic>> getActiveSessionUser() async {
    try {
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/get_current_user'),
        headers: _headers,
      );

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        UserSession.currentUser = User.fromJson(decoded);
        return {'success': true, 'user': UserSession.currentUser};
      } else {
        return {'success': false, 'error': 'No active session found'};
      }
    } catch (e) {
      return {'success': false, 'error': 'Connection failed: $e'};
    }
  }

  static Future<Map<String, dynamic>> logout(String email) async {
    try {
      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/logout'),
        headers: _headers,
        body: jsonEncode({'email': email}),
      );

      final decoded = jsonDecode(response.body);
      if (response.statusCode == 200) {
        UserSession.currentUser = null;
        return {'success': true, 'message': decoded['message'] ?? 'Logged out successfully'};
      } else {
        return {'success': false, 'error': decoded['error'] ?? 'Logout failed'};
      }
    } catch (e) {
      return {'success': false, 'error': 'Connection failed: $e'};
    }
  }

  // ─────────────────────────────────────────
  // PROFILE & FARM DETAILS APIs
  // ─────────────────────────────────────────

  static Future<Map<String, dynamic>> updateProfile({
    required int userId,
    required String name,
    required String phone,
    String? state,
  }) async {
    try {
      final response = await http.put(
        Uri.parse('${ApiConfig.baseUrl}/profile/$userId'),
        headers: _headers,
        body: jsonEncode({
          'name': name,
          'phone': phone,
          'state': state,
        }),
      );

      final decoded = jsonDecode(response.body);
      if (response.statusCode == 200) {
        // Update local session info
        if (UserSession.currentUser != null && UserSession.currentUser!.id == userId) {
          UserSession.currentUser = User(
            id: userId,
            name: name,
            phone: phone,
            email: UserSession.currentUser!.email,
            state: state,
          );
        }
        return {'success': true, 'message': decoded['message'] ?? 'Profile updated'};
      } else {
        return {'success': false, 'error': decoded['error'] ?? 'Update failed'};
      }
    } catch (e) {
      return {'success': false, 'error': 'Connection failed: $e'};
    }
  }

  static Future<Map<String, dynamic>> getFarmDetails(int userId) async {
    try {
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/farm_details/$userId'),
        headers: _headers,
      );

      final decoded = jsonDecode(response.body);
      if (response.statusCode == 200) {
        return {'success': true, 'data': decoded};
      } else {
        return {'success': false, 'error': decoded['error'] ?? 'Farm details not found'};
      }
    } catch (e) {
      return {'success': false, 'error': 'Connection failed: $e'};
    }
  }

  static Future<Map<String, dynamic>> updateFarmDetails({
    required int userId,
    double? landArea,
    String? primaryCrops,
    String? soilType,
    String? irrigation,
    String? region,
  }) async {
    try {
      final response = await http.put(
        Uri.parse('${ApiConfig.baseUrl}/farm_details/$userId'),
        headers: _headers,
        body: jsonEncode({
          if (landArea != null) 'land_area': landArea,
          if (primaryCrops != null) 'primary_crops': primaryCrops,
          if (soilType != null) 'soil_type': soilType,
          if (irrigation != null) 'irrigation': irrigation,
          if (region != null) 'region': region,
        }),
      );

      final decoded = jsonDecode(response.body);
      if (response.statusCode == 200) {
        return {'success': true, 'message': decoded['message'] ?? 'Farm details updated'};
      } else {
        return {'success': false, 'error': decoded['error'] ?? 'Update failed'};
      }
    } catch (e) {
      return {'success': false, 'error': 'Connection failed: $e'};
    }
  }

  // ─────────────────────────────────────────
  // CROP ADVISORY APIs
  // ─────────────────────────────────────────

  static Future<List<dynamic>> getCropAdvisories(int userId, {String? crop}) async {
    try {
      String url = '${ApiConfig.baseUrl}/crop_advisories/$userId';
      if (crop != null && crop.isNotEmpty) {
        url += '?crop=${Uri.encodeComponent(crop)}';
      }
      final response = await http.get(Uri.parse(url), headers: _headers);
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
    } catch (_) {}
    return [];
  }

  static Future<Map<String, dynamic>> addCropAdvisory({
    required int userId,
    required String crop,
    required String title,
    required String description,
    String? emoji,
    String? priority,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/crop_advisories'),
        headers: _headers,
        body: jsonEncode({
          'user_id': userId,
          'crop': crop,
          'title': title,
          'description': description,
          if (emoji != null) 'emoji': emoji,
          if (priority != null) 'priority': priority,
        }),
      );
      final decoded = jsonDecode(response.body);
      if (response.statusCode == 201) {
        return {'success': true, 'id': decoded['id']};
      }
      return {'success': false, 'error': decoded['error'] ?? 'Failed to add'};
    } catch (e) {
      return {'success': false, 'error': '$e'};
    }
  }

  // ─────────────────────────────────────────
  // PEST & DISEASE APIs
  // ─────────────────────────────────────────

  static Future<List<dynamic>> getPestAlerts({String? region, String? crop}) async {
    try {
      String url = '${ApiConfig.baseUrl}/pest_alerts';
      final List<String> params = [];
      if (region != null && region.isNotEmpty) {
        params.add('region=${Uri.encodeComponent(region)}');
      }
      if (crop != null && crop.isNotEmpty) {
        params.add('crop=${Uri.encodeComponent(crop)}');
      }
      if (params.isNotEmpty) {
        url += '?${params.join('&')}';
      }
      final response = await http.get(Uri.parse(url), headers: _headers);
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
    } catch (_) {}
    return [];
  }

  static Future<List<dynamic>> getTreatments({String? crop, String? type}) async {
    try {
      String url = '${ApiConfig.baseUrl}/treatments';
      final List<String> params = [];
      if (crop != null && crop.isNotEmpty) {
        params.add('crop=${Uri.encodeComponent(crop)}');
      }
      if (type != null && type.isNotEmpty) {
        params.add('type=${Uri.encodeComponent(type)}');
      }
      if (params.isNotEmpty) {
        url += '?${params.join('&')}';
      }
      final response = await http.get(Uri.parse(url), headers: _headers);
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
    } catch (_) {}
    return [];
  }

  // ─────────────────────────────────────────
  // MARKET PRICE APIs
  // ─────────────────────────────────────────

  static Future<List<dynamic>> getStates() async {
    try {
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/api/states'),
        headers: _headers,
      );
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
    } catch (_) {}
    return [];
  }

  static Future<List<dynamic>> getMandisByState(String state) async {
    try {
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/api/mandis?state=${Uri.encodeComponent(state)}'),
        headers: _headers,
      );
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
    } catch (_) {}
    return [];
  }

  static Future<Map<String, dynamic>> getMarketPricesByState({
    String? state,
    String? mandi,
    String? crop,
  }) async {
    try {
      String url = '${ApiConfig.baseUrl}/api/market-prices';
      final List<String> params = [];
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
        url += '?${params.join('&')}';
      }
      final response = await http.get(Uri.parse(url), headers: _headers);
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
    } catch (_) {}
    return {};
  }

  static Future<List<dynamic>> getPriceHistory({
    required String mandi,
    required String crop,
    int days = 30,
  }) async {
    try {
      final url = '${ApiConfig.baseUrl}/api/price-history'
          '?mandi=${Uri.encodeComponent(mandi)}'
          '&crop=${Uri.encodeComponent(crop)}'
          '&days=$days';
      final response = await http.get(Uri.parse(url), headers: _headers);
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
    } catch (_) {}
    return [];
  }

  static Future<List<dynamic>> getMarketPrices({String? mandi, String? category}) async {
    try {
      String url = '${ApiConfig.baseUrl}/market_prices';
      final List<String> params = [];
      if (mandi != null && mandi.isNotEmpty) {
        params.add('mandi=${Uri.encodeComponent(mandi)}');
      }
      if (category != null && category.isNotEmpty) {
        params.add('category=${Uri.encodeComponent(category)}');
      }
      if (params.isNotEmpty) {
        url += '?${params.join('&')}';
      }
      final response = await http.get(Uri.parse(url), headers: _headers);
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
    } catch (_) {}
    return [];
  }

  static Future<List<String>> getMandis() async {
    try {
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/mandis'),
        headers: _headers,
      );
      if (response.statusCode == 200) {
        final List<dynamic> list = jsonDecode(response.body);
        return list.map((e) => e.toString()).toList();
      }
    } catch (_) {}
    return [];
  }

  // ─────────────────────────────────────────
  // FARM SCHEDULE APIs
  // ─────────────────────────────────────────

  static Future<List<dynamic>> getFarmSchedule(int userId) async {
    try {
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/farm_schedule/$userId'),
        headers: _headers,
      );
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
    } catch (_) {}
    return [];
  }

  static Future<Map<String, dynamic>> addFarmSchedule({
    required int userId,
    required String activity,
    required String scheduledAt, // expects format YYYY-MM-DD HH:MM
  }) async {
    try {
      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/farm_schedule'),
        headers: _headers,
        body: jsonEncode({
          'user_id': userId,
          'activity': activity,
          'scheduled_at': scheduledAt,
        }),
      );
      final decoded = jsonDecode(response.body);
      if (response.statusCode == 201) {
        return {'success': true, 'id': decoded['id']};
      }
      return {'success': false, 'error': decoded['error'] ?? 'Failed to add'};
    } catch (e) {
      return {'success': false, 'error': '$e'};
    }
  }

  static Future<Map<String, dynamic>> updateScheduleStatus(int scheduleId, String status) async {
    try {
      final response = await http.put(
        Uri.parse('${ApiConfig.baseUrl}/farm_schedule/$scheduleId'),
        headers: _headers,
        body: jsonEncode({'status': status}),
      );
      final decoded = jsonDecode(response.body);
      if (response.statusCode == 200) {
        return {'success': true};
      }
      return {'success': false, 'error': decoded['error'] ?? 'Failed to update'};
    } catch (e) {
      return {'success': false, 'error': '$e'};
    }
  }

  static Future<Map<String, dynamic>> deleteFarmSchedule(int scheduleId) async {
    try {
      final response = await http.delete(
        Uri.parse('${ApiConfig.baseUrl}/farm_schedule/$scheduleId'),
        headers: _headers,
      );
      final decoded = jsonDecode(response.body);
      if (response.statusCode == 200) {
        return {'success': true};
      }
      return {'success': false, 'error': decoded['error'] ?? 'Failed to delete'};
    } catch (e) {
      return {'success': false, 'error': '$e'};
    }
  }

  // ─────────────────────────────────────────
  // FARMING TIPS & NEWS APIs
  // ─────────────────────────────────────────

  static Future<List<dynamic>> getFarmingTips({String? category}) async {
    try {
      String url = '${ApiConfig.baseUrl}/farming_tips';
      if (category != null && category.isNotEmpty) {
        url += '?category=${Uri.encodeComponent(category)}';
      }
      final response = await http.get(Uri.parse(url), headers: _headers);
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
    } catch (_) {}
    return [];
  }

  static Future<List<dynamic>> getNewsArticles({String? category, bool? featured, int? limit}) async {
    try {
      String url = '${ApiConfig.baseUrl}/news_articles';
      final List<String> params = [];
      if (category != null && category.isNotEmpty) {
        params.add('category=${Uri.encodeComponent(category)}');
      }
      if (featured != null) {
        params.add('featured=$featured');
      }
      if (limit != null) {
        params.add('limit=$limit');
      }
      if (params.isNotEmpty) {
        url += '?${params.join('&')}';
      }
      final response = await http.get(Uri.parse(url), headers: _headers);
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
    } catch (_) {}
    return [];
  }

  static Future<Map<String, dynamic>> askAI(String message) async {
    try {
      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/api/ask-ai'),
        headers: _headers,
        body: jsonEncode({'message': message}),
      );
      final decoded = jsonDecode(response.body);
      if (response.statusCode == 200) {
        return {'success': true, 'response': decoded['response']};
      }
      return {'success': false, 'error': decoded['error'] ?? 'AI request failed'};
    } catch (e) {
      return {'success': false, 'error': 'Connection failed: $e'};
    }
  }

  static Future<Map<String, dynamic>> analyzeImage(File imageFile) async {
    try {
      final uri = Uri.parse('${ApiConfig.baseUrl}/api/analyze-image');
      final request = http.MultipartRequest('POST', uri);
      
      request.headers.addAll({
        'Accept': 'application/json',
        'Bypass-Tunnel-Reminder': 'true',
      });
      
      final ext = path.extension(imageFile.path).toLowerCase();
      String mimeType = 'image/jpeg';
      if (ext == '.png') {
        mimeType = 'image/png';
      } else if (ext == '.gif') {
        mimeType = 'image/gif';
      }
      
      request.files.add(
        await http.MultipartFile.fromPath(
          'image',
          imageFile.path,
          contentType: MediaType.parse(mimeType),
        ),
      );
      
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);
      
      final decoded = jsonDecode(response.body);
      if (response.statusCode == 200) {
        return decoded;
      }
      return {'success': false, 'message': decoded['message'] ?? 'Image upload failed'};
    } catch (e) {
      return {'success': false, 'message': 'Image analysis failed: $e'};
    }
  }
}
