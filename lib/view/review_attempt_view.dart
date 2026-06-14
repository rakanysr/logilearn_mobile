import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:logilearn/services/api_service.dart';
import 'package:logilearn/view/widgetAttempt/dropdown_button.dart'
    as dropdown_widget;
import 'package:logilearn/view/widgetAttempt/header_section.dart';
import 'package:logilearn/view/widgetAttempt/question_card.dart';
import 'package:logilearn/view/widgetAttempt/question_card_with_feedback.dart';
import 'package:logilearn/view/home_view.dart';
import 'package:logilearn/widget/bottombar.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class ReviewAttemptView extends StatefulWidget {
  final int attemptId;
  final String sectionSlug;
  final int levelId;
  final String sectionTitle;
  final int sectionNumber;
  final int levelNumber;

  const ReviewAttemptView({
    super.key,
    required this.attemptId,
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
  int _selectedSectionNumber = 1; // Track selected section number
  final int _currentBottomNavIndex = 2;
  bool _isLoading = true;
  List<Map<String, dynamic>> _soals = [];
  Map<String, dynamic>? _attemptData; // Store attempt data
  String? _errorMessage;
  List<Map<String, dynamic>> _sectionsList =
      []; // Store sections list for navigation
  final _storage = const FlutterSecureStorage();

  // Level navigation state
  List<Map<String, dynamic>> _levelsList =
      []; // Store levels for current section
  int _currentLevelIndex = 0; // Current level index in the levels list
  int? _currentLevelId; // Current level ID being viewed

  @override
  void initState() {
    super.initState();
    _selectedSection =
        'Section ${widget.sectionNumber}, Level ${widget.levelNumber}';
    _selectedTitle = widget.sectionTitle;
    _selectedSectionNumber = widget.sectionNumber;
    _currentLevelId = widget.levelId; // Initialize with widget level ID
    _initData();
  }

  Future<void> _initData() async {
    await _fetchLevelsForSection();
    _loadLevelData();
  }
  List<dynamic> _extractList(dynamic response) {
    if (response is List) return response;
    if (response is Map &&
        response['payload'] is Map &&
        response['payload']['datas'] is List) {
      return response['payload']['datas'] as List;
    }
    if (response is Map && response['datas'] is List) {
      return response['datas'] as List;
    }
    return [];
  }

  void _populateSectionsList(Map<String, dynamic> sectionsResult) {
    final sectionsList = <Map<String, dynamic>>[];
    try {
      if (sectionsResult['success']) {
        final sectionsResponse = sectionsResult['data'];
        List<dynamic> sectionsData = [];

        if (sectionsResponse is Map &&
            sectionsResponse['payload'] is Map &&
            sectionsResponse['payload']['datas'] is List) {
          sectionsData = sectionsResponse['payload']['datas'];
        } else if (sectionsResponse is List) {
          sectionsData = sectionsResponse;
        }

        for (var i = 0; i < sectionsData.length; i++) {
          final section = sectionsData[i] is Map<String, dynamic>
              ? sectionsData[i]
              : Map<String, dynamic>.from(sectionsData[i] as Map);
          sectionsList.add({
            'id': section['id'],
            'nama': section['nama'] ?? '',
            'slug': section['slug'] ?? 'section-${i + 1}',
            'sectionNumber': i + 1,
          });
        }
        setState(() {
          _sectionsList = sectionsList;
        });
      }
    } catch (e) {
      debugPrint('Error fetching sections: $e');
    }
  }

  Future<void> _loadLevelData() async {
    debugPrint('=== _loadLevelData called for attempt ${widget.attemptId} ===');
    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _attemptData = null;
      _soals = [];
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

      final pelajarId = int.tryParse(pelajarIdStr) ?? 0;
      debugPrint('=== Loading attempt data for pelajar: $pelajarId ===');

      int attemptIdToFetch = widget.attemptId;
      if (_currentLevelId != null && _currentLevelId != widget.levelId) {
        final attemptsResult = await apiService.getAttemptsByPelajarId(pelajarId);
        if (attemptsResult['success']) {
          final List<dynamic> rawList = _extractList(attemptsResult['data']);
          final List<Map<String, dynamic>> matchedAttempts = rawList
              .whereType<Map>()
              .map((item) => Map<String, dynamic>.from(item))
              .where((item) {
                final itemLevelId = item['id_level'] ?? (item['levels'] is Map ? item['levels']['id'] : null);
                final parsedItemLevelId = int.tryParse(itemLevelId?.toString() ?? '');
                return parsedItemLevelId == _currentLevelId;
              })
              .toList();

          if (matchedAttempts.isNotEmpty) {
            matchedAttempts.sort((a, b) {
              final aId = int.tryParse(a['id']?.toString() ?? '') ?? 0;
              final bId = int.tryParse(b['id']?.toString() ?? '') ?? 0;
              return bId.compareTo(aId);
            });
            attemptIdToFetch = int.tryParse(matchedAttempts.first['id']?.toString() ?? '') ?? 0;
          } else {
            // Load sections first to populate dropdown/headers
            final sectionsResult = await apiService.getSections();
            _populateSectionsList(sectionsResult);

            String levelName = 'Level 1';
            if (_levelsList.isNotEmpty && _currentLevelIndex >= 0 && _currentLevelIndex < _levelsList.length) {
              levelName = _levelsList[_currentLevelIndex]['nama'] ?? 'Level 1';
            }

            final currentSec = _sectionsList.firstWhere(
              (s) => s['sectionNumber'] == _selectedSectionNumber,
              orElse: () => {'nama': widget.sectionTitle},
            );
            final sectionName = currentSec['nama'] ?? widget.sectionTitle;

            setState(() {
              _attemptData = null;
              _soals = [];
              _selectedSection = 'Section $_selectedSectionNumber, $levelName';
              _selectedTitle = sectionName.toUpperCase();
              _isLoading = false;
            });
            return;
          }
        } else {
          setState(() {
            _errorMessage = 'Gagal memuat history attempt untuk level ini.';
            _isLoading = false;
          });
          return;
        }
      }

      final results = await Future.wait([
        apiService.getAttemptById(attemptIdToFetch),
        apiService.getSections(),
      ]);

      final attemptResult = results[0];
      final sectionsResult = results[1];

      if (!attemptResult['success']) {
        setState(() {
          _errorMessage =
              attemptResult['message'] ?? 'Gagal memuat data attempt.';
          _isLoading = false;
        });
        return;
      }

      final attemptDataRaw = attemptResult['data'];
      final attemptData = _extractDataObject(attemptDataRaw);
      if (attemptData == null) {
        setState(() {
          _errorMessage = 'Gagal memproses data attempt.';
          _isLoading = false;
        });
        return;
      }

      if (pelajarId > 0 && attemptData['id_pelajar'] != null) {
        final attemptPelajarId = int.tryParse(attemptData['id_pelajar'].toString()) ??
            (attemptData['id_pelajar'] is int
                ? attemptData['id_pelajar'] as int
                : 0);
        if (attemptPelajarId != pelajarId) {
          setState(() {
            _errorMessage = 'Attempt tidak tersedia untuk pengguna ini.';
            _isLoading = false;
          });
          return;
        }
      }

      // Build sections list from API result
      _populateSectionsList(sectionsResult);

      final levelData = attemptData['levels'] is Map
          ? Map<String, dynamic>.from(attemptData['levels'] as Map)
          : <String, dynamic>{};
      final sectionData = levelData['sections'] is Map
          ? Map<String, dynamic>.from(levelData['sections'] as Map)
          : <String, dynamic>{};

      final sectionName = sectionData['nama']?.toString() ?? widget.sectionTitle;
      final levelName = levelData['nama']?.toString() ?? 'Level ${widget.levelNumber}';

      int selectedSectionNumber = widget.sectionNumber;
      if (sectionData['id'] != null && _sectionsList.isNotEmpty) {
        final matchedSection = _sectionsList.firstWhere(
          (s) {
            final sId = s['id'] is int
                ? s['id'] as int
                : int.tryParse(s['id']?.toString() ?? '');
            final sectionId = sectionData['id'] is int
                ? sectionData['id'] as int
                : int.tryParse(sectionData['id']?.toString() ?? '');
            return sId != null && sectionId != null && sId == sectionId;
          },
          orElse: () => {},
        );
        if (matchedSection.isNotEmpty) {
          selectedSectionNumber = matchedSection['sectionNumber'] as int;
        }
      }

      Map<int, Map<String, dynamic>> soalsMap = {};
      final jawabanPGs = attemptData['jawaban_pgs'] as List? ?? [];
      final jawabanEsais = attemptData['jawaban_esais'] as List? ?? [];

      for (var jawaban in jawabanPGs) {
        if (jawaban is Map && jawaban['opsis'] != null &&
            jawaban['opsis']['soals'] != null) {
          final soal = jawaban['opsis']['soals'];
          final soalId = soal['id'];
          if (soalId != null && !soalsMap.containsKey(soalId)) {
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

      for (var jawaban in jawabanEsais) {
        if (jawaban is Map && jawaban['soals'] != null) {
          final soal = jawaban['soals'];
          final soalId = soal['id'];
          if (soalId != null && !soalsMap.containsKey(soalId)) {
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

      if (soalsMap.isEmpty) {
        setState(() {
          _errorMessage = 'Tidak ada soal ditemukan dalam attempt ini';
          _isLoading = false;
        });
        return;
      }

      setState(() {
        _attemptData = attemptData;
        _soals = soalsMap.values.toList();
        _selectedSectionNumber = selectedSectionNumber;
        _selectedSection = 'Section $selectedSectionNumber, $levelName';
        _selectedTitle = sectionName.toUpperCase();
        _isLoading = false;
      });

      debugPrint('Loaded attempt ${widget.attemptId} for section $selectedSectionNumber');
    } catch (e, stackTrace) {
      setState(() {
        _errorMessage = 'Error: ${e.toString()}';
        _isLoading = false;
      });
      debugPrint('Exception in _loadLevelData: $e');
      debugPrint('Stack trace: $stackTrace');
    }
  }

  Map<String, dynamic>? _extractDataObject(dynamic response) {
    if (response is Map) {
      if (response['payload'] is Map && response['payload']['datas'] is Map) {
        return Map<String, dynamic>.from(response['payload']['datas'] as Map);
      }
      if (response['datas'] is Map) {
        return Map<String, dynamic>.from(response['datas'] as Map);
      }
      return Map<String, dynamic>.from(response);
    }
    return null;
  }

  // Fetch all levels for the current section
  Future<void> _fetchLevelsForSection() async {
    try {
      final apiService = ApiService();

      // Get the section slug from sections list
      if (_sectionsList.isEmpty) {
        final sectionsResult = await apiService.getSections();
        if (sectionsResult['success']) {
          final sectionsResponse = sectionsResult['data'];
          List<dynamic> sectionsData = [];

          if (sectionsResponse is Map &&
              sectionsResponse['payload'] is Map &&
              sectionsResponse['payload']['datas'] is List) {
            sectionsData = sectionsResponse['payload']['datas'];
          } else if (sectionsResponse is List) {
            sectionsData = sectionsResponse;
          }

          for (var i = 0; i < sectionsData.length; i++) {
            final section = sectionsData[i] is Map<String, dynamic>
                ? sectionsData[i]
                : Map<String, dynamic>.from(sectionsData[i] as Map);
            _sectionsList.add({
              'id': section['id'],
              'nama': section['nama'] ?? '',
              'slug': section['slug'] ?? 'section-${i + 1}',
              'sectionNumber': i + 1,
            });
          }
        }
      }

      // Find current section
      final currentSection = _sectionsList.firstWhere(
        (s) => s['sectionNumber'] == _selectedSectionNumber,
        orElse: () => {'slug': 'section-1'},
      );

      final sectionSlug = currentSection['slug'] as String;

      // Fetch levels for this section
      final levelsResult = await apiService.getLevelsBySection(sectionSlug);

      if (levelsResult['success']) {
        final levelsResponse = levelsResult['data'];
        List<dynamic> levelsData = [];

        if (levelsResponse is Map &&
            levelsResponse['payload'] is Map &&
            levelsResponse['payload']['datas'] is List) {
          levelsData = levelsResponse['payload']['datas'];
        } else if (levelsResponse is List) {
          levelsData = levelsResponse;
        }

        List<Map<String, dynamic>> parsedLevels = [];
        for (var i = 0; i < levelsData.length; i++) {
          final level = levelsData[i] is Map<String, dynamic>
              ? levelsData[i]
              : Map<String, dynamic>.from(levelsData[i] as Map);
          parsedLevels.add({
            'id': level['id'],
            'nama': level['nama'] ?? 'Level ${i + 1}',
            'levelNumber': i + 1,
          });
        }

        // Sort levels by id ascending to ensure Level 1 is index 0, Level 2 is index 1, etc.
        parsedLevels.sort((a, b) {
          final aId = a['id'] is int ? a['id'] as int : int.tryParse(a['id']?.toString() ?? '') ?? 0;
          final bId = b['id'] is int ? b['id'] as int : int.tryParse(b['id']?.toString() ?? '') ?? 0;
          return aId.compareTo(bId);
        });

        // Reassign levelNumber based on sorted order
        for (var i = 0; i < parsedLevels.length; i++) {
          parsedLevels[i]['levelNumber'] = i + 1;
        }

        setState(() {
          _levelsList = parsedLevels;
          // Find current level index by level id first.
          _currentLevelIndex = parsedLevels.indexWhere(
            (l) => l['id'] == _currentLevelId,
          );
          if (_currentLevelIndex == -1) {
            _currentLevelIndex = 0;
          }
          if (_levelsList.isNotEmpty) {
            _currentLevelId = _levelsList[_currentLevelIndex]['id'];
          }
        });

        debugPrint(
          'Fetched ${_levelsList.length} levels for section $_selectedSectionNumber',
        );
        debugPrint('Current level index: $_currentLevelIndex');
      }
    } catch (e) {
      debugPrint('Error fetching levels: $e');
    }
  }

  // Navigate to previous level
  void _previousLevel() async {
    if (_levelsList.isEmpty || _currentLevelIndex <= 0) {
      debugPrint('Cannot navigate to previous level');
      return;
    }

    final previousLevelIndex = _currentLevelIndex - 1;
    final previousLevel = _levelsList[previousLevelIndex];

    setState(() {
      _currentLevelIndex = previousLevelIndex;
      _currentLevelId = previousLevel['id']; // Update current level ID
      _selectedSection =
          'Section $_selectedSectionNumber, ${previousLevel['nama']}';
      // Clear old data
      _attemptData = null;
      _soals = [];
      _errorMessage = null;
    });

    debugPrint(
      'Navigating to previous level: ${previousLevel['nama']} (ID: ${previousLevel['id']})',
    );

    // Reload data for previous level
    _loadLevelData();
  }

  // Navigate to next level
  void _nextLevel() async {
    if (_levelsList.isEmpty || _currentLevelIndex >= _levelsList.length - 1) {
      debugPrint('Cannot navigate to next level');
      return;
    }

    final nextLevelIndex = _currentLevelIndex + 1;
    final nextLevel = _levelsList[nextLevelIndex];

    setState(() {
      _currentLevelIndex = nextLevelIndex;
      _currentLevelId = nextLevel['id']; // Update current level ID
      _selectedSection =
          'Section $_selectedSectionNumber, ${nextLevel['nama']}';
      // Clear old data
      _attemptData = null;
      _soals = [];
      _errorMessage = null;
    });

    debugPrint(
      'Navigating to next level: ${nextLevel['nama']} (ID: ${nextLevel['id']})',
    );

    // Reload data for next level
    _loadLevelData();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: Colors.white,
        body: const Center(child: CircularProgressIndicator()),
        bottomNavigationBar: BottomNavBar(currentIndex: _currentBottomNavIndex),
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
                    _errorMessage ?? 'Review belum tersedia karena soal belum dikerjakan',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      color: Colors.grey[700],
                    ),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const HomeView(),
                        ),
                      );
                    },
                    icon: const Icon(Icons.home),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2977FF),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 32,
                        vertical: 12,
                      ),
                    ),
                    label: Text(
                      'Kembali ke Beranda',
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
        bottomNavigationBar: BottomNavBar(currentIndex: _currentBottomNavIndex),
      );
    }
    return Theme(
      data: Theme.of(context).copyWith(
        textTheme: GoogleFonts.interTextTheme(Theme.of(context).textTheme),
      ),
      child: Scaffold(
        backgroundColor: Colors.white,
        body: SafeArea(
          child: SingleChildScrollView(
            child: Column(
              children: [
              dropdown_widget.SectionDropdownButton(
                selectedSection: _selectedSection,
                selectedTitle: _selectedTitle,
                isDropdownOpen: _isDropdownOpen,
                sectionNumber: _selectedSectionNumber,
                onToggleDropdown: () {
                  setState(() {
                    _isDropdownOpen = !_isDropdownOpen;
                  });
                },
                onSelectSection: (section, title, number) async {
                  debugPrint(
                    '=== Section selected: $number, Title: $title ===',
                  );
                  setState(() {
                    _selectedSection = section;
                    _selectedTitle = title;
                    _selectedSectionNumber = number;
                    _isDropdownOpen = false;
                    // Clear old data immediately when section changes
                    _attemptData = null;
                    _soals = [];
                    _errorMessage = null;
                    _currentLevelIndex = 0;
                    _currentLevelId = null;
                  });
                  // Reload data untuk section yang dipilih
                  await _fetchLevelsForSection();
                  _loadLevelData();
                },
              ),

              const SizedBox(height: 24),

              HeaderSection(
                selectedSection: _selectedSection,
                selectedTitle: _selectedTitle,
                onNextSection: _nextLevel, // Changed to level navigation
                onPreviousLevel:
                    _previousLevel, // Added previous level navigation
                score: _attemptData != null
                    ? (_attemptData!['skor'] as num?)?.toDouble()
                    : null,
                hasAttempt: _attemptData != null,
                sectionNumber: _selectedSectionNumber,
                canNavigatePrevious:
                    _levelsList.isNotEmpty && _currentLevelIndex > 0,
                canNavigateNext:
                    _levelsList.isNotEmpty &&
                    _currentLevelIndex < _levelsList.length - 1,
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

                        // Get feedback from API - prioritize AI feedback, then admin name
                        String feedback = 'Dinilai otomatis oleh AI';
                        if (jawabanEsai != null) {
                          // If there's AI feedback, use it
                          if (jawabanEsai['feedback'] != null &&
                              jawabanEsai['feedback']
                                  .toString()
                                  .trim()
                                  .isNotEmpty) {
                            feedback = jawabanEsai['feedback'].toString();
                          }
                          // If admin graded it, show admin name
                          else if (jawabanEsai['admins'] != null) {
                            feedback =
                                'Dinilai oleh: ${jawabanEsai['admins']['nama'] ?? 'Admin'}';
                          }
                        }

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
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.assignment_late_outlined,
                        size: 60,
                        color: Colors.grey[400],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Review Belum Tersedia',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.inter(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Kamu belum mengerjakan quiz untuk level ini.',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),

              const SizedBox(height: 30),
            ],
          ),
        ),
        ),
        bottomNavigationBar: BottomNavBar(currentIndex: _currentBottomNavIndex),
      ),
    );
  }
}
