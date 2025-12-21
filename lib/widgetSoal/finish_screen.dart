import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../view/quiz_view.dart';

class FinishScreen extends StatelessWidget {
  final int score;
  final int totalQuestions;
  final String? sectionSlug;
  final int? levelId;
  final String? sectionTitle;
  final int? sectionNumber;
  final int? levelNumber;

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
  });

  final double? finalPercentage;

  @override
  Widget build(BuildContext context) {
    double percentage = finalPercentage ?? (score / totalQuestions) * 100;
    String imagePath;
    String title;
    String message;
    Color statusColor;

    if (percentage == 100) {
      // Nilai Sempurna
      imagePath = 'assets/images/jempol.png';
      title = "Luar Biasa!";
      message =
          "Kamu menjawab semua soal dengan benar. Pertahankan prestasimu!";
      statusColor = Colors.green;
    } else if (percentage >= 60) {
      // Nilai Bagus
      imagePath = 'assets/images/Mascot halo.png';
      title = "Kerja Bagus!";
      message =
          "Kamu sudah menguasai sebagian besar materi. Sedikit lagi sempurna!";
      statusColor = Colors.blueAccent;
    } else {
      // Nilai Kurang
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
              const SizedBox(height: 30),
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
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  finalPercentage != null
                      ? "Skor: ${finalPercentage!.toStringAsFixed(1)}%"
                      : "Skor: $score / $totalQuestions",
                  style: GoogleFonts.inter(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: statusColor,
                  ),
                ),
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

              const SizedBox(height: 50),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    // If we have quiz parameters, restart the quiz
                    if (sectionSlug != null &&
                        levelId != null &&
                        sectionTitle != null &&
                        sectionNumber != null &&
                        levelNumber != null) {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                          builder: (_) => QuizScreen(
                            sectionSlug: sectionSlug!,
                            levelId: levelId!,
                            sectionTitle: sectionTitle!,
                            sectionNumber: sectionNumber!,
                            levelNumber: levelNumber!,
                          ),
                        ),
                      );
                    } else {
                      // Otherwise, go back to previous screen
                      Navigator.pop(context);
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    backgroundColor: const Color(0xFF2977FF), // Warna brand
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 5,
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
