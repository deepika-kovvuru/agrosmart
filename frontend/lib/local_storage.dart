import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

/// Central local persistence layer for AGROSMART offline-first architecture.
class LocalStorage {
  static const _keyUserSession = 'user_session';
  static const _keyLastSync = 'last_sync';
  static const _cachePrefix = 'cache_';

  // ─────────────────────────────────────────
  // SESSION
  // ─────────────────────────────────────────

  /// Save user session after successful online login.
  static Future<void> saveSession(Map<String, dynamic> user) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyUserSession, jsonEncode(user));
  }

  /// Load saved session. Returns null if not found.
  static Future<Map<String, dynamic>?> loadSession() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_keyUserSession);
    if (raw == null) return null;
    try {
      return jsonDecode(raw) as Map<String, dynamic>;
    } catch (_) {
      return null;
    }
  }

  /// Clear session on logout.
  static Future<void> clearSession() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyUserSession);
  }

  /// Check if a valid saved session exists.
  static Future<bool> hasSession() async {
    final session = await loadSession();
    return session != null && session['id'] != null;
  }

  // ─────────────────────────────────────────
  // GENERIC CACHE
  // ─────────────────────────────────────────

  /// Cache any JSON-encodable data under a key.
  static Future<void> saveCache(String key, dynamic data) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_cachePrefix + key, jsonEncode(data));
  }

  /// Load cached data. Returns null if key not found.
  static Future<dynamic> loadCache(String key) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_cachePrefix + key);
    if (raw == null) return null;
    try {
      return jsonDecode(raw);
    } catch (_) {
      return null;
    }
  }

  // ─────────────────────────────────────────
  // SYNC TIME
  // ─────────────────────────────────────────

  /// Save the current time as last sync timestamp.
  static Future<void> saveLastSync() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyLastSync, DateTime.now().toIso8601String());
  }

  /// Get last sync time as a formatted string, or null.
  static Future<String?> getLastSync() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_keyLastSync);
    if (raw == null) return null;
    try {
      final dt = DateTime.parse(raw).toLocal();
      return '${dt.day}/${dt.month}/${dt.year} ${dt.hour.toString().padLeft(2,'0')}:${dt.minute.toString().padLeft(2,'0')}';
    } catch (_) {
      return raw;
    }
  }

  // ─────────────────────────────────────────
  // OFFLINE CREDENTIALS (for offline login)
  // ─────────────────────────────────────────

  /// Save a hash of the user's email for offline identification.
  static Future<void> saveOfflineCredentials(String email) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('offline_email', email.toLowerCase().trim());
  }

  /// Check if the provided email matches the offline session.
  static Future<bool> verifyOfflineEmail(String email) async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString('offline_email');
    return saved != null && saved == email.toLowerCase().trim();
  }
}
