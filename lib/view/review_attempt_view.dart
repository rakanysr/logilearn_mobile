import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:logilearn/services/api_service.dart';
import 'package:logilearn/view/widgetAttempt/dropdown_button.dart'
    as dropdown_widget;
import 'package:logilearn/view/widgetAttempt/header_section.dart';
import 'package:logilearn/view/widgetAttempt/question_card.dart';
import 'package:logilearn/view/widgetAttempt/question_card_with_feedback.dart';
import 'package:logilearn/widget/bottombar.dart';

class ReviewAttemptView extends StatefulWidget {
  final String sectionSlug;
  final int levelId;
  final String sectionTitle;
  final int sectionNumber;
  final int levelNumber;

  const ReviewAttemptView({
    super.key,
    required this.sectionSlug,
    required this.levelId,
    required this.sectionTitle,
    required this.sectionNumber,
    required this.levelNumber,
  });

  @override
  State<ReviewAttemptView> createState() => _ReviewAttemptViewState();
}

class _ReviewAttemptViewState extends State<ReviewAttemptView> {
  bool _isDropdownOpen = false;
  String _selectedSection = 'Section 1, Level 1';
  String _selectedTitle = 'LOGIKA DASAR';
  int _currentBottomNavIndex = 1;
  bool _isLoading = true;
  List<Map<String, dynamic>> _soals = [];
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _selectedSection =
        'Section ${widget.sectionNumber}, Level ${widget.levelNumber}';
    _selectedTitle = widget.sectionTitle;
    _loadLevelData();
  }

  Future<void> _loadLevelData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final apiService = ApiService();
      print('=== Loading soals data ===');
      print('  sectionSlug: ${widget.sectionSlug}');
      print('  levelId: ${widget.levelId}');
      print(
        '  Full URL will be: ${ApiService.baseUrl}/${widget.sectionSlug}/levels/${widget.levelId}/soal',
      );

      // Use new endpoint to get soals directly
      final result = await apiService.getSoalsByLevel(
        widget.sectionSlug,
        widget.levelId,
      );

      print('API Response success: ${result['success']}');
      print('API Response data keys: ${result['data']?.keys}');

      if (result['success']) {
        final fullResponse = result['data'];
        List<dynamic> soalsList = [];

        // Parse response structure from helpers/response.js
        // Structure: { payload: { datas: [...] } }
        if (fullResponse is Map && fullResponse['payload'] is Map) {
          final payload = fullResponse['payload'] as Map;

          if (payload['datas'] is List) {
            soalsList = payload['datas'] as List;
            print(
              'Parsed soals from payload.datas (array): ${soalsList.length}',
            );
          } else if (payload['datas'] is Map) {
            // If single object, wrap in array
            soalsList = [payload['datas']];
            print('Parsed soals from payload.datas (object, wrapped in array)');
          }
        } else if (fullResponse is Map && fullResponse['datas'] is List) {
          soalsList = fullResponse['datas'] as List;
          print('Parsed soals from datas (array): ${soalsList.length}');
        } else if (fullResponse is List) {
          soalsList = fullResponse;
          print('Parsed soals from direct list: ${soalsList.length}');
        }

        print('Found ${soalsList.length} soals');

        if (soalsList.isNotEmpty) {
          setState(() {
            _soals = soalsList.map<Map<String, dynamic>>((soal) {
              final soalMap = soal is Map<String, dynamic>
                  ? soal
                  : (soal is Map
                        ? Map<String, dynamic>.from(soal)
                        : <String, dynamic>{});

              // Parse opsis with correct field names from backend
              // Backend uses: text_opsi, is_correct
              List<dynamic> opsisList = [];
              if (soalMap['opsis'] is List) {
                opsisList = (soalMap['opsis'] as List).map((opsi) {
                  final opsiMap = opsi is Map<String, dynamic>
                      ? opsi
                      : (opsi is Map
                            ? Map<String, dynamic>.from(opsi)
                            : <String, dynamic>{});
                  // Map backend field names to our internal format
                  return {
                    'id': opsiMap['id'],
                    'text':
                        opsiMap['text_opsi'] ??
                        opsiMap['text'] ??
                        '', // Backend uses text_opsi
                    'text_opsi':
                        opsiMap['text_opsi'] ??
                        opsiMap['text'] ??
                        '', // Keep original for compatibility
                    'is_benar':
                        opsiMap['is_correct'] ??
                        opsiMap['is_benar'] ??
                        false, // Backend uses is_correct
                    'is_correct':
                        opsiMap['is_correct'] ??
                        opsiMap['is_benar'] ??
                        false, // Keep original for compatibility
                  };
                }).toList();
                print(
                  'Parsed ${opsisList.length} opsis for soal ${soalMap['id']}',
                );
              } else {
                print(
                  'No opsis found or opsis is not a List for soal ${soalMap['id']}',
                );
              }

              return {
                'id': soalMap['id'],
                'text_soal': soalMap['text_soal'] ?? '',
                'tipe': soalMap['tipe'] ?? 'pg',
                'opsis': opsisList,
                'kata_kunci':
                    soalMap['kata_kunci'] ?? '', // For essay questions
              };
            }).toList();
            _isLoading = false;
          });
          print('Soals loaded successfully: ${_soals.length}');
        } else {
          setState(() {
            _errorMessage = 'Tidak ada soal ditemukan untuk level ini';
            _isLoading = false;
          });
          print('No soals found in list');
        }
      } else {
        setState(() {
          _errorMessage = result['message'] ?? 'Gagal memuat soal dari server';
          _isLoading = false;
        });
        print('API call failed: ${result['message']}');
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error: ${e.toString()}';
        _isLoading = false;
      });
      print('Exception in _loadLevelData: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: Colors.white,
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_errorMessage != null) {
      return Scaffold(
        backgroundColor: Colors.white,
        body: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
                  const SizedBox(height: 16),
                  Text(
                    'Oops! Terjadi Kesalahan',
                    style: GoogleFonts.inter(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _errorMessage!,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      color: Colors.grey[700],
                    ),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: _loadLevelData,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2977FF),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 32,
                        vertical: 12,
                      ),
                    ),
                    child: Text(
                      'Coba Lagi',
                      style: GoogleFonts.inter(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }
    return Theme(
      data: Theme.of(context).copyWith(
        textTheme: GoogleFonts.interTextTheme(Theme.of(context).textTheme),
      ),
      child: Scaffold(
        backgroundColor: Colors.white,
        body: SingleChildScrollView(
          child: Column(
            children: [
              dropdown_widget.SectionDropdownButton(
                selectedSection: _selectedSection,
                selectedTitle: _selectedTitle,
                isDropdownOpen: _isDropdownOpen,
                onToggleDropdown: () {
                  setState(() {
                    _isDropdownOpen = !_isDropdownOpen;
                  });
                },
                onSelectSection: (section, title, number) {
                  setState(() {
                    _selectedSection = section;
                    _selectedTitle = title;
                    _isDropdownOpen = false;
                  });
                },
              ),

              const SizedBox(height: 24),

              HeaderSection(
                selectedSection: _selectedSection,
                selectedTitle: _selectedTitle,
                onNextSection: _nextSection,
              ),

              const SizedBox(height: 32),

              // Display questions from backend
              if (_soals.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    children: _soals.asMap().entries.map((entry) {
                      final index = entry.key;
                      final soal = entry.value;
                      final questionNumber = index + 1;
                      final tipe = soal['tipe'] as String? ?? 'pg';
                      final textSoal = soal['text_soal'] as String? ?? '';
                      final opsis = soal['opsis'] as List? ?? [];

                      // For now, we'll show placeholder data since we don't have attempt data
                      // In a real scenario, you would fetch attempt data separately
                      if (tipe == 'esai') {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 16),
                          child: QuestionCardWithFeedback(
                            questionNumber: questionNumber,
                            score:
                                '0/1', // Placeholder - should come from attempt data
                            isCorrect:
                                false, // Placeholder - should come from attempt data
                            question: textSoal,
                            answer:
                                'Jawaban belum tersedia', // Placeholder - should come from attempt data
                            feedback:
                                'Feedback belum tersedia', // Placeholder - should come from attempt data
                          ),
                        );
                      } else {
                        // Find the correct option text
                        // Support both is_benar and is_correct, and both text and text_opsi
                        String correctAnswerText = 'Jawaban belum tersedia';
                        if (opsis.isNotEmpty) {
                          try {
                            final correctOption = opsis.firstWhere(
                              (opsi) =>
                                  (opsi['is_benar'] == true) ||
                                  (opsi['is_correct'] == true),
                            );
                            if (correctOption != null) {
                              correctAnswerText =
                                  (correctOption['text'] ??
                                          correctOption['text_opsi'] ??
                                          'Jawaban belum tersedia')
                                      .toString();
                            }
                          } catch (e) {
                            // If no correct option found, try to find manually
                            for (var opsi in opsis) {
                              if ((opsi['is_benar'] == true) ||
                                  (opsi['is_correct'] == true)) {
                                correctAnswerText =
                                    (opsi['text'] ??
                                            opsi['text_opsi'] ??
                                            'Jawaban belum tersedia')
                                        .toString();
                                break;
                              }
                            }
                          }
                        }
                        if (correctAnswerText.isEmpty) {
                          correctAnswerText = 'Jawaban belum tersedia';
                        }

                        return Padding(
                          padding: const EdgeInsets.only(bottom: 16),
                          child: QuestionCard(
                            questionNumber: questionNumber,
                            score:
                                '0/1', // Placeholder - should come from attempt data
                            isCorrect:
                                false, // Placeholder - should come from attempt data
                            question: textSoal,
                            answer:
                                correctAnswerText, // Placeholder - should come from attempt data
                          ),
                        );
                      }
                    }).toList(),
                  ),
                )
              else
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Text(
                    'Tidak ada soal ditemukan untuk level ini',
                    style: GoogleFonts.inter(color: Colors.grey),
                  ),
                ),

              const SizedBox(height: 30),
            ],
          ),
        ),
        bottomNavigationBar: BottomNavBar(
          currentIndex: _currentBottomNavIndex,
          onTap: (index) {
            setState(() {
              _currentBottomNavIndex = index;
            });
            // Handle navigation based on index
            if (index == 0) {
            } else if (index == 1) {
            } else if (index == 2) {}
          },
        ),
      ),
    );
  }

  void _nextSection() {
    setState(() {
      if (_selectedTitle == 'LOGIKA DASAR') {
        _selectedSection = 'Section 2, Level 1';
        _selectedTitle = 'LOGIKA PEMROGRAMAN';
      } else if (_selectedTitle == 'LOGIKA PEMROGRAMAN') {
        _selectedSection = 'Section 3, Level 1';
        _selectedTitle = 'LOGIKA SILOGISME';
      } else if (_selectedTitle == 'LOGIKA SILOGISME') {
        _selectedSection = 'Section 1, Level 1';
        _selectedTitle = 'LOGIKA DASAR';
      }
    });
  }
}
