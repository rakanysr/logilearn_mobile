import 'package:flutter/material.dart';

class HeaderSection extends StatelessWidget {
  final String selectedSection;
  final String selectedTitle;
  final VoidCallback onNextSection;

  const HeaderSection({
    super.key,
    required this.selectedSection,
    required this.selectedTitle,
    required this.onNextSection,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Stack(
                  alignment: Alignment.bottomCenter,
                  children: [
                    Image.asset(
                      'assets/images/jempol.png',
                      width: 200,
                      height: 200,
                      fit: BoxFit.contain,
                    ),

                    Positioned(
                      bottom: -5,
                      child: Container(
                        width: 70,
                        height: 22,
                        decoration: BoxDecoration(
                          color: Colors.grey[300],
                          shape: BoxShape.rectangle,
                          borderRadius: BorderRadius.circular(30),
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                // Text section
                Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      selectedSection,
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.black,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.2,
                        height: 1.2,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      selectedTitle,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                        letterSpacing: 0.5,
                        height: 1.2,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 24),

                // Progress badge
                Stack(
                  alignment: Alignment.center,
                  children: [
                    // Shadow di bawah untuk efek 3D
                    Positioned(
                      bottom: -4,
                      child: Container(
                        width: 90,
                        height: 20,
                        decoration: BoxDecoration(
                          color:
                              (selectedTitle == 'LOGIKA SILOGISME'
                                      ? const Color(0xFF32CD32)
                                      : selectedTitle == 'LOGIKA PEMROGRAMAN'
                                      ? const Color(0xFF50BFFF)
                                      : const Color(0xFF1E5FD4))
                                  .withOpacity(0.4),
                          shape: BoxShape.rectangle,
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                    // Lingkaran solid
                    Container(
                      width: 90,
                      height: 90,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: selectedTitle == 'LOGIKA SILOGISME'
                            ? const Color(0xFF32CD32)
                            : selectedTitle == 'LOGIKA PEMROGRAMAN'
                            ? const Color(0xFF50BFFF)
                            : const Color(0xFF2977FF),
                        boxShadow: [
                          BoxShadow(
                            color:
                                (selectedTitle == 'LOGIKA SILOGISME'
                                        ? const Color(0xFF32CD32)
                                        : selectedTitle == 'LOGIKA PEMROGRAMAN'
                                        ? const Color(0xFF50BFFF)
                                        : const Color(0xFF2977FF))
                                    .withOpacity(0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Center(
                        child: Text(
                          (selectedTitle == 'LOGIKA SILOGISME' ||
                                  selectedTitle == 'LOGIKA PEMROGRAMAN')
                              ? '-%'
                              : '67%',
                          style: const TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),

                // Show message if LOGIKA SILOGISME or LOGIKA PEMROGRAMAN
                if (selectedTitle == 'LOGIKA SILOGISME' ||
                    selectedTitle == 'LOGIKA PEMROGRAMAN') ...[
                  const SizedBox(height: 12),
                  const Text(
                    'Anda Belum Sampai Section Ini',
                    style: TextStyle(
                      fontSize: 20,
                      color: Colors.black,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ],
            ),
          ),

          const SizedBox(width: 16),

          // Right arrow icon - vertically centered
          GestureDetector(
            onTap: onNextSection,
            child: const Icon(
              Icons.arrow_forward_ios,
              color: Color(0xFF2977FF),
              size: 22,
            ),
          ),
        ],
      ),
    );
  }
}
