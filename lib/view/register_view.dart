// lib/screens/registrasi_screen.dart

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class RegistrasiScreen extends StatefulWidget {
  const RegistrasiScreen({super.key});

  @override
  State<RegistrasiScreen> createState() => _RegistrasiScreenState();
}

class _RegistrasiScreenState extends State<RegistrasiScreen> {
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isPasswordVisible = false;

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
        title: Text(
          'Registrasi',
          style: GoogleFonts.inter(
            textStyle: TextStyle(fontWeight: FontWeight.w900),
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: Colors.black,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              'Untuk pengguna baru, anda bisa membuat akun dengan memasukkan username baru dan password baru.',
              style: GoogleFonts.inter(
                textStyle: TextStyle(fontSize: 14, color: Colors.grey[600]),
              ),
            ),
            SizedBox(height: 30),
            //Username Input
            Text(
              'Username',
              style: GoogleFonts.inter(
                textStyle: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
            SizedBox(height: 8),
            TextField(
              controller: _usernameController,
              decoration: InputDecoration(
                hintText: 'Masukkan Username',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8.0),
                ),
                contentPadding: EdgeInsets.symmetric(
                  vertical: 12,
                  horizontal: 15,
                ),
              ),
            ),
            SizedBox(height: 20),
            //Password Input
            Text(
              'Kata Sandi',
              style: GoogleFonts.inter(
                textStyle: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
            SizedBox(height: 8),
            TextField(
              controller: _passwordController,
              obscureText: !_isPasswordVisible,
              decoration: InputDecoration(
                hintText: 'Masukkan Kata Sandi',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8.0),
                ),
                contentPadding: EdgeInsets.symmetric(
                  vertical: 12,
                  horizontal: 15,
                ),
                suffixIcon: IconButton(
                  icon: Icon(
                    _isPasswordVisible
                        ? Icons.visibility
                        : Icons.visibility_off,
                    color: Colors.grey,
                  ),
                  onPressed: () {
                    setState(() {
                      _isPasswordVisible = !_isPasswordVisible;
                    });
                  },
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(20.0),
        child: ElevatedButton(
          onPressed: () {
            String username = _usernameController.text;
            String password = _passwordController.text;
            debugPrint('Username: $username');
            debugPrint('Password: $password');
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: Color(0xFF2977FF), // Warna biru sesuai prototype
            foregroundColor: Colors.white, // Warna teks putih
            padding: EdgeInsets.symmetric(vertical: 15),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8.0),
            ),
            minimumSize: Size(double.infinity, 0), // Lebar penuh
          ),
          child: Text(
            'LANJUTKAN',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
          ),
        ),
      ),
    );
  }
}
