import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class AuthService {
  static const String baseUrl = "http://10.0.2.2:3030/api/auth";
  final _storage = const FlutterSecureStorage();

  Future<bool> loginPelajar(String username, String password) async {
    final response = await http.post(
      Uri.parse("$baseUrl/login-pelajar"),
      headers: {
        "Content-Type": "application/json",
      },
      body: jsonEncode({
        "username": username,
        "password": password
      })
    );

    if (response.statusCode == 200){
      final result = jsonDecode(response.body);

      await _storage.write(
        key: "token",
        value: result["payload"]["datas"]["token"]
      );

      await _storage.write(
        key: "id_pelajar", 
        value: result["payload"]["datas"]["pelajar"]["id"].toString()
      );

      await _storage.write(
        key: "nama_pelajar", 
        value: result["payload"]["datas"]["pelajar"]["nama"].toString()
      );

      return true;
    }
    return false;
  }

  Future<String?> getToken() async {
    return await _storage.read(key: "token");
  }

  Future<void> logout() async {
    await _storage.deleteAll();
  }
}