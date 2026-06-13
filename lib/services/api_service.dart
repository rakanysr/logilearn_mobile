import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class ApiService {
  static String get baseUrl {
    final apiUrl = dotenv.env['VITE_API_URL'] ?? 'http://localhost:3030';
    return '$apiUrl/api';
  }

  final _storage = const FlutterSecureStorage();

  // Cache helper untuk soal
  String _getSoalCacheKey(String slugSection, int levelId) {
    return 'soal_cache_${slugSection}_$levelId';
  }

  Future<void> _saveSoalToCache(
    String slugSection,
    int levelId,
    dynamic soalData,
  ) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = _getSoalCacheKey(slugSection, levelId);
      final jsonString = jsonEncode(soalData);
      await prefs.setString(key, jsonString);
      debugPrint('✅ Soal cached untuk $slugSection level $levelId');
    } catch (e) {
      debugPrint('❌ Error saving soal to cache: $e');
    }
  }

  Future<Map<String, dynamic>?> _getSoalFromCache(
    String slugSection,
    int levelId,
  ) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = _getSoalCacheKey(slugSection, levelId);
      final jsonString = prefs.getString(key);
      if (jsonString != null) {
        final data = jsonDecode(jsonString);
        debugPrint(
          '✅ Soal loaded from cache untuk $slugSection level $levelId',
        );
        return {'success': true, 'data': data};
      }
      return null;
    } catch (e) {
      debugPrint('❌ Error getting soal from cache: $e');
      return null;
    }
  }

  static String? _cachedToken;

  static void clearCache() {
    _cachedToken = null;
  }

  // Headers helper
  Future<Map<String, String>> _getHeaders() async {
    _cachedToken ??= await _storage.read(key: 'token');
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $_cachedToken',
    };
  }

  Future<Map<String, dynamic>> getSections() async {
    final url = Uri.parse('$baseUrl/sections');
    try {
      final headers = await _getHeaders();
      final response = await http.get(url, headers: headers);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {'success': true, 'data': data};
      } else {
        return {'success': false, 'message': 'Failed to load sections'};
      }
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  Future<Map<String, dynamic>> getProfile() async {
    final url = Uri.parse('$baseUrl/profile');
    try {
      final headers = await _getHeaders();
      final response = await http.get(url, headers: headers);

      final data = jsonDecode(response.body);
      return {'status_code': response.statusCode, 'data': data};
    } catch (e) {
      return {'status_code': 500, 'message': e.toString()};
    }
  }

  Future<Map<String, dynamic>> changePassword(
    String oldPassword,
    String newPassword,
  ) async {
    final url = Uri.parse('$baseUrl/profile/change-password');
    try {
      final headers = await _getHeaders();
      final response = await http.put(
        url,
        headers: headers,
        body: jsonEncode({
          'oldPassword': oldPassword,
          'newPassword': newPassword,
        }),
      );

      final data = jsonDecode(response.body);
      return {
        'status_code': response.statusCode,
        'payload': data['payload'] ?? data,
        'message': data['message'] ?? data['meta']?['message'],
      };
    } catch (e) {
      return {'status_code': 500, 'message': e.toString()};
    }
  }

  Future<Map<String, dynamic>> getSoalsByLevel(
    String slugSection,
    int levelId, {
    bool useCache = true,
    bool forceRefresh = false,
  }) async {
    if (useCache && !forceRefresh) {
      final cachedData = await _getSoalFromCache(slugSection, levelId);
      if (cachedData != null) {
        return cachedData;
      }
    }

    final url = Uri.parse('$baseUrl/$slugSection/levels/$levelId/soal');
    try {
      final headers = await _getHeaders();
      final response = await http.get(url, headers: headers);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        await _saveSoalToCache(slugSection, levelId, data);
        return {'success': true, 'data': data};
      } else {
        return {
          'success': false,
          'message': 'Failed to load soals (Status: ${response.statusCode})',
        };
      }
    } catch (e) {
      // Jika error fetch dari API, coba load dari cache sebagai fallback
      if (useCache) {
        final cachedData = await _getSoalFromCache(slugSection, levelId);
        if (cachedData != null) {
          debugPrint('⚠️ API error, using cached data: $e');
          return cachedData;
        }
      }
      return {'success': false, 'message': e.toString()};
    }
  }

  Future<Map<String, dynamic>> getLevelsBySection(String slugSection) async {
    final url = Uri.parse('$baseUrl/$slugSection/levels');
    try {
      final headers = await _getHeaders();
      final response = await http.get(url, headers: headers);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {'success': true, 'data': data};
      } else {
        return {'success': false, 'message': 'Failed to load levels'};
      }
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  Future<Map<String, dynamic>> getLevelById(
    String slugSection,
    int levelId,
  ) async {
    final url = Uri.parse('$baseUrl/$slugSection/levels/$levelId');
    try {
      final headers = await _getHeaders();
      final response = await http.get(url, headers: headers);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {'success': true, 'data': data};
      } else {
        return {'success': false, 'message': 'Failed to load level'};
      }
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  Future<Map<String, dynamic>> createAttempt(int levelId) async {
    final url = Uri.parse('$baseUrl/attempts');
    try {
      final headers = await _getHeaders();

      debugPrint('=== CREATE ATTEMPT DEBUG ===');
      debugPrint('URL: $url');
      debugPrint('Headers: $headers');
      debugPrint('Body: ${jsonEncode({'id_level': levelId})}');

      final response = await http.post(
        url,
        headers: headers,
        body: jsonEncode({'id_level': levelId}),
      );

      debugPrint('Response Status: ${response.statusCode}');
      debugPrint('Response Body: ${response.body}');
      debugPrint('=== END DEBUG ===');

      if (response.statusCode == 201 || response.statusCode == 200) {
        final body = jsonDecode(response.body);
        return {'success': true, 'data': body};
      } else {
        final errorBody = response.body;
        return {
          'success': false,
          'message':
              'Failed to create attempt: ${response.statusCode} - $errorBody',
        };
      }
    } catch (e) {
      debugPrint('EXCEPTION in createAttempt: $e');
      return {'success': false, 'message': e.toString()};
    }
  }

  Future<Map<String, dynamic>> submitJawabanPG(
    int attemptId,
    int opsiId,
  ) async {
    final url = Uri.parse('$baseUrl/attempts/$attemptId/jawaban-pg');
    try {
      final headers = await _getHeaders();
      debugPrint('Submitting PG to: $url');
      debugPrint('Payload: {idOpsi: $opsiId}');

      final response = await http.post(
        url,
        headers: headers,
        body: jsonEncode({'idOpsi': opsiId}),
      );

      debugPrint('PG Response status: ${response.statusCode}');
      debugPrint('PG Response body: ${response.body}');

      if (response.statusCode == 201 || response.statusCode == 200) {
        final body = jsonDecode(response.body);
        return {'success': true, 'data': body};
      } else {
        return {
          'success': false,
          'message': 'Failed to submit PG answer: ${response.statusCode}',
        };
      }
    } catch (e) {
      debugPrint('Exception in submitJawabanPG: $e');
      return {'success': false, 'message': e.toString()};
    }
  }

  Future<Map<String, dynamic>> submitJawabanEsai(
    int attemptId,
    int soalId,
    String jawaban,
  ) async {
    final url = Uri.parse('$baseUrl/attempts/$attemptId/jawaban-esai/$soalId');
    try {
      final headers = await _getHeaders();
      debugPrint('Submitting Essay to: $url');
      debugPrint('Payload: {jawaban: $jawaban}');

      final response = await http.post(
        url,
        headers: headers,
        body: jsonEncode({'jawaban': jawaban}),
      );

      debugPrint('Essay Response status: ${response.statusCode}');
      debugPrint('Essay Response body: ${response.body}');

      if (response.statusCode == 201 || response.statusCode == 200) {
        final body = jsonDecode(response.body);
        return {'success': true, 'data': body};
      } else {
        return {
          'success': false,
          'message': 'Failed to submit Essay answer: ${response.statusCode}',
        };
      }
    } catch (e) {
      debugPrint('Exception in submitJawabanEsai: $e');
      return {'success': false, 'message': e.toString()};
    }
  }

  Future<Map<String, dynamic>> submitAttempt(int attemptId) async {
    final url = Uri.parse('$baseUrl/attempts/submit');
    try {
      final headers = await _getHeaders();
      final body = jsonEncode({'id_attempt': attemptId});

      debugPrint('Calling Finalize/Submit Attempt: $url');
      debugPrint('Body: $body');

      final response = await http.post(url, headers: headers, body: body);

      debugPrint('submitAttempt - Status Code: ${response.statusCode}');
      debugPrint('submitAttempt - Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {'success': true, 'data': data};
      } else {
        return {
          'success': false,
          'message':
              'Failed to submit attempt (Status: ${response.statusCode})',
          'error': response.body,
        };
      }
    } catch (e) {
      debugPrint('submitAttempt - Exception: $e');
      return {'success': false, 'message': e.toString()};
    }
  }

  Future<Map<String, dynamic>> getAttempts({int? levelId}) async {
    var urlString = '$baseUrl/attempts';
    if (levelId != null) {
      urlString += '?level_id=$levelId';
    }
    final url = Uri.parse(urlString);

    try {
      final headers = await _getHeaders();
      final response = await http.get(url, headers: headers);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {'success': true, 'data': data};
      } else {
        return {'success': false, 'message': 'Failed to fetch attempts'};
      }
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  Future<Map<String, dynamic>> getAttemptById(int attemptId) async {
    final url = Uri.parse('$baseUrl/attempts/$attemptId');
    try {
      final headers = await _getHeaders();
      final response = await http.get(url, headers: headers);

      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);
        if (body is Map && body['payload'] is Map && body['payload']['datas'] != null) {
          return {'success': true, 'data': body['payload']['datas']};
        }
        return {'success': true, 'data': body};
      } else {
        return {'success': false, 'message': 'Failed to fetch attempt details'};
      }
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  /// Get all attempts for a specific student (pelajar)
  Future<Map<String, dynamic>> getAttemptsByPelajarId(int pelajarId) async {
    final url = Uri.parse('$baseUrl/attempts/pelajar/$pelajarId');

    try {
      final headers = await _getHeaders();
      final response = await http.get(url, headers: headers);
      debugPrint("ini id nya$pelajarId");
      debugPrint('=== GET ATTEMPTS BY PELAJAR DEBUG ===');
      debugPrint('URL: $url');
      debugPrint('Response Status: ${response.statusCode}');
      debugPrint('Response Body: ${response.body}');
      debugPrint('=== END DEBUG ===');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {'success': true, 'data': data};
      } else {
        return {
          'success': false,
          'message': 'Failed to fetch attempts for pelajar',
        };
      }
    } catch (e) {
      debugPrint('Exception in getAttemptsByPelajarId: $e');
      return {'success': false, 'message': e.toString()};
    }
  }

  Future<Map<String, dynamic>> getStats(int pelajarId) async {
    final url = Uri.parse('$baseUrl/pelajar/$pelajarId/stats');
    try {
      final headers = await _getHeaders();
      final response = await http.get(url, headers: headers);
      final data = jsonDecode(response.body);
      return {
        'success': response.statusCode == 200,
        'status_code': response.statusCode,
        'data': data,
        'message': data['message'] ?? 'Gagal memuat statistik',
      };
    } catch (e) {
      return {
        'success': false,
        'status_code': 500,
        'message': e.toString(),
      };
    }
  }

  Future<Map<String, dynamic>> getBadges(int pelajarId) async {
    final url = Uri.parse('$baseUrl/pelajar/$pelajarId/badges');
    try {
      final headers = await _getHeaders();
      final response = await http.get(url, headers: headers);
      final data = jsonDecode(response.body);
      return {
        'success': response.statusCode == 200,
        'status_code': response.statusCode,
        'data': data,
        'message': data['message'] ?? 'Gagal memuat badge',
      };
    } catch (e) {
      return {
        'success': false,
        'status_code': 500,
        'message': e.toString(),
      };
    }
  }

  Future<Map<String, dynamic>> getGlobalLeaderboard({int page = 1, int limit = 10}) async {
    final url = Uri.parse('$baseUrl/global/leaderboard?page=$page&limit=$limit');
    try {
      final headers = await _getHeaders();
      final response = await http.get(url, headers: headers);
      final data = jsonDecode(response.body);
      return {
        'success': response.statusCode == 200,
        'status_code': response.statusCode,
        'data': data,
        'message': data['message'] ?? 'Gagal memuat leaderboard',
      };
    } catch (e) {
      return {
        'success': false,
        'status_code': 500,
        'message': e.toString(),
      };
    }
  }
}
