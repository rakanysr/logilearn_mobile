import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:logilearn/services/api_service.dart';

class LeaderboardView extends StatefulWidget {
  const LeaderboardView({super.key});

  @override
  State<LeaderboardView> createState() => _LeaderboardViewState();
}

class _LeaderboardViewState extends State<LeaderboardView> {
  final ApiService _apiService = ApiService();
  bool _isLoading = true;
  String? _error;
  List<dynamic> _leaderboardList = [];

  // Paginasi
  final int _currentPage = 1;
  final int _limit = 50; // Kita ambil top 50 sekaligus agar simpel dan lengkap

  @override
  void initState() {
    super.initState();
    _fetchLeaderboard();
  }

  Future<void> _fetchLeaderboard() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final response = await _apiService.getGlobalLeaderboard(page: _currentPage, limit: _limit);
      debugPrint('=== LEADERBOARD RAW RESPONSE ===');
      debugPrint('success: ${response['success']}');
      debugPrint('data keys: ${response['data']?.keys?.toList()}');
      if (response['success'] == true) {
        final datas = response['data']?['payload']?['datas'];
        debugPrint('datas length: ${datas?.length}');
        if (datas != null && datas is List && datas.isNotEmpty) {
          debugPrint('first item: ${datas[0]}');
          debugPrint('first item total_xp: ${datas[0]['total_xp']}');
        }
      }

      if (response['success']) {
        setState(() {
          _leaderboardList = response['data']['payload']['datas'] as List<dynamic>? ?? [];
          _isLoading = false;
        });
      } else {
        setState(() {
          _error = response['message'] ?? "Gagal memuat papan peringkat";
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = "Terjadi kesalahan koneksi: ${e.toString()}";
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

  @override
  Widget build(BuildContext context) {
    // Pisahkan Top 3 dan sisa peringkat
    final List<dynamic> topThree = _leaderboardList.take(3).toList();
    final List<dynamic> restOfList = _leaderboardList.skip(3).toList();

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Text(
          'Leaderboard',
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
      body: RefreshIndicator(
        onRefresh: _fetchLeaderboard,
        color: const Color(0xFF2977FF),
        child: _isLoading
            ? const Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF2977FF)),
                ),
              )
            : _error != null
                ? SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    child: Container(
                      height: MediaQuery.of(context).size.height - 150,
                      alignment: Alignment.center,
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
                            onPressed: _fetchLeaderboard,
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
                : _leaderboardList.isEmpty
                    ? const Center(
                        child: Text(
                          "Belum ada data peringkat.",
                          style: TextStyle(fontSize: 16, color: Colors.black54),
                        ),
                      )
                    : Column(
                        children: [
                          // Podiums for Top 3 (if exists)
                          if (topThree.isNotEmpty) ...[
                            _buildPodiumSection(topThree),
                            const SizedBox(height: 10),
                          ],

                          // The rest of the leaderboard
                          Expanded(
                            child: ListView.separated(
                              physics: const BouncingScrollPhysics(),
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                              itemCount: restOfList.length,
                              separatorBuilder: (context, index) => const SizedBox(height: 10),
                              itemBuilder: (context, index) {
                                final item = restOfList[index];
                                final int rank = item['rank'] ?? (index + 4);
                                final String name = item['nama'] ?? 'Pelajar';
                                final int xp = item['total_xp'] ?? item['xp'] ?? 0;
                                final int levelRank = item['level_rank'] ?? 1;

                                return Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(14),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withValues(alpha: 0.02),
                                        blurRadius: 5,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: Row(
                                    children: [
                                      // Rank Number
                                      Container(
                                        width: 32,
                                        alignment: Alignment.center,
                                        child: Text(
                                          rank.toString(),
                                          style: GoogleFonts.inter(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 15,
                                            color: Colors.grey[600],
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      
                                      // Mascot Icon
                                      const CircleAvatar(
                                        radius: 18,
                                        backgroundImage: AssetImage('assets/images/Mascot buntung.png'),
                                      ),
                                      const SizedBox(width: 16),
                                      
                                      // Name & Rank Subtitle
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              name,
                                              style: GoogleFonts.inter(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 15,
                                                color: Colors.black87,
                                              ),
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                            Text(
                                              _getRankName(levelRank),
                                              style: GoogleFonts.inter(
                                                fontSize: 12,
                                                color: Colors.grey[500],
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      
                                      // XP Gained
                                      Text(
                                        "$xp XP",
                                        style: GoogleFonts.inter(
                                          fontWeight: FontWeight.w800,
                                          color: const Color(0xFF2977FF),
                                          fontSize: 14,
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                          ),
                        ],
                      ),
      ),
    );
  }

  Widget _buildPodiumSection(List<dynamic> topThree) {
    // Reorder so that Rank 2 is Left, Rank 1 is Center, Rank 3 is Right
    final dynamic first = topThree[0];
    final dynamic second = topThree.length > 1 ? topThree[1] : null;
    final dynamic third = topThree.length > 2 ? topThree[2] : null;

    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(24),
          bottomRight: Radius.circular(24),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.only(top: 20, bottom: 24, left: 16, right: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // Second Place (Left)
          if (second != null)
            Expanded(child: _buildPodiumUser(second, 2, 75))
          else
            const Expanded(child: SizedBox()),

          // First Place (Center)
          Expanded(child: _buildPodiumUser(first, 1, 95)),

          // Third Place (Right)
          if (third != null)
            Expanded(child: _buildPodiumUser(third, 3, 68))
          else
            const Expanded(child: SizedBox()),
        ],
      ),
    );
  }

  Widget _buildPodiumUser(dynamic user, int position, double heightScale) {
    final String name = user['nama'] ?? 'Pelajar';
    final int xp = user['total_xp'] ?? user['xp'] ?? 0;
    
    Color color;
    IconData medalIcon;
    double avatarRadius;
    if (position == 1) {
      color = Colors.amber;
      medalIcon = Icons.emoji_events;
      avatarRadius = 38.0;
    } else if (position == 2) {
      color = Colors.grey[400]!;
      medalIcon = Icons.workspace_premium;
      avatarRadius = 30.0;
    } else {
      color = Colors.orange[300]!;
      medalIcon = Icons.military_tech;
      avatarRadius = 30.0;
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Trophy/Medal Icon
        Icon(medalIcon, color: color, size: position == 1 ? 30 : 24),
        const SizedBox(height: 4),

        // Avatar Image
        Stack(
          alignment: Alignment.center,
          children: [
            CircleAvatar(
              radius: avatarRadius + 3,
              backgroundColor: color,
              child: CircleAvatar(
                radius: avatarRadius,
                backgroundImage: const AssetImage('assets/images/Mascot buntung.png'),
              ),
            ),
            Positioned(
              bottom: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 1.5),
                ),
                child: Text(
                  position.toString(),
                  style: GoogleFonts.inter(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 10,
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),

        // Name
        Text(
          name,
          style: GoogleFonts.inter(
            fontWeight: FontWeight.bold,
            fontSize: position == 1 ? 15 : 13,
            color: Colors.black87,
          ),
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 4),

        // XP
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            "$xp XP",
            style: GoogleFonts.inter(
              fontWeight: FontWeight.bold,
              fontSize: position == 1 ? 12 : 11,
              color: position == 1 ? Colors.amber[800] : Colors.black87,
            ),
          ),
        ),
      ],
    );
  }
}
