import 'package:flutter/material.dart';
import 'package:logilearn/services/api_service.dart';

class SectionDropdownButton extends StatefulWidget {
  final String selectedSection;
  final String selectedTitle;
  final bool isDropdownOpen;
  final VoidCallback onToggleDropdown;
  final Function(String, String, int) onSelectSection;
  final int sectionNumber; // Section number for color synchronization

  const SectionDropdownButton({
    super.key,
    required this.selectedSection,
    required this.selectedTitle,
    required this.isDropdownOpen,
    required this.onToggleDropdown,
    required this.onSelectSection,
    required this.sectionNumber, // Required: section number for color
  });

  @override
  State<SectionDropdownButton> createState() => _SectionDropdownButtonState();
}

class _SectionDropdownButtonState extends State<SectionDropdownButton> {
  List<Map<String, dynamic>> _sections = [];
  bool _isLoading = true;

  // Get section color based on section number (synchronized with header)
  Color _getSectionColor(int sectionNumber) {
    // Same logic as header_section.dart: (sectionNumber - 1) % 3
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
  void initState() {
    super.initState();
    _fetchSections();
  }

  Future<void> _fetchSections() async {
    final apiService = ApiService();
    final result = await apiService.getSections();

    if (result['success']) {
      final fullResponse = result['data'];
      List<dynamic> sectionsList = [];

      if (fullResponse is Map &&
          fullResponse['payload'] is Map &&
          fullResponse['payload']['datas'] is List) {
        sectionsList = fullResponse['payload']['datas'];
      } else if (fullResponse is List) {
        sectionsList = fullResponse;
      }

      if (sectionsList.isNotEmpty) {
        final List<Map<String, dynamic>> parsedSections = [];

        for (var i = 0; i < sectionsList.length; i++) {
          final item = sectionsList[i];

          Color sectionColor;
          if (i % 3 == 0)
            sectionColor = const Color(0xFF2F80ED);
          else if (i % 3 == 1)
            sectionColor = const Color(0xFF2D9CDB);
          else
            sectionColor = const Color(0xFF27AE60);

          parsedSections.add({
            'section': 'SECTION ${i + 1}',
            'title': item['nama'] ?? 'LOGIKA',
            'color': sectionColor,
            'slug': item['slug'] ?? 'section-${i + 1}',
            'id': item['id'],
          });
        }

        if (mounted) {
          setState(() {
            _sections = parsedSections;
            _isLoading = false;
          });
        }
      }
    } else {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      child: Column(
        children: [
          GestureDetector(
            onTap: widget.onToggleDropdown,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              decoration: BoxDecoration(
                color: _getSectionColor(widget.sectionNumber),
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
                        widget.selectedSection.toUpperCase(),
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.9),
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        widget.selectedTitle,
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
                    widget.isDropdownOpen
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
          if (widget.isDropdownOpen) ...[
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
                child: _isLoading
                    ? const Padding(
                        padding: EdgeInsets.all(20),
                        child: Center(
                          child: CircularProgressIndicator(color: Colors.white),
                        ),
                      )
                    : Column(
                        children: _sections.asMap().entries.map((entry) {
                          final index = entry.key;
                          final section = entry.value;

                          return Padding(
                            padding: EdgeInsets.only(
                              bottom: index == _sections.length - 1 ? 0 : 12,
                            ),
                            child: _DropdownItem(
                              section:
                                  section['section'] ?? 'SECTION ${index + 1}',
                              title: section['title'] ?? 'LOGIKA',
                              color:
                                  section['color'] ?? const Color(0xFF2977FF),
                              sectionNumber: index + 1,
                              onTap: () => widget.onSelectSection(
                                'Section ${index + 1}, Level 1',
                                section['title'] ?? 'LOGIKA',
                                index + 1,
                              ),
                            ),
                          );
                        }).toList(),
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
