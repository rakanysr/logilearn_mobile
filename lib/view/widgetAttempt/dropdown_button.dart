import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
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
          if (i % 3 == 0) {
            sectionColor = const Color(0xFF2F80ED);
          } else if (i % 3 == 1) {
            sectionColor = const Color(0xFF2D9CDB);
          } else {
            sectionColor = const Color(0xFF27AE60);
          }

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
    final sectionColor = _getSectionColor(widget.sectionNumber);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      child: Column(
        children: [
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: widget.onToggleDropdown,
              borderRadius: BorderRadius.circular(18),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  vertical: 18,
                  horizontal: 20,
                ),
                decoration: BoxDecoration(
                  color: sectionColor,
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: [
                    BoxShadow(
                      color: sectionColor.withValues(
                        alpha: 0.3,
                      ),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.selectedSection.toUpperCase(),
                            style: GoogleFonts.inter(
                              color: Colors.white,
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                          ),
                          Text(
                            widget.selectedTitle,
                            style: GoogleFonts.inter(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                            overflow: TextOverflow.ellipsis,
                            maxLines: 2,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
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
          ),

          // Dropdown Menu
          if (widget.isDropdownOpen) ...[
            const SizedBox(height: 8),
            Material(
              color: Colors.transparent,
              elevation: 8,
              borderRadius: BorderRadius.circular(18),
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
                            bottom: index == _sections.length - 1 ? 0 : 8.0,
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
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(
            vertical: 18,
            horizontal: 20,
          ),
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                color: color.withValues(
                  alpha: 0.3,
                ),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                section,
                style: GoogleFonts.inter(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                title,
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
  }
}
