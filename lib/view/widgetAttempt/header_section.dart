import 'package:flutter/material.dart';

class HeaderSection extends StatelessWidget {
  final String selectedSection;
  final String selectedTitle;
  final VoidCallback onNextSection;
  final VoidCallback? onPreviousLevel; // Add callback for previous level
  final double? score; // Add score parameter
  final bool hasAttempt; // Whether this section has been attempted
  final int sectionNumber; // Section number for color synchronization
  final bool canNavigatePrevious; // Whether previous navigation is available
  final bool canNavigateNext; // Whether next navigation is available

  const HeaderSection({
    super.key,
    required this.selectedSection,
    required this.selectedTitle,
    required this.onNextSection,
    this.onPreviousLevel, // Optional callback for previous level
    this.score, // Optional score
    required this.hasAttempt, // Required: indicates if section has attempt data
    required this.sectionNumber, // Required: section number for color
    this.canNavigatePrevious = true, // Default to true
    this.canNavigateNext = true, // Default to true
  });

  // Get section color based on section number (synchronized with dropdown)
  Color _getSectionColor(int sectionNumber) {
    // Same logic as dropdown_button.dart: (i % 3)
    // Section 1: (1-1) % 3 = 0 -> Blue
    // Section 2: (2-1) % 3 = 1 -> Light Blue
    // Section 3: (3-1) % 3 = 2 -> Green
    final index = (sectionNumber - 1) % 3;
    if (index == 0) {
      return const Color(0xFF2F80ED); // Blue for Section 1
    } else if (index == 1) {
      return const Color(0xFF2D9CDB); // Light Blue for Section 2
    } else {
      return const Color(0xFF27AE60); // Green for Section 3
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Left arrow icon - for previous level
          if (canNavigatePrevious && onPreviousLevel != null)
            GestureDetector(
              onTap: onPreviousLevel,
              child: const Icon(
                Icons.arrow_back_ios,
                color: Color(0xFF2977FF),
                size: 22,
              ),
            )
          else
            const SizedBox(width: 22), // Placeholder to maintain spacing

          const SizedBox(width: 16),

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
                          color: _getSectionColor(
                            sectionNumber,
                          ).withValues(alpha: 0.4),
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
                        color: _getSectionColor(sectionNumber),
                        boxShadow: [
                          BoxShadow(
                            color: _getSectionColor(
                              sectionNumber,
                            ).withValues(alpha: 0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Center(
                        child: Text(
                          (score != null && score! > 0)
                              ? '${score!.toStringAsFixed(0)}%'
                              : '0%',
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

                // Show message only if section hasn't been attempted yet
                if (!hasAttempt) ...[
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

          // Right arrow icon - for next level
          if (canNavigateNext)
            GestureDetector(
              onTap: onNextSection,
              child: const Icon(
                Icons.arrow_forward_ios,
                color: Color(0xFF2977FF),
                size: 22,
              ),
            )
          else
            const SizedBox(width: 22), // Placeholder to maintain spacing
        ],
      ),
    );
  }
}
