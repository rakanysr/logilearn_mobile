import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'dart:io';
import 'package:flutter/foundation.dart';

class AuthService {
  static String get baseUrl {
    if (kIsWeb) return 'http://localhost:3030/api/auth';
    if (Platform.isAndroid) return 'http://10.0.2.2:3030/api/auth';
    return 'http://localhost:3030/api/auth';
  }

  final _storage = const FlutterSecureStorage();

  String? validatePassowrd(String password) {
    if (password.isEmpty) {
      return 'Password tidak boleh kosong.';
    }
    if (password.length < 8) {
      return 'Password harus terdiri dari minimal 8 karakter.';
    }
    if (!password.contains(RegExp(r'[A-Z]'))) {
      return 'Password harus mengandung minimal satu huruf kapital.';
    }
    if (!password.contains(RegExp(r'[0-9]'))) {
      return 'Password harus mengandung minimal satu angka.';
    }
    return null;
  }

  String? validateUsername(String username) {
    if (username.isEmpty) {
      return 'Username tidak boleh kosong.';
    }
    if (username.length < 4) {
      return 'Username harus terdiri dari minimal 4 karakter.';
    }
    if (username.contains(' ')) {
      return 'Username tidak boleh mengandung spasi.';
    }
    return null;
  }

  String? validateReisterInput({
    required String nama,
    required String username,
    required String password,
  }) {
    if (nama.isEmpty || username.isEmpty || password.isEmpty) {
      return 'Harap isi semua kolom!.';
    }
    String? usernameError = validateUsername(username);
    if (usernameError != null) {
      return usernameError;
    }
    String? passwordError = validatePassowrd(password);
    if (passwordError != null) {
      return passwordError;
    }
    return null;
  }

  Future<Map<String, dynamic>> loginPelajar(
    String username,
    String password,
  ) async {
    try {
      final response = await http.post(
        Uri.parse("$baseUrl/login-pelajar"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"username": username, "password": password}),
      );

      print('Status Code: ${response.statusCode}');
      print('Response Body: ${response.body}');

      final responseData = jsonDecode(response.body);

      if (response.statusCode == 200) {
        await _storage.write(
          key: "token",
          value: responseData["payload"]["datas"]["token"],
        );

        await _storage.write(
          key: "id_pelajar",
          value: responseData["payload"]["datas"]["pelajar"]["id"].toString(),
        );

        await _storage.write(
          key: "nama_pelajar",
          value: responseData["payload"]["datas"]["pelajar"]["nama"].toString(),
        );
      }

      return {
        'success': response.statusCode == 200,
        'statusCode': response.statusCode,
        'message': responseData['payload']?['message'] ?? 'Login gagal',
        'data': responseData,
      };
    } catch (e) {
      print('Error Login: $e');
      return {
        'success': false,
        'statusCode': 0,
        'message': 'Terjadi kesalahan: $e',
        'data': null,
      };
    }
  }

  Future<Map<String, dynamic>> registerPelajar({
    required String nama,
    required String username,
    required String password,
  }) async {
    String? validationError = validateReisterInput(
      nama: nama,
      username: username,
      password: password,
    );
    if (validationError != null) {
      return {
        'success': false,
        'statusCode': 400,
        'message': validationError,
        'data': null,
      };
    }

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
