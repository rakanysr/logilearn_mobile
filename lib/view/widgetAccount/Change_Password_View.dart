import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:logilearn/services/api_service.dart';
import 'package:logilearn/services/auth_service.dart';

class ChangePasswordView extends StatefulWidget {
  const ChangePasswordView({super.key});

  @override
  State<ChangePasswordView> createState() => _ChangePasswordViewState();
}

class _ChangePasswordViewState extends State<ChangePasswordView> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _currentPwdController = TextEditingController();
  final TextEditingController _newPwdController = TextEditingController();
  final TextEditingController _confirmPwdController = TextEditingController();
  final ApiService _apiService = ApiService();
  final AuthService _authService = AuthService();
  bool _isLoading = false;

  @override
  void dispose() {
    _currentPwdController.dispose();
    _newPwdController.dispose();
    _confirmPwdController.dispose();
    super.dispose();
  }

  Future<void> _changePassword() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    final messenger = ScaffoldMessenger.of(context);
    final nav = Navigator.of(context);
    try {
      final response = await _apiService.changePassword(
        _currentPwdController.text.trim(),
        _newPwdController.text.trim(),
      );
      if (!mounted) return;
      messenger.showSnackBar(
        SnackBar(
          content: Text(response['message'] ?? 'Password changed'),
          backgroundColor: response['status_code'] == 200 ? Colors.green : Colors.red,
        ),
      );
      if (response['status_code'] == 200) {
        await _authService.logout();
        if (mounted) {
          nav.popUntil((route) => route.isFirst);
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Terjadi kesalahan, coba lagi'), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ganti Kata Sandi'),
        backgroundColor: const Color(0xFF2977FF),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _currentPwdController,
                obscureText: true,
                decoration: InputDecoration(
                  labelText: 'Kata sandi lama',
                  labelStyle: GoogleFonts.inter(),
                ),
                validator: (value) => (value == null || value.isEmpty) ? 'Tidak boleh kosong' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _newPwdController,
                obscureText: true,
                decoration: InputDecoration(
                  labelText: 'Kata sandi baru',
                  labelStyle: GoogleFonts.inter(),
                ),
                validator: (value) => (value == null || value.length < 6) ? 'Minimal 6 karakter' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _confirmPwdController,
                obscureText: true,
                decoration: InputDecoration(
                  labelText: 'Konfirmasi kata sandi',
                  labelStyle: GoogleFonts.inter(),
                ),
                validator: (value) => (value != _newPwdController.text) ? 'Tidak cocok dengan kata sandi baru' : null,
              ),
              const SizedBox(height: 24),
              _isLoading
                  ? const CircularProgressIndicator()
                  : ElevatedButton(
                      onPressed: _changePassword,
                      style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF2977FF)),
                      child: const Text('Simpan'),
                    ),
            ],
          ),
        ),
      ),
    );
  }
}
