import 'package:flutter/material.dart';
import 'login_view.dart';
import '../services/auth_service.dart';

class RegisterView extends StatefulWidget {
  const RegisterView({super.key});

  @override
  State<RegisterView> createState() => _RegisterViewState();
}

class _RegisterViewState extends State<RegisterView> {
  final TextEditingController _namaController = TextEditingController();
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final AuthService _authService = AuthService();

  bool _isLoading = false;

  Future<void> registerPelajar() async {
    // Validasi input
    if (_namaController.text.isEmpty ||
        _usernameController.text.isEmpty ||
        _passwordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Harap isi semua kolom!'),
          backgroundColor: Colors.red, // Merah untuk error validasi
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    // Panggil service
    final result = await _authService.registerPelajar(
      nama: _namaController.text,
      username: _usernameController.text,
      password: _passwordController.text,
    );

    if (!mounted) return;

    setState(() {
      _isLoading = false;
    });

    // Handle response
    if (result['success']) {
      // ✅ Snackbar BIRU untuk berhasil
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Registrasi Berhasil! Silakan Login.'),
          backgroundColor: Color(0xFF2977FF), // 🔵 Biru sesuai request
          duration: const Duration(seconds: 2),
        ),
      );

      // ✅ Pindah ke halaman Login setelah 1 detik
      Future.delayed(const Duration(seconds: 1), () {
        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const LoginView()),
          );
        }
      });
    } else {
      // ❌ Snackbar MERAH untuk gagal
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result['message']),
          backgroundColor: Colors.red, // 🔴 Merah untuk error
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 50.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Daftar Akun",
                style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              const Text("Silakan lengkapi data diri Anda."),
              const SizedBox(height: 30),
              TextField(
                controller: _namaController,
                decoration: const InputDecoration(
                  labelText: "Nama Lengkap",
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.person),
                ),
              ),
              const SizedBox(height: 15),
              TextField(
                controller: _usernameController,
                decoration: const InputDecoration(
                  labelText: "Username",
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.alternate_email),
                ),
              ),
              const SizedBox(height: 15),
              TextField(
                controller: _passwordController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: "Password",
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.lock),
                ),
              ),
              const SizedBox(height: 30),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : registerPelajar,
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text(
                          "Daftar",
                          style: TextStyle(color: Colors.white, fontSize: 16),
                        ),
                ),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text("Sudah punya akun? "),
                  GestureDetector(
                    onTap: () {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const LoginView(),
                        ),
                      );
                    },
                    child: const Text(
                      "Login",
                      style: TextStyle(
                        color: Colors.blue,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
