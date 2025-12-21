import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'dart:io';
import 'package:flutter/foundation.dart';

class AuthService {
  // Use 10.0.2.2 for Android Emulator, localhost for others
  static String get baseUrl {
    if (kIsWeb) return 'http://localhost:3030/api/auth';
    if (Platform.isAndroid) return 'http://10.0.2.2:3030/api/auth';
    return 'http://localhost:3030/api/auth';
  }

  final _storage = const FlutterSecureStorage();

  Future<bool> loginPelajar(String username, String password) async {
    final response = await http.post(
      Uri.parse("$baseUrl/login-pelajar"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({"username": username, "password": password}),
    );

    if (response.statusCode == 200) {
      final result = jsonDecode(response.body);

      await _storage.write(
        key: "token",
        value: result["payload"]["datas"]["token"],
      );

      await _storage.write(
        key: "id_pelajar",
        value: result["payload"]["datas"]["pelajar"]["id"].toString(),
      );

      await _storage.write(
        key: "nama_pelajar",
        value: result["payload"]["datas"]["pelajar"]["nama"].toString(),
      );

      return true;
    }
    return false;
  }

  Future<Map<String, dynamic>> registerPelajar({
    required String nama,
    required String username,
    required String password,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/register-pelajar'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'nama': nama,
          'username': username,
          'password': password,
        }),
      );

      print('🔵 Status Code: ${response.statusCode}');
      print('🔵 Response Body: ${response.body}');

      final responseData = jsonDecode(response.body);

      return {
        'success': response.statusCode == 201,
        'statusCode': response.statusCode,
        'message': responseData['payload']?['message'] ?? 'Registrasi Gagal',
        'data': responseData,
      };
    } catch (e) {
      print('🔴 Error: $e');
      return {
        'success': false,
        'statusCode': 0,
        'message': 'Terjadi kesalahan: $e',
        'data': null,
      };
    }
  }

  Future<String?> getToken() async {
    return await _storage.read(key: "token");
  }

  Future<void> logout() async {
    await _storage.deleteAll();
  }
}
