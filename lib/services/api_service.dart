import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'dart:io';
import 'package:flutter/foundation.dart';

class ApiService {
  static String get baseUrl {
    if (kIsWeb) return 'http://localhost:3030/api';
    if (Platform.isAndroid) return 'http://10.0.2.2:3030/api';
    return 'http://localhost:3030/api';
  }

  final _storage = const FlutterSecureStorage();

  // Headers helper
  Future<Map<String, String>> _getHeaders() async {
    final token = await _storage.read(key: 'token');
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
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
    int levelId,
  ) async {
    final url = Uri.parse('$baseUrl/$slugSection/levels/$levelId/soal');
    try {
      final headers = await _getHeaders();
      final response = await http.get(url, headers: headers);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {'success': true, 'data': data};
      } else {
        return {
          'success': false,
          'message': 'Failed to load soals (Status: ${response.statusCode})',
        };
      }
    } catch (e) {
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

      print('=== CREATE ATTEMPT DEBUG ===');
      print('URL: $url');
      print('Headers: $headers');
      print('Body: ${jsonEncode({'id_level': levelId})}');

      final response = await http.post(
        url,
        headers: headers,
        body: jsonEncode({'id_level': levelId}),
      );

      print('Response Status: ${response.statusCode}');
      print('Response Body: ${response.body}');
      print('=== END DEBUG ===');

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
      print('EXCEPTION in createAttempt: $e');
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
      print('Submitting PG to: $url');
      print('Payload: {idOpsi: $opsiId}');

      final response = await http.post(
        url,
        headers: headers,
        body: jsonEncode({'idOpsi': opsiId}),
      );

      print('PG Response status: ${response.statusCode}');
      print('PG Response body: ${response.body}');

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
      print('Exception in submitJawabanPG: $e');
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
      print('Submitting Essay to: $url');
      print('Payload: {jawaban: $jawaban}');

      final response = await http.post(
        url,
        headers: headers,
        body: jsonEncode({'jawaban': jawaban}),
      );

      print('Essay Response status: ${response.statusCode}');
      print('Essay Response body: ${response.body}');

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
      print('Exception in submitJawabanEsai: $e');
      return {'success': false, 'message': e.toString()};
    }
  }

  Future<Map<String, dynamic>> submitAttempt(int attemptId) async {
    final url = Uri.parse('$baseUrl/attempts/submit');
    try {
      final headers = await _getHeaders();
      final body = jsonEncode({'id_attempt': attemptId});

      print('Calling Finalize/Submit Attempt: $url');
      print('Body: $body');

      final response = await http.post(url, headers: headers, body: body);

      print('submitAttempt - Status Code: ${response.statusCode}');
      print('submitAttempt - Response Body: ${response.body}');

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
      print('submitAttempt - Exception: $e');
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
        final data = jsonDecode(response.body);
        return {'success': true, 'data': data};
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
      print("ini id nya" + pelajarId.toString());
      print('=== GET ATTEMPTS BY PELAJAR DEBUG ===');
      print('URL: $url');
      print('Response Status: ${response.statusCode}');
      print('Response Body: ${response.body}');
      print('=== END DEBUG ===');

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
      print('Exception in getAttemptsByPelajarId: $e');
      return {'success': false, 'message': e.toString()};
    }
  }
}
