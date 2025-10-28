import 'package:flutter/material.dart';
import 'package:logilearn/widget/bottombar.dart';
import 'package:logilearn/view/widgetAccount/security_view.dart';
import 'package:google_fonts/google_fonts.dart';

class AccountView extends StatelessWidget {
  const AccountView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,

      body: Column(
        children: [
          Container(
            width: double.infinity,
            height: 180,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color.fromARGB(255, 187, 241, 253), Color(0xFF2977FF)],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
            padding: const EdgeInsets.only(left: 20, right: 20, top: 50),
            alignment: Alignment.centerLeft,
            child: const Text(
              'Akun Saya',
              style: TextStyle(
                fontFamily: 'Inter',
                fontWeight: FontWeight.w600,
                color: Colors.white,
                fontSize: 18,
              ),
            ),
          ),

          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  Transform.translate(
                    offset: const Offset(0, -30),
                    child: Container(
                      height: 160,
                      margin: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 10,
                      ),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 10,
                            offset: const Offset(0, 5),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          const CircleAvatar(
                            radius: 28,
                            backgroundImage: const AssetImage(
                              'assets/images/Mascot buntung.png',
                            ),
                          ),
                          const SizedBox(width: 12),
                          const Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                SizedBox(height: 40),
                                Text(
                                  'Jakarta Jawa',
                                  style: TextStyle(
                                    fontFamily: 'Inter',
                                    fontWeight: FontWeight.w600,
                                    fontSize: 16,
                                  ),
                                ),
                                SizedBox(height: 5),
                                Text(
                                  '@JawaJawa',
                                  style: TextStyle(
                                    fontFamily: 'Inter',
                                    fontSize: 13,
                                    color: Colors.grey,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          ElevatedButton.icon(
                            onPressed: () {},
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white,
                              side: const BorderSide(color: Color(0xFF2977FF)),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              elevation: 0,
                            ),
                            icon: const Icon(
                              Icons.person,
                              color: Color(0xFF2977FF),
                              size: 18,
                            ),
                            label: const Text(
                              'Lihat Profil',
                              style: TextStyle(
                                fontFamily: 'Inter',
                                color: Color(0xFF2977FF),
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 10,
                    ),
                    child: Row(
                      children: [
                        Expanded(child: _buildStatCard('Section Selesai', '0')),
                        const SizedBox(width: 12),
                        Expanded(child: _buildStatCard('Level Selesai', '0')),
                      ],
                    ),
                  ),

                  const SizedBox(height: 10),

                  _buildMenuItem(
                    icon: Icons.lock_outline,
                    text: 'Keamanan',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const SecurityView(),
                        ),
                      );
                    },
                  ),

                  _buildMenuItem(
                    icon: Icons.logout,
                    text: 'Keluar',
                    onTap: () => _showLogoutDialog(context),
                  ),

                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
      ),

      bottomNavigationBar: const BottomNavBar(currentIndex: 2),
    );
  }

  Widget _buildStatCard(String title, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            title,
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 13,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: const TextStyle(
              fontFamily: 'Inter',
              fontWeight: FontWeight.w600,
              fontSize: 15,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuItem({
    required IconData icon,
    required String text,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Ink(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.08),
                blurRadius: 6,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Row(
            children: [
              Icon(icon, color: Colors.grey[700]),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  text,
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              const Icon(Icons.chevron_right),
            ],
          ),
        ),
      ),
    );
  }
}

void _showLogoutDialog(BuildContext context) {
  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (BuildContext context) {
      return AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Center(
          child: Text(
            'Keluar',
            style: GoogleFonts.getFont(
              'Inter',
              fontWeight: FontWeight.w700,
              color: Colors.black,
            ),
          ),
        ),
        content: Text(
          'Apakah anda yakin untuk keluar dari akun anda?',
          textAlign: TextAlign.center,
          style: GoogleFonts.getFont(
            'Inter',
            fontSize: 14,
            color: Colors.black87,
          ),
        ),
        actionsAlignment: MainAxisAlignment.center,
        actions: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFFA8A8),
                  minimumSize: const Size(100, 40),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                onPressed: () {
                  Navigator.pop(context);
                },
                child: Text(
                  'TIDAK',
                  style: GoogleFonts.getFont(
                    'Inter',
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2977FF),
                  minimumSize: const Size(100, 40),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                onPressed: () {
                  Navigator.pop(context);
                  // Tambahkan logout di sini
                },
                child: Text(
                  'YA',
                  style: GoogleFonts.getFont(
                    'Inter',
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ],
      );
    },
  );
}
