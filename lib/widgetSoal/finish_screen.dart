import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../view/quiz_view.dart';

class FinishScreen extends StatefulWidget {
  final int score;
  final int totalQuestions;
  final String? sectionSlug;
  final int? levelId;
  final String? sectionTitle;
  final int? sectionNumber;
  final int? levelNumber;
  final double? finalPercentage;
  final int? xpGained;
  final int? totalXp;
  final bool levelRankUp;
  final int? newLevelRank;
  final List<dynamic> newBadges;

  const FinishScreen({
    super.key,
    required this.score,
    required this.totalQuestions,
    this.sectionSlug,
    this.levelId,
    this.sectionTitle,
    this.sectionNumber,
    this.levelNumber,
    this.finalPercentage,
    this.xpGained,
    this.totalXp,
    this.levelRankUp = false,
    this.newLevelRank,
    this.newBadges = const [],
  });

  @override
  State<FinishScreen> createState() => _FinishScreenState();
}

class _FinishScreenState extends State<FinishScreen> {
  @override
  void initState() {
    super.initState();
    // Tampilkan notifikasi gamifikasi (level up dan badge) berurutan setelah render pertama selesai
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (widget.levelRankUp) {
        if (!mounted) return; await _showLevelUpDialog(context, widget.newLevelRank ?? 1);
      }
      if (widget.newBadges.isNotEmpty) {
        for (var badge in widget.newBadges) {
          if (badge is Map) {
            if (!mounted) return; await _showBadgeDialog(
              context,
              badge['name']?.toString() ?? '',
              badge['description']?.toString() ?? '',
            );
          }
        }
      }
    });
  }

  Future<void> _showLevelUpDialog(BuildContext context, int newRank) {
    return showDialog(
      context: context,
      barrierDismissible: true,
      builder: (_) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Column(
          children: [
            Image.asset('assets/images/Mascot halo.png', height: 100),
            const SizedBox(height: 15),
            Text(
              "Naik Peringkat!",
              style: GoogleFonts.inter(
                fontWeight: FontWeight.bold,
                color: const Color(0xFF2977FF),
                fontSize: 24,
              ),
            ),
          ],
        ),
        content: Text(
          "Selamat! Peringkat level kamu sekarang naik ke Rank $newRank!",
          textAlign: TextAlign.center,
          style: GoogleFonts.inter(fontSize: 16, color: Colors.black87),
        ),
        actionsAlignment: MainAxisAlignment.center,
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2977FF),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
            onPressed: () => Navigator.pop(context),
            child: Text(
              "Hebat!",
              style: GoogleFonts.inter(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          )
        ],
      ),
    );
  }

  Future<void> _showBadgeDialog(
    BuildContext context,
    String name,
    String description,
  ) {
    return showDialog(
      context: context,
      barrierDismissible: true,
      builder: (_) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Column(
          children: [
            const Icon(Icons.stars, color: Colors.amber, size: 80),
            const SizedBox(height: 15),
            Text(
              "Lencana Baru!",
              style: GoogleFonts.inter(
                fontWeight: FontWeight.bold,
                color: Colors.amber[800],
                fontSize: 22,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              name,
              style: GoogleFonts.inter(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              description,
              style: GoogleFonts.inter(fontSize: 14, color: Colors.black54),
              textAlign: TextAlign.center,
            ),
          ],
        ),
        actionsAlignment: MainAxisAlignment.center,
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.amber,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
            onPressed: () => Navigator.pop(context),
            child: Text(
              "Klaim Lencana",
              style: GoogleFonts.inter(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    double percentage =
        widget.finalPercentage ?? (widget.score / widget.totalQuestions) * 100;
    String imagePath;
    String title;
    String message;
    Color statusColor;

    if (percentage == 100) {
      imagePath = 'assets/images/jempol.png';
      title = "Luar Biasa!";
      message =
          "Kamu menjawab semua soal dengan benar. Pertahankan prestasimu!";
      statusColor = Colors.green;
    } else if (percentage >= 60) {
      imagePath = 'assets/images/Mascot halo.png';
      title = "Kerja Bagus!";
      message =
          "Kamu sudah menguasai sebagian besar materi. Sedikit lagi sempurna!";
      statusColor = Colors.blueAccent;
    } else {
      imagePath = 'assets/images/Mascot banyak.png';
      title = "Jangan Menyerah!";
      message =
          "Belajar adalah proses. Yuk pelajari lagi materinya dan coba lagi.";
      statusColor = Colors.orange;
    }

    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset(imagePath, height: 180),
              const SizedBox(height: 25),
              Text(
                title,
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                  color: statusColor,
                ),
              ),
              const SizedBox(height: 10),

              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      widget.finalPercentage != null
                          ? "Skor: ${widget.finalPercentage!.toStringAsFixed(1)}%"
                          : "Skor: ${widget.score} / ${widget.totalQuestions}",
                      style: GoogleFonts.inter(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: statusColor,
                      ),
                    ),
                  ),
                  if (widget.xpGained != null && widget.xpGained! > 0) ...[
                    const SizedBox(width: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.amber.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: Colors.amber.withValues(alpha: 0.3),
                          width: 1.5,
                        ),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.bolt,
                            color: Colors.amber,
                            size: 20,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            "+${widget.xpGained} XP",
                            style: GoogleFonts.inter(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.amber[800],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 15),

              Text(
                message,
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  fontSize: 16,
                  color: Colors.grey[600],
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 40),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    if (widget.sectionSlug != null &&
                        widget.levelId != null &&
                        widget.sectionTitle != null &&
                        widget.sectionNumber != null &&
                        widget.levelNumber != null) {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                          builder: (_) => QuizScreen(
                            sectionSlug: widget.sectionSlug!,
                            levelId: widget.levelId!,
                            sectionTitle: widget.sectionTitle!,
                            sectionNumber: widget.sectionNumber!,
                            levelNumber: widget.levelNumber!,
                          ),
                        ),
                      );
                    } else {
                      Navigator.pop(context);
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    backgroundColor: const Color(0xFF2977FF),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 3,
                  ),
                  child: Text(
                    "COBA LAGI",
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 15),
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                child: Text(
                  "Kembali ke Beranda",
                  style: GoogleFonts.inter(
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
