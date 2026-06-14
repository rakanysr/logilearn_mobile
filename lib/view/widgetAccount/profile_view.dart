import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:logilearn/services/api_service.dart';

class ProfileView extends StatefulWidget {
  final Map<String, dynamic>? userData;
  final int initialTab;

  const ProfileView({super.key, this.userData, this.initialTab = 0});

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

    final int userLevelRank = _statsData?['level_rank'] ?? 1;

    final List<Map<String, dynamic>> allRanks = [
      {
        'level': 1,
        'name': 'Pemula',
        'xp': '0 - 499 XP',
        'minXp': 0,
        'icon': Icons.sentiment_satisfied_alt,
        'color': Colors.grey[600]!,
      },
      {
        'level': 2,
        'name': 'Pelajar',
        'xp': '500 - 1499 XP',
        'minXp': 500,
        'icon': Icons.school,
        'color': Colors.green[600]!,
      },
      {
        'level': 3,
        'name': 'Mahir',
        'xp': '1500 - 2999 XP',
        'minXp': 1500,
        'icon': Icons.auto_awesome,
        'color': Colors.blue[600]!,
      },
      {
        'level': 4,
        'name': 'Ahli',
        'xp': '3000 - 5999 XP',
        'minXp': 3000,
        'icon': Icons.military_tech,
        'color': Colors.purple[600]!,
      },
      {
        'level': 5,
        'name': 'Master',
        'xp': '≥ 6000 XP',
        'minXp': 6000,
        'icon': Icons.emoji_events,
        'color': Colors.amber[700]!,
      },
    ];

    final List<Map<String, dynamic>> allBadges = [
      {
        'type': 'PERFECT_SCORE',
        'name': 'Skor Sempurna',
        'description': 'Raih skor 100 untuk pertama kalinya',
        'requirement': 'Dapatkan skor 100 pada level apa saja.',
        'icon': Icons.stars,
        'color': Colors.amber[700]!,
      },
      {
        'type': 'FIRST_PASS',
        'name': 'Lulus Pertama Kali',
        'description': 'Lulus (skor ≥ 75) di sebuah level untuk pertama kalinya',
        'requirement': 'Selesaikan sebuah level dengan skor minimal 75.',
        'icon': Icons.thumb_up,
        'color': Colors.blue[600]!,
      },
      {
        'type': 'XP_1000',
        'name': 'Pelajar Rajin',
        'description': 'Kumpulkan total XP ≥ 1000',
        'requirement': 'Akumulasikan total XP sebesar 1000 atau lebih.',
        'icon': Icons.local_fire_department,
        'color': Colors.orange[700]!,
      },
      {
        'type': 'XP_5000',
        'name': 'Pejuang XP',
        'description': 'Kumpulkan total XP ≥ 5000',
        'requirement': 'Akumulasikan total XP sebesar 5000 atau lebih.',
        'icon': Icons.emoji_events,
        'color': Colors.red[600]!,
      },
    ];

    return DefaultTabController(
      length: 2,
      initialIndex: widget.initialTab,
      child: Scaffold(
        backgroundColor: const Color(0xFFF8FAFC),
        appBar: AppBar(
          title: Text(
            'Detail Lencana & Rank',
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
          bottom: TabBar(
            labelColor: const Color(0xFF2977FF),
            unselectedLabelColor: Colors.grey,
            indicatorColor: const Color(0xFF2977FF),
            labelStyle: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 14),
            unselectedLabelStyle: GoogleFonts.inter(fontSize: 14),
            tabs: const [
              Tab(text: 'Rank & Tingkatan'),
              Tab(text: 'Lencana'),
            ],
          ),
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
                : TabBarView(
                    physics: const BouncingScrollPhysics(),
                    children: [
                      // Tab 0: Rank List
                      SingleChildScrollView(
                        physics: const BouncingScrollPhysics(),
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildUserInfoCard(nama, username),
                            const SizedBox(height: 25),
                            _buildRanksList(allRanks, userLevelRank),
                          ],
                        ),
                      ),
                      // Tab 1: Badges List
                      SingleChildScrollView(
                        physics: const BouncingScrollPhysics(),
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildUserInfoCard(nama, username),
                            const SizedBox(height: 25),
                            _buildBadgesList(allBadges),
                          ],
                        ),
                      ),
                    ],
                  ),
      ),
    );
  }

  Widget _buildUserInfoCard(String nama, String username) {
    return Container(
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
    );
  }

  Widget _buildRanksList(List<Map<String, dynamic>> allRanks, int userLevelRank) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Daftar Rank & Tingkatan',
          style: GoogleFonts.inter(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 12),
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: allRanks.length,
          separatorBuilder: (context, index) => const SizedBox(height: 10),
          itemBuilder: (context, index) {
            final rank = allRanks[index];
            final bool isUnlocked = userLevelRank >= rank['level'];
            final bool isCurrent = userLevelRank == rank['level'];

            return Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isCurrent 
                      ? const Color(0xFF2977FF).withValues(alpha: 0.5) 
                      : Colors.transparent,
                  width: isCurrent ? 2 : 0,
                ),
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
                      color: isUnlocked
                          ? rank['color'].withValues(alpha: 0.1)
                          : Colors.grey.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      isUnlocked ? rank['icon'] : Icons.lock_outline,
                      color: isUnlocked ? rank['color'] : Colors.grey,
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              rank['name'],
                              style: GoogleFonts.inter(
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                                color: isUnlocked ? Colors.black87 : Colors.grey[600],
                              ),
                            ),
                            if (isCurrent) ...[
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF2977FF).withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  'Aktif',
                                  style: GoogleFonts.inter(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: const Color(0xFF2977FF),
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Syarat: ${rank['xp']}',
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            color: isUnlocked ? Colors.black54 : Colors.grey[500],
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    isUnlocked ? Icons.check_circle : Icons.lock_clock,
                    color: isUnlocked ? Colors.green : Colors.grey[400],
                    size: 20,
                  ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildBadgesList(List<Map<String, dynamic>> allBadges) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Daftar Lencana Pencapaian',
          style: GoogleFonts.inter(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 12),
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: allBadges.length,
          separatorBuilder: (context, index) => const SizedBox(height: 10),
          itemBuilder: (context, index) {
            final badge = allBadges[index];
            final ownedBadgeIndex = _badgesList.indexWhere(
              (b) => b['badge_name'] == badge['name']
            );
            final bool isOwned = ownedBadgeIndex != -1;
            final String obtainedAt = isOwned 
                ? (_badgesList[ownedBadgeIndex]['obtained_at']?.toString() ?? '') 
                : '';

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
                      color: isOwned
                          ? badge['color'].withValues(alpha: 0.1)
                          : Colors.grey.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      isOwned ? badge['icon'] : Icons.lock_outline,
                      color: isOwned ? badge['color'] : Colors.grey,
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          badge['name'],
                          style: GoogleFonts.inter(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                            color: isOwned ? Colors.black87 : Colors.grey[600],
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          isOwned ? badge['description'] : badge['requirement'],
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            color: isOwned ? Colors.black54 : Colors.grey[500],
                          ),
                        ),
                        if (isOwned && obtainedAt.isNotEmpty) ...[
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
                  Icon(
                    isOwned ? Icons.check_circle : Icons.lock_clock,
                    color: isOwned ? Colors.green : Colors.grey[400],
                    size: 20,
                  ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }
}
