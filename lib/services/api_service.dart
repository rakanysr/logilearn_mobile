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

  // --- Data ---

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
    String oldPw,
    String newPw,
  ) async {
    final url = Uri.parse('$baseUrl/profile/change-password');
    try {
      final headers = await _getHeaders();
      final response = await http.put(
        url,
        headers: headers,
        body: jsonEncode({'oldPassword': oldPw, 'newPassword': newPw}),
      );
      return jsonDecode(response.body);
    } catch (e) {
      return {'status': 500, 'message': e.toString()};
    }
  }
}
