import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:logilearn/services/api_service.dart';
import 'package:logilearn/view/widgetAttempt/dropdown_button.dart'
    as dropdown_widget;
import 'package:logilearn/view/widgetAttempt/header_section.dart';
import 'package:logilearn/view/widgetAttempt/question_card.dart';
import 'package:logilearn/view/widgetAttempt/question_card_with_feedback.dart';
import 'package:logilearn/widget/bottombar.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

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
  Map<String, dynamic>? _attemptData; // Store attempt data
  String? _errorMessage;
  final _storage = const FlutterSecureStorage();

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

      // 1. Get student ID from secure storage
      final pelajarIdStr = await _storage.read(key: 'id_pelajar');
      if (pelajarIdStr == null) {
        setState(() {
          _errorMessage = 'ID Pelajar tidak ditemukan. Silakan login kembali.';
          _isLoading = false;
        });
        return;
      }
      final pelajarId = int.parse(pelajarIdStr);
      print('=== Loading attempt data for pelajar: $pelajarId ===');

      // 2. Fetch attempts for this student
      final attemptsResult = await apiService.getAttemptsByPelajarId(pelajarId);

      if (!attemptsResult['success']) {
        setState(() {
          _errorMessage =
              attemptsResult['message'] ?? 'Gagal memuat data attempt';
          _isLoading = false;
        });
        return;
      }

      // 3. Parse attempts and filter by current level
      final attemptsResponse = attemptsResult['data'];
      List<dynamic> attemptsList = [];

      print('DEBUG: attemptsResponse type: ${attemptsResponse.runtimeType}');

      if (attemptsResponse is Map && attemptsResponse['payload'] is Map) {
        final payload = attemptsResponse['payload'] as Map;
        print('DEBUG: payload keys: ${payload.keys.toList()}');
        if (payload['datas'] is List) {
          attemptsList = payload['datas'] as List;
          print('DEBUG: Successfully parsed ${attemptsList.length} attempts');
        } else {
          print(
            'ERROR: payload[\"datas\"] is not a List, type: ${payload['datas'].runtimeType}',
          );
        }
      } else if (attemptsResponse is List) {
        attemptsList = attemptsResponse;
        print('DEBUG: Response is directly a List');
      } else {
        print('ERROR: Unexpected response type');
      }

      print('Found ${attemptsList.length} total attempts');

      if (attemptsList.isEmpty) {
        print('WARNING: No attempts found for this student');
        setState(() {
          _errorMessage =
              'Belum ada attempt ditemukan.\n\nSilakan kerjakan quiz terlebih dahulu.';
          _isLoading = false;
        });
        return;
      }

      // Get the most recent attempt (first one since backend orders by id desc)
      // Don't filter by level - show whatever attempt is available
      final attemptMap = attemptsList.first is Map<String, dynamic>
          ? attemptsList.first
          : Map<String, dynamic>.from(attemptsList.first as Map);

      print(
        'Using attempt ID: ${attemptMap['id']} for level: ${attemptMap['id_level']}',
      );

      // Show info if attempt is from different level
      if (attemptMap['id_level'] != widget.levelId) {
        print(
          'INFO: Showing attempt from level ${attemptMap['id_level']} (current page is level ${widget.levelId})',
        );
      }

      // 4. Extract soals from attempt answers instead of fetching separately
      // This handles cases where attempt level doesn't match actual question levels
      print('Extracting soals from attempt answers...');

      try {
        final jawabanPGs = attemptMap['jawaban_pgs'] as List? ?? [];
        final jawabanEsais = attemptMap['jawaban_esais'] as List? ?? [];

        print(
          'Found ${jawabanPGs.length} PG answers and ${jawabanEsais.length} essay answers',
        );

        // Build soals list from answers
        Map<int, Map<String, dynamic>> soalsMap = {};

        // Extract from PG answers
        for (var jawaban in jawabanPGs) {
          if (jawaban['opsis'] != null && jawaban['opsis']['soals'] != null) {
            final soal = jawaban['opsis']['soals'];
            final soalId = soal['id'];

            if (!soalsMap.containsKey(soalId)) {
              // Get all opsis for this soal from the level data if available
              // For now, we'll just mark the selected opsi
              soalsMap[soalId] = {
                'id': soalId,
                'text_soal': soal['text_soal'] ?? '',
                'tipe': soal['tipe'] ?? 'pg',
                'opsis': [],
                'kata_kunci': soal['kata_kunci'] ?? '',
              };
            }
          }
        }

        // Extract from Essay answers
        for (var jawaban in jawabanEsais) {
          if (jawaban['soals'] != null) {
            final soal = jawaban['soals'];
            final soalId = soal['id'];

            if (!soalsMap.containsKey(soalId)) {
              soalsMap[soalId] = {
                'id': soalId,
                'text_soal': soal['text_soal'] ?? '',
                'tipe': soal['tipe'] ?? 'esai',
                'opsis': [],
                'kata_kunci': soal['kata_kunci'] ?? '',
              };
            }
          }
        }

        if (soalsMap.isNotEmpty) {
          // Extract section info from attempt data
          final levelData = attemptMap['levels'];
          final sectionData = levelData?['sections'];

          setState(() {
            _attemptData = attemptMap;
            _soals = soalsMap.values.toList();

            // Update section title and number from attempt data
            if (sectionData != null) {
              final sectionId = sectionData['id'] ?? 1;
              final sectionName = sectionData['nama'] ?? 'Unknown Section';
              final levelName = levelData?['nama'] ?? 'Level 1';

              _selectedSection = 'Section $sectionId, $levelName';
              _selectedTitle = sectionName.toUpperCase();
            }

            _isLoading = false;
          });
          print('Extracted ${_soals.length} unique soals from attempt answers');
          print('Section: $_selectedSection, Title: $_selectedTitle');
        } else {
          setState(() {
            _errorMessage = 'Tidak ada soal ditemukan dalam attempt ini';
            _isLoading = false;
          });
        }
      } catch (e) {
        print('Error extracting soals from attempt: $e');
        setState(() {
          _errorMessage = 'Error memproses data attempt: ${e.toString()}';
          _isLoading = false;
        });
      }
    } catch (e, stackTrace) {
      setState(() {
        _errorMessage = 'Error: ${e.toString()}';
        _isLoading = false;
      });
      print('Exception in _loadLevelData: $e');
      print('Stack trace: $stackTrace');
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
                score: _attemptData != null
                    ? (_attemptData!['skor'] as num?)?.toDouble()
                    : null,
              ),

              const SizedBox(height: 32),

              // Display questions from backend with actual attempt data
              if (_soals.isNotEmpty && _attemptData != null)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    children: _soals.asMap().entries.map((entry) {
                      final index = entry.key;
                      final soal = entry.value;
                      final questionNumber = index + 1;
                      final tipe = soal['tipe'] as String? ?? 'pg';
                      final textSoal = soal['text_soal'] as String? ?? '';
                      final soalId = soal['id'];

                      if (tipe == 'esai') {
                        // Find essay answer from attempt data
                        final jawabanEsais =
                            _attemptData!['jawaban_esais'] as List? ?? [];
                        final jawabanEsai = jawabanEsais.firstWhere(
                          (j) => j['id_soal'] == soalId,
                          orElse: () => null,
                        );

                        final score = jawabanEsai != null
                            ? (jawabanEsai['skor'] ?? 0.0).toString()
                            : '0';
                        final isCorrect = jawabanEsai != null
                            ? (jawabanEsai['skor'] ?? 0.0) >= 0.5
                            : false;
                        final answer = jawabanEsai != null
                            ? (jawabanEsai['text_jawaban_esai'] ??
                                  'Tidak ada jawaban')
                            : 'Tidak ada jawaban';
                        final feedback =
                            jawabanEsai != null && jawabanEsai['admins'] != null
                            ? 'Dinilai oleh: ${jawabanEsai['admins']['nama'] ?? 'Admin'}'
                            : 'Dinilai otomatis oleh AI';

                        return Padding(
                          padding: const EdgeInsets.only(bottom: 16),
                          child: QuestionCardWithFeedback(
                            questionNumber: questionNumber,
                            score: '$score/1',
                            isCorrect: isCorrect,
                            question: textSoal,
                            answer: answer,
                            feedback: feedback,
                          ),
                        );
                      } else {
                        // Find PG answer from attempt data
                        final jawabanPGs =
                            _attemptData!['jawaban_pgs'] as List? ?? [];

                        // Find the student's answer
                        Map<String, dynamic>? studentAnswer;
                        for (var jawaban in jawabanPGs) {
                          final opsi = jawaban['opsis'];
                          if (opsi != null && opsi['soals'] != null) {
                            if (opsi['soals']['id'] == soalId) {
                              studentAnswer = jawaban;
                              break;
                            }
                          }
                        }

                        final score = studentAnswer != null
                            ? (studentAnswer['skor'] ?? 0.0).toString()
                            : '0';
                        final isCorrect = studentAnswer != null
                            ? (studentAnswer['skor'] ?? 0.0) >= 1.0
                            : false;

                        // Get the answer text
                        String answerText = 'Tidak ada jawaban';
                        if (studentAnswer != null &&
                            studentAnswer['opsis'] != null) {
                          answerText =
                              studentAnswer['opsis']['text_opsi'] ??
                              'Tidak ada jawaban';
                        }

                        return Padding(
                          padding: const EdgeInsets.only(bottom: 16),
                          child: QuestionCard(
                            questionNumber: questionNumber,
                            score: '$score/1',
                            isCorrect: isCorrect,
                            question: textSoal,
                            answer: answerText,
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
                    _attemptData == null
                        ? 'Belum ada data attempt. Silakan kerjakan quiz terlebih dahulu.'
                        : 'Tidak ada soal ditemukan untuk level ini',
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
