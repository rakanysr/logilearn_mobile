import 'package:flutter/material.dart';

class SectionDropdownButton extends StatelessWidget {
  final String selectedSection;
  final String selectedTitle;
  final bool isDropdownOpen;
  final VoidCallback onToggleDropdown;
  final Function(String, String, int) onSelectSection;

  const SectionDropdownButton({
    super.key,
    required this.selectedSection,
    required this.selectedTitle,
    required this.isDropdownOpen,
    required this.onToggleDropdown,
    required this.onSelectSection,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      child: Column(
        children: [
          GestureDetector(
            onTap: onToggleDropdown,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              decoration: BoxDecoration(
                color: const Color(0xFF2977FF),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        selectedSection.toUpperCase(),
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.9),
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        selectedTitle,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                  const Spacer(),
                  Container(
                    width: 1,
                    height: 30,
                    color: Colors.white.withOpacity(0.3),
                    margin: const EdgeInsets.symmetric(horizontal: 12),
                  ),
                  // Chevron icon
                  Icon(
                    isDropdownOpen
                        ? Icons.keyboard_arrow_up
                        : Icons.keyboard_arrow_down,
                    color: Colors.white,
                    size: 28,
                  ),
                ],
              ),
            ),
          ),

          // Dropdown Menu
          if (isDropdownOpen) ...[
            const SizedBox(height: 8),
            Material(
              elevation: 24,
              borderRadius: BorderRadius.circular(16),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFF363636),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    _DropdownItem(
                      section: 'SECTION 1',
                      title: 'LOGIKA DASAR',
                      color: const Color(0xFF2977FF),
                      sectionNumber: 1,
                      onTap: () => onSelectSection(
                        'Section 1, Level 1',
                        'LOGIKA DASAR',
                        1,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _DropdownItem(
                      section: 'SECTION 2',
                      title: 'LOGIKA PEMROGRAMAN',
                      color: const Color(0xFF50BFFF),
                      sectionNumber: 2,
                      onTap: () => onSelectSection(
                        'Section 2, Level 1',
                        'LOGIKA PEMROGRAMAN',
                        2,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _DropdownItem(
                      section: 'SECTION 3',
                      title: 'LOGIKA SILOGISME',
                      color: const Color(0xFF32CD32),
                      sectionNumber: 3,
                      onTap: () => onSelectSection(
                        'Section 3, Level 1',
                        'LOGIKA SILOGISME',
                        3,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _DropdownItem extends StatelessWidget {
  final String section;
  final String title;
  final Color color;
  final int sectionNumber;
  final VoidCallback onTap;

  const _DropdownItem({
    required this.section,
    required this.title,
    required this.color,
    required this.sectionNumber,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.15),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              section,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
