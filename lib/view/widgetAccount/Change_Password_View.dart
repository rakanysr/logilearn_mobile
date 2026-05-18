import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:logilearn/services/api_service.dart';

class ChangePasswordView extends StatefulWidget {
  const ChangePasswordView({super.key});

  @override
  State<ChangePasswordView> createState() => _ChangePasswordViewState();
}

class _ChangePasswordViewState extends State<ChangePasswordView> {
  final _oldPwController = TextEditingController();
  final _newPwController = TextEditingController();
  final _apiService = ApiService();

  bool _isLoading = false;
  bool _obscureOld = true;
  bool _obscureNew = true;

  String? _validateNewPassword(String password) {
    if (password.isEmpty) {
      return 'Password baru tidak boleh kosong.';
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

  void _handleUpdate() async {
    final oldPw = _oldPwController.text.trim();
    final newPw = _newPwController.text.trim();

    if (oldPw.isEmpty || newPw.isEmpty) {
      _showMsg("Harap isi semua kolom!", Colors.red);
      return;
    }

    String? passwordError = _validateNewPassword(newPw);
    if (passwordError != null) {
      _showMsg(passwordError, Colors.red);
      return;
    }

    if (oldPw == newPw) {
      _showMsg("Sandi baru tidak boleh sama dengan sandi lama.", Colors.red);
      return;
    }

    setState(() => _isLoading = true);

    final response = await _apiService.changePassword(oldPw, newPw);

    if (!mounted) return;
    setState(() => _isLoading = false);

    String message =
        response['payload']?['message'] ?? response['message'] ?? "";
    bool isSuccess =
        response['status_code'] == 200 ||
        response['status'] == 200 ||
        message.toLowerCase().contains("berhasil");

    if (isSuccess) {
      final messenger = ScaffoldMessenger.of(context);
      Navigator.of(context).pop();

      messenger.showSnackBar(
        SnackBar(
          content: Text(
            "Sandi berhasil diperbarui!",
            style: GoogleFonts.inter(),
          ),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          margin: const EdgeInsets.all(20),
        ),
      );
    } else {
      _showMsg(
        message.isEmpty ? "Gagal mengubah sandi" : message,
        Colors.redAccent,
      );
    }
  }

  void _showMsg(String msg, Color color) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg, style: GoogleFonts.inter()),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(20),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new,
            color: Colors.black,
            size: 20,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          "Keamanan",
          style: GoogleFonts.inter(
            color: Colors.black,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 20),
            Text(
              "Ganti Kata Sandi",
              style: GoogleFonts.inter(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF1E1E1E),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              "Sandi baru harus minimal 8 karakter, mengandung huruf kapital dan angka.",
              style: GoogleFonts.inter(fontSize: 14, color: Colors.grey[600]),
            ),
            const SizedBox(height: 40),
            _buildInputLabel("Kata Sandi Lama"),
            _buildPasswordField(
              controller: _oldPwController,
              hint: "Masukkan sandi lama",
              isObscured: _obscureOld,
              onToggle: () => setState(() => _obscureOld = !_obscureOld),
            ),
            const SizedBox(height: 24),
            _buildInputLabel("Kata Sandi Baru"),
            _buildPasswordField(
              controller: _newPwController,
              hint: "Masukkan sandi baru",
              isObscured: _obscureNew,
              onToggle: () => setState(() => _obscureNew = !_obscureNew),
            ),
            const SizedBox(height: 48),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _handleUpdate,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2977FF),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 0,
                ),
                child: _isLoading
                    ? const SizedBox(
                        height: 24,
                        width: 24,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 3,
                        ),
                      )
                    : Text(
                        "SIMPAN PERUBAHAN",
                        style: GoogleFonts.inter(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInputLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, left: 4),
      child: Text(
        label,
        style: GoogleFonts.inter(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: Colors.black87,
        ),
      ),
    );
  }

  Widget _buildPasswordField({
    required TextEditingController controller,
    required String hint,
    required bool isObscured,
    required VoidCallback onToggle,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF5F7FA),
        borderRadius: BorderRadius.circular(16),
      ),
      child: TextField(
        controller: controller,
        obscureText: isObscured,
        style: GoogleFonts.inter(),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: GoogleFonts.inter(color: Colors.grey[400], fontSize: 14),
          prefixIcon: const Icon(Icons.lock_outline_rounded, size: 22),
          suffixIcon: IconButton(
            icon: Icon(
              isObscured
                  ? Icons.visibility_off_outlined
                  : Icons.visibility_outlined,
              size: 20,
            ),
            onPressed: onToggle,
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 16,
          ),
        ),
      ),
    );
  }
}
