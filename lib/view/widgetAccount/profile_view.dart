import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:logilearn/services/api_service.dart';

class ProfileView extends StatefulWidget {
  final Map<String, dynamic>? userData;

  const ProfileView({super.key, this.userData});

  @override
  State<ProfileView> createState() => _ProfileViewState();
}

class _ProfileViewState extends State<ProfileView> {
  final ApiService _apiService = ApiService();
  bool _isLoading = true;
  String? _error;
  
  Map<String, dynamic>? _statsData;
  List<dynamic> _badgesList = [];

  @override
  void initState() {
    super.initState();
    _loadProfileData();
  }

  Future<void> _loadProfileData() async {
    final String? rawId = widget.userData?['id']?.toString();
    final int? pelajarId = rawId != null ? int.tryParse(rawId) : null;

    if (pelajarId == null) {
      setState(() {
        _isLoading = false;
        _error = "ID Pelajar tidak valid";
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
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
          _isLoading = false;
        });
      } else {
        setState(() {
          _error = statsRes['message'] ?? badgesRes['message'] ?? "Gagal memuat statistik";
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = "Koneksi gagal: ${e.toString()}";
        _isLoading = false;
      });
    }
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

  @override
  Widget build(BuildContext context) {
    final String nama = widget.userData?['nama'] ?? '-';
    final String username = widget.userData?['username'] ?? '-';

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Text(
          'Detail Profil',
          style: GoogleFonts.inter(
            color: Colors.black87,
            fontWeight: FontWeight.w700,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.black87),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF2977FF)),
              ),
            )
          : _error != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.error_outline, size: 60, color: Colors.redAccent),
                        const SizedBox(height: 16),
                        Text(
                          _error!,
                          textAlign: TextAlign.center,
                          style: GoogleFonts.inter(fontSize: 16, color: Colors.black54),
                        ),
                        const SizedBox(height: 24),
                        ElevatedButton(
                          onPressed: _loadProfileData,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF2977FF),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                          child: const Text('Coba Lagi', style: TextStyle(color: Colors.white)),
                        ),
                      ],
                    ),
                  ),
                )
              : SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // User Basic Info Card
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.04),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            )
                          ],
                        ),
                        child: Column(
                          children: [
                            const CircleAvatar(
                              radius: 40,
                              backgroundImage: AssetImage('assets/images/Mascot buntung.png'),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              nama,
                              style: GoogleFonts.inter(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              "@$username",
                              style: GoogleFonts.inter(
                                fontSize: 14,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Stats Section
                      Text(
                        'Statistik Belajar',
                        style: GoogleFonts.inter(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 12),
                      GridView.count(
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
                      const SizedBox(height: 25),

                      // Badges List Section
                      Text(
                        'Lencana Pencapaian (${_badgesList.length})',
                        style: GoogleFonts.inter(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 12),
                      _badgesList.isEmpty
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
                                        color: Colors.black.withValues(alpha: 0.02),
                                        blurRadius: 8,
                                        offset: const Offset(0, 2),
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
                    ],
                  ),
                ),
    );
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
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
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
}
