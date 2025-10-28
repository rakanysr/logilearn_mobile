import 'package:flutter/material.dart';
import 'package:logilearn/widget/bottombar.dart';

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
      'unlockedLevel': 3,
    },
    {
      'section': 'SECTION 2',
      'title': 'LOGIKA PEMROGRAMAN',
      'color': const Color(0xFF2D9CDB),
      'image': 'assets/images/Mascot banyak.png',
      'unlockedLevel': 1,
    },
    {
      'section': 'SECTION 3',
      'title': 'LOGIKA SILOGISME',
      'color': const Color(0xFF27AE60),
      'image': 'assets/images/Mascot buntung.png',
      'unlockedLevel': 0,
    },
  ];

  void _showLockedPopup() {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (_) {
        return Center(
          child: TweenAnimationBuilder<double>(
            tween: Tween(begin: 0.8, end: 1.0),
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeOutBack,
            builder: (context, scale, child) {
              return Transform.scale(
                scale: scale,
                child: AlertDialog(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  title: const Text(
                    "Level Terkunci 🔒",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  content: const Text(
                    "Selesaikan level sebelumnya dulu untuk membuka level ini.",
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.black54),
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
                      child: const Text("Oke"),
                    ),
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }

  void _navigateToLevelDetail(int level) {
    // Navigasi ke halaman detail level
  }

  @override
  Widget build(BuildContext context) {
    final selected = _sections[_selectedSectionIndex];
    final screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              GestureDetector(
                onTap: () {
                  setState(() => _isDropdownOpen = !_isDropdownOpen);
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  width: screenWidth,
                  margin: const EdgeInsets.only(top: 12, bottom: 8),
                  padding: const EdgeInsets.symmetric(
                    vertical: 18,
                    horizontal: 20,
                  ),
                  decoration: BoxDecoration(
                    color: selected['color'],
                    borderRadius: const BorderRadius.only(
                      bottomLeft: Radius.circular(18),
                      bottomRight: Radius.circular(18),
                    ),
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
                            '${selected['section']}, LEVEL 1',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          Text(
                            selected['title'],
                            style: const TextStyle(
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

              AnimatedCrossFade(
                duration: const Duration(milliseconds: 350),
                crossFadeState: _isDropdownOpen
                    ? CrossFadeState.showFirst
                    : CrossFadeState.showSecond,
                firstChild: Column(
                  children: List.generate(_sections.length, (index) {
                    final s = _sections[index];
                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          _selectedSectionIndex = index;
                          _isDropdownOpen = false;
                        });
                      },
                      child: Container(
                        width: screenWidth * 0.9,
                        margin: const EdgeInsets.symmetric(vertical: 8),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: s['color'],
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: s['color'].withOpacity(0.3),
                              blurRadius: 6,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              s['section'],
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            Text(
                              s['title'],
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 17,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }),
                ),
                secondChild: const SizedBox.shrink(),
              ),

              const SizedBox(height: 20),

              Image.asset(selected['image'], height: 120),
              const SizedBox(height: 12),
              Text(
                '${selected['section']}, LEVEL 1',
                style: const TextStyle(fontSize: 14, color: Colors.black54),
              ),
              Text(
                selected['title'],
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),

              const SizedBox(height: 20),

              Padding(
                padding: const EdgeInsets.symmetric(vertical: 20.0),
                child: Column(
                  children: List.generate(10, (index) {
                    bool isLeft = index.isEven;
                    bool isUnlocked = index < selected['unlockedLevel'];
                    double progress = isUnlocked ? (index + 1) * 10 : 0;

                    return Padding(
                      padding: EdgeInsets.only(
                        left: isLeft ? 40 : 120,
                        right: isLeft ? 120 : 40,
                        top: 20,
                        bottom: 10,
                      ),
                      child: GestureDetector(
                        onTap: () {
                          if (isUnlocked) {
                            _navigateToLevelDetail(index + 1);
                          } else {
                            _showLockedPopup();
                          }
                        },
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            Container(
                              width: 80,
                              height: 80,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.1),
                                    blurRadius: 8,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                            ),
                            AnimatedContainer(
                              duration: const Duration(milliseconds: 300),
                              width: 80,
                              height: 80,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: isUnlocked
                                    ? selected['color']
                                    : Colors.grey.shade300,
                                border: Border.all(
                                  color: isUnlocked
                                      ? selected['color'].withOpacity(0.8)
                                      : Colors.grey.shade400,
                                  width: 3,
                                ),
                              ),
                              child: Center(
                                child: isUnlocked
                                    ? Column(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          Text(
                                            '${progress.toInt()}%',
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontWeight: FontWeight.bold,
                                              fontSize: 18,
                                            ),
                                          ),
                                          const Text(
                                            'Done',
                                            style: TextStyle(
                                              color: Colors.white70,
                                              fontSize: 12,
                                            ),
                                          ),
                                        ],
                                      )
                                    : const Icon(
                                        Icons.lock,
                                        color: Colors.black45,
                                        size: 28,
                                      ),
                              ),
                            ),
                            Positioned(
                              bottom: -25,
                              child: Text(
                                'LEVEL ${index + 1}',
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 13,
                                  color: isUnlocked
                                      ? Colors.black87
                                      : Colors.black38,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }),
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: BottomNavBar(currentIndex: _currentBottomNavIndex),
    );
  }
}
