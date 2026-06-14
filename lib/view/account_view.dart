import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:logilearn/services/api_service.dart';
import 'package:logilearn/services/auth_service.dart';
import 'package:logilearn/view/widgetAccount/change_password_view.dart';
import 'package:logilearn/view/widgetAccount/profile_view.dart';
import 'package:logilearn/view/login_view.dart';
import 'package:logilearn/widget/bottombar.dart';

class AccountView extends StatefulWidget {
  const AccountView({super.key});

  @override
  State<AccountView> createState() => _AccountViewState();
}

class _AccountViewState extends State<AccountView> {
  final ApiService _apiService = ApiService();
  final AuthService _authService = AuthService();

  Map<String, dynamic>? profileData;
  Map<String, dynamic>? _statsData;
  List<dynamic> _badgesList = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchProfileData();
  }

  Future<void> _fetchProfileData() async {
    try {
      final response = await _apiService.getProfile();

      if (response['status_code'] == 200) {
        final data = response['data']['payload']['datas'];
        setState(() {
          profileData = data;
        });

        final String? rawId = data?['id']?.toString();
        final int? pelajarId = rawId != null ? int.tryParse(rawId) : null;

        if (pelajarId != null) {
          final futures = await Future.wait([
            _apiService.getStats(pelajarId),
            _apiService.getBadges(pelajarId),
          ]);

          final statsRes = futures[0];
          final badgesRes = futures[1];

          if (statsRes['success'] && badgesRes['success']) {
            setState(() {
              _statsData = statsRes['data']['payload']['datas'];
              _badgesList = badgesRes['data']['payload']['datas'] as List<dynamic>? ?? [];
              isLoading = false;
            });
            return;
          }
        }
        setState(() => isLoading = false);
      } else {
        setState(() => isLoading = false);
        String errorMsg = response['data']?['message'] ?? "Gagal memuat profil";
        _showSnackBar(errorMsg, Colors.red);
      }
    } catch (e) {
      setState(() => isLoading = false);
      _showSnackBar("Terjadi kesalahan koneksi", Colors.red);
    }
  }

  void _showSnackBar(String message, Color color) {
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message), backgroundColor: color));
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(color: Color(0xFF2977FF)),
        ),
      );
    }

    final stats =
        profileData?['statistik'] ?? {'section_selesai': 0, 'level_selesai': 0};

    return Scaffold(
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header & Profile Card Stack
            SizedBox(
              height: 220,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Container(
                    width: double.infinity,
                    height: 180,
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Color(0xFFBBF1FD), Color(0xFF2977FF)],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                    padding: const EdgeInsets.only(left: 20, right: 20, top: 50),
                    alignment: Alignment.topLeft,
                    child: Text(
                      'Akun Saya',
                      style: GoogleFonts.inter(
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        fontSize: 20,
                      ),
                    ),
                  ),
                  Positioned(
                    top: 130,
                    left: 20,
                    right: 20,
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.12),
                            blurRadius: 15,
                            offset: const Offset(0, 5),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          const CircleAvatar(
                            radius: 30,
                            backgroundImage: AssetImage(
                              'assets/images/Mascot buntung.png',
                            ),
                          ),
                          const SizedBox(width: 15),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  profileData?['nama'] ?? "Nama Pelajar",
                                  style: GoogleFonts.inter(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  profileData?['username'] != null
                                      ? "@${profileData!['username']}"
                                      : "@username",
                                  style: GoogleFonts.inter(
                                    fontSize: 13,
                                    color: Colors.grey[600],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),

            // Statistik Belajar Section
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Statistik Belajar',
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  InkWell(
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ProfileView(userData: profileData, initialTab: 0),
                      ),
                    ),
                    borderRadius: BorderRadius.circular(20),
                    child: const Padding(
                      padding: EdgeInsets.all(8.0),
                      child: Icon(Icons.arrow_forward_ios, size: 16, color: Color(0xFF2977FF)),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 4),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: GridView.count(
                padding: EdgeInsets.zero,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 2,
                childAspectRatio: 1.4,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                children: [
                  _buildStatItem(
                    icon: Icons.bolt,
                    iconColor: Colors.amber,
                    title: "Total XP",
                    value: "${_statsData?['total_xp'] ?? 0} XP",
                  ),
                  _buildStatItem(
                    icon: Icons.military_tech,
                    iconColor: Colors.blueAccent,
                    title: "Rank Level",
                    value: "Rank ${_statsData?['level_rank'] ?? 1}",
                    subtitle: _getRankName(_statsData?['level_rank'] ?? 1),
                  ),
                  _buildStatItem(
                    icon: Icons.stars,
                    iconColor: Colors.purple,
                    title: "Lencana",
                    value: "${_statsData?['total_badges'] ?? 0} Dimiliki",
                  ),
                  _buildStatItem(
                    icon: Icons.emoji_events,
                    iconColor: Colors.orange,
                    title: "Global Rank",
                    value: "#${_statsData?['global_rank'] ?? '-'}",
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),

            // Lencana Pencapaian Section
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Lencana Pencapaian (${_badgesList.length})',
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  InkWell(
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ProfileView(userData: profileData, initialTab: 1),
                      ),
                    ),
                    borderRadius: BorderRadius.circular(20),
                    child: const Padding(
                      padding: EdgeInsets.all(8.0),
                      child: Icon(Icons.arrow_forward_ios, size: 16, color: Color(0xFF2977FF)),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 4),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: _badgesList.isEmpty
                  ? Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 40),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.grey[200]!),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.stars_outlined, size: 48, color: Colors.grey[400]),
                          const SizedBox(height: 12),
                          Text(
                            'Belum ada lencana yang didapatkan',
                            style: GoogleFonts.inter(
                              color: Colors.grey[500],
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    )
                  : ListView.separated(
                      padding: EdgeInsets.zero,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _badgesList.length,
                      separatorBuilder: (context, index) => const SizedBox(height: 10),
                      itemBuilder: (context, index) {
                        final badge = _badgesList[index];
                        final badgeName = badge['badge_name']?.toString() ?? 'Lencana';
                        final badgeDesc = badge['badge_description']?.toString() ?? '-';
                        final obtainedAt = badge['obtained_at']?.toString() ?? '';

                        return Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.12),
                                blurRadius: 16,
                                offset: const Offset(0, 6),
                              )
                            ],
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: Colors.amber.withValues(alpha: 0.1),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.stars,
                                  color: Colors.amber,
                                  size: 28,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      badgeName,
                                      style: GoogleFonts.inter(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 15,
                                        color: Colors.black87,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      badgeDesc,
                                      style: GoogleFonts.inter(
                                        fontSize: 13,
                                        color: Colors.black54,
                                      ),
                                    ),
                                    if (obtainedAt.isNotEmpty) ...[
                                      const SizedBox(height: 6),
                                      Text(
                                        "Didapatkan pada: ${_formatIsoDate(obtainedAt)}",
                                        style: GoogleFonts.inter(
                                          fontSize: 11,
                                          color: Colors.grey[500],
                                          fontStyle: FontStyle.italic,
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
            ),
            const SizedBox(height: 10),

            // Progress Section (Section & Level Selesai)
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 4),
              child: Text(
                'Kemajuan Belajar',
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
            ),
            const SizedBox(height: 4),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.12),
                            blurRadius: 16,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          Text(
                            'Section Selesai',
                            style: GoogleFonts.inter(fontSize: 12, color: Colors.grey[600]),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            stats['section_selesai']?.toString() ?? "0",
                            style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 18),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.12),
                            blurRadius: 16,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          Text(
                            'Level Selesai',
                            style: GoogleFonts.inter(fontSize: 12, color: Colors.grey[600]),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            stats['level_selesai']?.toString() ?? "0",
                            style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 18),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 25),

            // Menu Items
            _buildMenuItem(
              icon: Icons.lock_outline,
              text: 'Ganti Kata Sandi',
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const ChangePasswordView(),
                ),
              ),
            ),
            _buildMenuItem(
              icon: Icons.logout,
              text: 'Keluar',
              onTap: () => _showLogoutDialog(context),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
      bottomNavigationBar: const BottomNavBar(currentIndex: 3),
    );
  }

  String _getRankName(int rank) {
    switch (rank) {
      case 1:
        return "Pemula";
      case 2:
        return "Pelajar";
      case 3:
        return "Mahir";
      case 4:
        return "Ahli";
      case 5:
        return "Master";
      default:
        return "Pemula";
    }
  }

  String _formatIsoDate(String isoString) {
    try {
      final dt = DateTime.parse(isoString).toLocal();
      final months = [
        'Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni',
        'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember'
      ];
      return '${dt.day} ${months[dt.month - 1]} ${dt.year}';
    } catch (e) {
      return isoString.split('T').first;
    }
  }

  Widget _buildStatItem({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String value,
    String? subtitle,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.12),
            blurRadius: 16,
            offset: const Offset(0, 6),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            children: [
              Icon(icon, color: iconColor, size: 22),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                value,
                style: GoogleFonts.inter(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              if (subtitle != null) ...[
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    "($subtitle)",
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: Colors.grey[500],
                      fontWeight: FontWeight.w500,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ],
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
    return ListTile(
      onTap: onTap,
      leading: Icon(icon, color: Colors.grey[700]),
      title: Text(
        text,
        style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w500),
      ),
      trailing: const Icon(Icons.chevron_right, color: Colors.grey),
    );
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (_) => Center(
        child: TweenAnimationBuilder<double>(
          tween: Tween(begin: 0.8, end: 1.0),
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOutBack,
          builder: (context, scale, child) {
            return Transform.scale(
              scale: scale,
              child: AlertDialog(
                backgroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                title: Text(
                  "Keluar Akun",
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                content: Text(
                  "Apakah Anda yakin ingin keluar dari akun LogiLearn Anda?",
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(color: Colors.black54),
                ),
                actionsAlignment: MainAxisAlignment.center,
                actions: [
                  OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Colors.grey),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    ),
                    onPressed: () => Navigator.pop(context),
                    child: Text(
                      "Batal",
                      style: GoogleFonts.inter(color: Colors.grey[700], fontWeight: FontWeight.w600),
                    ),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.redAccent,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                      elevation: 0,
                    ),
                    onPressed: () async {
                      await _authService.logout();
                      if (!context.mounted) return;
                      Navigator.pushAndRemoveUntil(
                        context,
                        MaterialPageRoute(builder: (_) => const LoginView()),
                        (route) => false,
                      );
                    },
                    child: Text(
                      "Keluar",
                      style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
