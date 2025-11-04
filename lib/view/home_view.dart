import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:logilearn/widget/bottombar.dart';
import 'package:logilearn/view/quiz_view.dart';

class HomeView extends StatefulWidget {
  const HomeView({super.key});

  @override
  State<HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends State<HomeView> {
  bool _isDropdownOpen = false;
  int _selectedSectionIndex = 0;
  int _currentBottomNavIndex = 0;

  final List<Map<String, dynamic>> _sections = [
    {
      'section': 'SECTION 1',
      'title': 'LOGIKA DASAR',
      'color': const Color(0xFF2F80ED),
      'image': 'assets/images/Mascot halo.png',
      'unlockedLevel': 4,
      'levelScores': [100, 85, 90, 0],
    },
    {
      'section': 'SECTION 2',
      'title': 'LOGIKA PEMROGRAMAN',
      'color': const Color(0xFF2D9CDB),
      'image': 'assets/images/Mascot banyak.png',
      'unlockedLevel': 0,
      'levelScores': [],
    },
    {
      'section': 'SECTION 3',
      'title': 'LOGIKA SILOGISME',
      'color': const Color(0xFF27AE60),
      'image': 'assets/images/Mascot buntung.png',
      'unlockedLevel': 0,
      'levelScores': [],
    },
  ];

  void _navigateToLevelDetail(int level) {
    // Navigate to quiz screen for the selected level
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const QuizScreen()),
    );
  }

  void _showLockedPopup() {
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
                  "Level Terkunci",
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                content: Text(
                  "Selesaikan level sebelumnya dulu untuk membuka level ini.",
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(color: Colors.black54),
                ),
                actionsAlignment: MainAxisAlignment.center,
                actions: [
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blueAccent,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    onPressed: () => Navigator.pop(context),
                    child: Text(
                      "Oke",
                      style: GoogleFonts.inter(color: Colors.white),
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

  @override
  Widget build(BuildContext context) {
    final selected = _sections[_selectedSectionIndex];
    final screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Stack(
          children: [
            SingleChildScrollView(
              child: Column(
                children: [
                  Container(
                    width: double.infinity,
                    alignment: Alignment.centerLeft,
                    padding: const EdgeInsets.only(top: 15.0, left: 15.0),
                    child: Text(
                      'Selamat Datang, Jakarta Jawa',
                      style: GoogleFonts.inter(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                  ),

                  // dropdown header
                  Container(
                    width: screenWidth,
                    margin: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () {
                          setState(() => _isDropdownOpen = !_isDropdownOpen);
                        },
                        borderRadius: BorderRadius.circular(18),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            vertical: 18,
                            horizontal: 20,
                          ),
                          decoration: BoxDecoration(
                            color: selected['color'],
                            borderRadius: BorderRadius.circular(18),
                            boxShadow: [
                              BoxShadow(
                                color: selected['color'].withOpacity(0.3),
                                blurRadius: 8,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '${selected['section']}',
                                    style: GoogleFonts.inter(
                                      color: Colors.white,
                                      fontSize: 13,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  Text(
                                    selected['title'],
                                    style: GoogleFonts.inter(
                                      color: Colors.white,
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                              Icon(
                                _isDropdownOpen
                                    ? Icons.keyboard_arrow_up
                                    : Icons.keyboard_arrow_down,
                                color: Colors.white,
                                size: 28,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),
                  Image.asset(selected['image'], height: 120),
                  const SizedBox(height: 12),
                  Text(
                    '${selected['section']}',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      color: Colors.black54,
                    ),
                  ),
                  Text(
                    selected['title'],
                    style: GoogleFonts.inter(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),

                  // grid zigzag
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 20.0),
                    child: Column(
                      children: List.generate(10, (index) {
                        final isUnlocked = index < selected['unlockedLevel'];
                        final scores = selected['levelScores'] as List<dynamic>;
                        final dx = (index % 4 == 0)
                            ? -screenWidth * 0.2
                            : (index % 4 == 1)
                            ? 0.0
                            : (index % 4 == 2)
                            ? screenWidth * 0.2
                            : 0.0;

                        return Padding(
                          padding: const EdgeInsets.only(bottom: 20.0),
                          child: Transform.translate(
                            offset: Offset(dx, 0),
                            child: GestureDetector(
                              onTap: () {
                                if (isUnlocked) {
                                  _navigateToLevelDetail(index + 1);
                                } else {
                                  _showLockedPopup();
                                }
                              },
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Stack(
                                    alignment: Alignment.center,
                                    children: [
                                      Container(
                                        width: 88,
                                        height: 88,
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          color: isUnlocked
                                              ? selected['color']
                                              : Colors.grey[300],
                                          boxShadow: [
                                            BoxShadow(
                                              color:
                                                  (isUnlocked
                                                          ? selected['color']
                                                          : Colors.grey[300])!
                                                      .withOpacity(0.3),
                                              blurRadius: 10,
                                              offset: const Offset(0, 6),
                                            ),
                                          ],
                                        ),
                                        child: Column(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            Text(
                                              '${index + 1}',
                                              style: GoogleFonts.inter(
                                                color: isUnlocked
                                                    ? Colors.white
                                                    : Colors.grey[600],
                                                fontSize: 26,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                            if (isUnlocked &&
                                                index < scores.length)
                                              Text(
                                                '${scores[index]}%',
                                                style: GoogleFonts.inter(
                                                  color: Colors.white,
                                                  fontSize: 14,
                                                  fontWeight: FontWeight.w500,
                                                ),
                                              ),
                                          ],
                                        ),
                                      ),
                                      if (!isUnlocked)
                                        const Positioned(
                                          right: 0,
                                          top: 0,
                                          child: Icon(
                                            Icons.lock,
                                            color: Colors.grey,
                                            size: 26,
                                          ),
                                        ),
                                      if (isUnlocked && index < scores.length)
                                        Positioned(
                                          right: 0,
                                          top: 0,
                                          child: Container(
                                            padding: const EdgeInsets.all(5),
                                            decoration: BoxDecoration(
                                              color: Colors.white,
                                              shape: BoxShape.circle,
                                              boxShadow: [
                                                BoxShadow(
                                                  color: selected['color']
                                                      .withOpacity(0.3),
                                                  blurRadius: 4,
                                                  offset: const Offset(0, 2),
                                                ),
                                              ],
                                            ),
                                            child: Icon(
                                              Icons.check_circle,
                                              color: selected['color'],
                                              size: 22,
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
                      }),
                    ),
                  ),
                ],
              ),
            ),

            // dropdown menu overlay
            if (_isDropdownOpen)
              Positioned(
                top: 55,
                left: 16,
                right: 16,
                child: Material(
                  elevation: 8,
                  color: Colors.transparent,
                  borderRadius: BorderRadius.circular(18),
                  child: Column(
                    children: List.generate(_sections.length, (index) {
                      final s = _sections[index];
                      return Padding(
                        padding: EdgeInsets.only(
                          bottom: index == _sections.length - 1 ? 0 : 8.0,
                        ),
                        child: InkWell(
                          onTap: () {
                            setState(() {
                              _selectedSectionIndex = index;
                              _isDropdownOpen = false;
                            });
                          },
                          borderRadius: BorderRadius.circular(18),
                          child: Container(
                            width: screenWidth - 32,
                            padding: const EdgeInsets.symmetric(
                              vertical: 18,
                              horizontal: 20,
                            ),
                            margin: const EdgeInsets.symmetric(
                              horizontal: 0,
                              vertical: 0,
                            ),
                            decoration: BoxDecoration(
                              color: s['color'],
                              borderRadius: BorderRadius.circular(18),
                              boxShadow: [
                                BoxShadow(
                                  color: s['color'].withOpacity(0.3),
                                  blurRadius: 8,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  s['section'],
                                  style: GoogleFonts.inter(
                                    color: Colors.white,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                Text(
                                  s['title'],
                                  style: GoogleFonts.inter(
                                    color: Colors.white,
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    }),
                  ),
                ),
              ),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavBar(currentIndex: _currentBottomNavIndex),
    );
  }
}
