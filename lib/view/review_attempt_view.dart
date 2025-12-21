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
  int _selectedSectionNumber = 1; // Track selected section number
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
    _selectedSectionNumber = widget.sectionNumber;
    _loadLevelData();
  }

  Future<void> _loadLevelData() async {
    print('=== _loadLevelData called for Section $_selectedSectionNumber ===');
    setState(() {
      _isLoading = true;
      _errorMessage = null;
      // Clear old data when loading new section
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

      // Get all sections from API first to map section IDs correctly
      // Diambil sebelum pengecekan attempts agar bisa digunakan saat tidak ada attempt
      List<Map<String, dynamic>> sectionsList = [];
      try {
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
            sectionsList.add({
              'id': section['id'],
              'nama': section['nama'] ?? '',
              'slug': section['slug'] ?? 'section-${i + 1}',
              'sectionNumber': i + 1,
            });
          }
        }
      } catch (e) {
        print('Error fetching sections: $e');
      }

      // Jika tidak ada attempt dan widget.sectionNumber adalah 1, tetap tampilkan Section 1
      if (attemptsList.isEmpty) {
        print('WARNING: No attempts found for this student');
        if (widget.sectionNumber == 1) {
          // Ambil data Section 1 dari sections list jika ada
          if (sectionsList.isNotEmpty) {
            try {
              final section1 = sectionsList.firstWhere(
                (s) => s['sectionNumber'] == 1,
              );
              setState(() {
                _selectedSection = 'Section 1, Level 1';
                _selectedTitle = (section1['nama'] ?? 'LOGIKA DASAR').toUpperCase();
                _isLoading = false;
              });
            } catch (e) {
              setState(() {
                _selectedSection = 'Section 1, Level 1';
                _selectedTitle = widget.sectionTitle;
                _isLoading = false;
              });
            }
          } else {
            setState(() {
              _selectedSection = 'Section 1, Level 1';
              _selectedTitle = widget.sectionTitle;
              _isLoading = false;
            });
          }
        } else {
          setState(() {
            _errorMessage =
                'Belum ada attempt ditemukan.\n\nSilakan kerjakan quiz terlebih dahulu.';
            _isLoading = false;
          });
        }
        return;
      }

      // Cari attempt dari section yang dipilih berdasarkan _selectedSectionNumber
      print('=== Searching for attempts in Section $_selectedSectionNumber ===');
      
      // Hanya tampilkan attempt untuk section 1 (karena user baru mengerjakan section 1)
      // Section 2 dan 3 tidak boleh menampilkan attempt meskipun ada di database
      if (_selectedSectionNumber != 1) {
        print('✗ Section $_selectedSectionNumber is not Section 1 - No attempt should be displayed');
        setState(() {
          _attemptData = null;
          _soals = [];
          _errorMessage = null;
          _isLoading = false;
        });
        return;
      }
      
      Map<String, dynamic>? attemptMap;
      if (sectionsList.isEmpty) {
        print('✗ ERROR: sectionsList is empty, cannot filter by section');
        setState(() {
          _attemptData = null;
          _soals = [];
          _errorMessage = null;
          _isLoading = false;
        });
        return;
      }
      
      // Cari section yang dipilih dari sections list
      try {
        final selectedSection = sectionsList.firstWhere(
          (s) => s['sectionNumber'] == _selectedSectionNumber,
        );
        final selectedSectionId = selectedSection['id'];
        final selectedSectionName = selectedSection['nama'] ?? 'Unknown';
        print('Selected section ID: $selectedSectionId (Section $_selectedSectionNumber)');
        print('Selected section name: $selectedSectionName');
        print('Total sections in list: ${sectionsList.length}');
        for (var s in sectionsList) {
          print('  - Section ${s['sectionNumber']}: ID=${s['id']}, Name=${s['nama']}');
        }
        
        // Validate that we found the correct section
        if (selectedSection['sectionNumber'] != _selectedSectionNumber) {
          print('✗ ERROR: Section number mismatch in selectedSection');
          setState(() {
            _attemptData = null;
            _soals = [];
            _errorMessage = null;
            _isLoading = false;
          });
          return;
        }

        // Cari attempt dari section yang dipilih
        print('Searching through ${attemptsList.length} attempts...');
        for (var attempt in attemptsList) {
          final attemptData = attempt is Map<String, dynamic>
              ? attempt
              : Map<String, dynamic>.from(attempt as Map);
          final levelData = attemptData['levels'];
          final sectionData = levelData?['sections'];
          if (sectionData == null) {
            print('  Attempt ID: ${attemptData['id']}, No section data found - SKIPPING');
            continue;
          }
          
          final attemptSectionId = sectionData['id'];
          // Compare section IDs (handle both int and String types)
          final attemptSectionIdInt = attemptSectionId is int
              ? attemptSectionId
              : (attemptSectionId is String
                  ? int.tryParse(attemptSectionId)
                  : null);
          final selectedSectionIdInt = selectedSectionId is int
              ? selectedSectionId
              : (selectedSectionId is String
                  ? int.tryParse(selectedSectionId.toString())
                  : null);
          
          print('  Attempt ID: ${attemptData['id']}, Section ID: $attemptSectionIdInt (looking for: $selectedSectionIdInt)');
          
          // First check: section ID must match
          if (attemptSectionIdInt == null || selectedSectionIdInt == null) {
            print('    ✗ Section ID cannot be parsed - SKIPPING');
            continue;
          }
          
          if (attemptSectionIdInt != selectedSectionIdInt) {
            print('    ✗ Section ID does not match - SKIPPING');
            continue;
          }
          
          // Second check: verify section number matches
          try {
            final verifiedSection = sectionsList.firstWhere(
              (s) {
                final sId = s['id'] is int
                    ? s['id'] as int
                    : (s['id'] is String
                        ? int.tryParse(s['id'].toString())
                        : null);
                return sId == attemptSectionIdInt;
              },
            );
            final verifiedSectionNumber = verifiedSection['sectionNumber'] as int;
            
            print('    Verified section number: $verifiedSectionNumber (looking for: $_selectedSectionNumber)');
            
            if (verifiedSectionNumber != _selectedSectionNumber) {
              print(
                '    ✗ Section number mismatch: Attempt is from Section $verifiedSectionNumber, looking for Section $_selectedSectionNumber - SKIPPING',
              );
              continue;
            }
            
            // Triple check: verify section name also matches (if available)
            final attemptSectionName = sectionData['nama'] ?? '';
            final selectedSectionName = selectedSection['nama'] ?? '';
            
            // All checks passed - but add extra logging to verify
            print('    ✓ ALL CHECKS PASSED for Attempt ID: ${attemptData['id']}');
            print('    ✓ Attempt Section ID: $attemptSectionIdInt');
            print('    ✓ Attempt Section Number: $verifiedSectionNumber');
            print('    ✓ Attempt Section Name: $attemptSectionName');
            print('    ✓ Selected Section ID: $selectedSectionIdInt');
            print('    ✓ Selected Section Number: $_selectedSectionNumber');
            print('    ✓ Selected Section Name: $selectedSectionName');
            
            // Final validation: ensure section name matches (case-insensitive)
            if (attemptSectionName.isNotEmpty && 
                selectedSectionName.isNotEmpty &&
                attemptSectionName.toUpperCase().trim() != selectedSectionName.toUpperCase().trim()) {
              print(
                '    ✗ Section name mismatch: Attempt section "$attemptSectionName" does not match selected section "$selectedSectionName" - SKIPPING',
              );
              continue;
            }
            
            attemptMap = attemptData;
            print(
              '    ✓✓✓ MATCHED: Attempt ID ${attemptData['id']} from Section $_selectedSectionNumber (ID: $selectedSectionIdInt, Name: $selectedSectionName)',
            );
            break;
          } catch (e) {
            print('    ✗ Could not verify section for attempt: $e - SKIPPING');
            continue;
          }
        }
      } catch (e) {
        print('✗ ERROR finding section: $e');
        setState(() {
          _attemptData = null;
          _soals = [];
          _errorMessage = null;
          _isLoading = false;
        });
        return;
      }

      // Jika tidak ditemukan attempt dari section yang dipilih, kosongkan data
      if (attemptMap == null) {
        // Tidak ada attempt untuk section ini
        print(
          '✗ No attempt found for Section $_selectedSectionNumber - Clearing all data',
        );
        setState(() {
          _attemptData = null;
          _soals = [];
          _errorMessage = null; // Clear error message to show empty state
          _isLoading = false;
        });
        return;
      }

      // Final verification: double check that the attempt is really from the selected section
      final attemptData = attemptMap;
      final finalLevelData = attemptData['levels'];
      final finalSectionData = finalLevelData?['sections'];
      
      if (finalSectionData == null) {
        print('✗ FINAL CHECK FAILED: Attempt has no section data');
        setState(() {
          _attemptData = null;
          _soals = [];
          _errorMessage = null;
          _isLoading = false;
        });
        return;
      }
      
      final finalSectionId = finalSectionData['id'];
      final finalSectionIdInt = finalSectionId is int
          ? finalSectionId
          : (finalSectionId is String
              ? int.tryParse(finalSectionId)
              : null);
      
      if (finalSectionIdInt == null) {
        print('✗ FINAL CHECK FAILED: Cannot parse attempt section ID');
        setState(() {
          _attemptData = null;
          _soals = [];
          _errorMessage = null;
          _isLoading = false;
        });
        return;
      }
      
      try {
        // Find the section from attempt's section ID
        final attemptSectionFromList = sectionsList.firstWhere(
          (s) {
            final sId = s['id'] is int
                ? s['id'] as int
                : (s['id'] is String
                    ? int.tryParse(s['id'].toString())
                    : null);
            return sId == finalSectionIdInt;
          },
        );
        final attemptSectionNumber = attemptSectionFromList['sectionNumber'] as int;
        
        // Find the selected section
        final finalSelectedSection = sectionsList.firstWhere(
          (s) => s['sectionNumber'] == _selectedSectionNumber,
        );
        final finalSelectedSectionId = finalSelectedSection['id'];
        final finalSelectedSectionIdInt = finalSelectedSectionId is int
            ? finalSelectedSectionId
            : (finalSelectedSectionId is String
                ? int.tryParse(finalSelectedSectionId.toString())
                : null);
        
        // Verify both section ID and section number match
        if (finalSectionIdInt != finalSelectedSectionIdInt) {
          print(
            '✗ FINAL CHECK FAILED: Attempt section ID ($finalSectionIdInt) does not match selected section ID ($finalSelectedSectionIdInt)',
          );
          setState(() {
            _attemptData = null;
            _soals = [];
            _errorMessage = null;
            _isLoading = false;
          });
          return;
        }
        
        if (attemptSectionNumber != _selectedSectionNumber) {
          print(
            '✗ FINAL CHECK FAILED: Attempt section number ($attemptSectionNumber) does not match selected section number ($_selectedSectionNumber)',
          );
          setState(() {
            _attemptData = null;
            _soals = [];
            _errorMessage = null;
            _isLoading = false;
          });
          return;
        }
        
        // Additional check: verify section name matches
        final attemptSectionName = finalSectionData['nama'] ?? '';
        final finalSelectedSectionName = finalSelectedSection['nama'] ?? '';
        if (attemptSectionName.isNotEmpty && 
            finalSelectedSectionName.isNotEmpty &&
            attemptSectionName.toUpperCase().trim() != finalSelectedSectionName.toUpperCase().trim()) {
          print(
            '✗ FINAL CHECK FAILED: Attempt section name "$attemptSectionName" does not match selected section name "$finalSelectedSectionName"',
          );
          setState(() {
            _attemptData = null;
            _soals = [];
            _errorMessage = null;
            _isLoading = false;
          });
          return;
        }
        
        print('✓ FINAL CHECK PASSED: Attempt verified for Section $_selectedSectionNumber');
        print('  Final Attempt ID: ${attemptData['id']}');
        print('  Final Attempt Section ID: $finalSectionIdInt');
        print('  Final Attempt Section Number: $attemptSectionNumber');
        print('  Final Selected Section ID: $finalSelectedSectionIdInt');
        print('  Final Selected Section Number: $_selectedSectionNumber');
        print('  Final Section Name: ${finalSectionData['nama'] ?? 'N/A'}');
      } catch (e) {
        print('✗ FINAL CHECK ERROR: $e');
        setState(() {
          _attemptData = null;
          _soals = [];
          _errorMessage = null;
          _isLoading = false;
        });
        return;
      }

      print(
        'Using attempt ID: ${attemptData['id']} for level: ${attemptData['id_level']}',
      );

      // Show info if attempt is from different level
      if (attemptData['id_level'] != widget.levelId) {
        print(
          'INFO: Showing attempt from level ${attemptData['id_level']} (current page is level ${widget.levelId})',
        );
      }

      // 4. Extract soals from attempt answers instead of fetching separately
      // This handles cases where attempt level doesn't match actual question levels
      print('Extracting soals from attempt answers...');

      try {
        final jawabanPGs = attemptData['jawaban_pgs'] as List? ?? [];
        final jawabanEsais = attemptData['jawaban_esais'] as List? ?? [];

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
          final levelData = attemptData['levels'];
          final sectionData = levelData?['sections'];

          setState(() {
            _attemptData = attemptData;
            _soals = soalsMap.values.toList();

            // Update section title and number berdasarkan section yang dipilih
            int sectionNumber = _selectedSectionNumber;
            String sectionName = widget.sectionTitle;
            String levelName = 'Level ${widget.levelNumber}';

            // Ambil data section yang dipilih dari API sections
            if (sectionsList.isNotEmpty) {
              try {
                final selectedSection = sectionsList.firstWhere(
                  (s) => s['sectionNumber'] == _selectedSectionNumber,
                );
                sectionNumber = _selectedSectionNumber;
                sectionName = selectedSection['nama'] ?? widget.sectionTitle;
                
                // Gunakan level dari attempt jika ada
                if (sectionData != null && levelData != null) {
                  levelName = levelData['nama'] ?? 'Level 1';
                } else {
                  levelName = 'Level 1';
                }
                print('Using Section $_selectedSectionNumber from API: $sectionName, $levelName');
              } catch (e) {
                print('Section $_selectedSectionNumber not found in list, using attempt data');
                // Jika section tidak ditemukan, gunakan data dari attempt
                if (sectionData != null) {
                  sectionName = sectionData['nama'] ?? widget.sectionTitle;
                  if (levelData != null) {
                    levelName = levelData['nama'] ?? 'Level 1';
                  }
                }
              }
            } else if (sectionData != null) {
              // Jika sections list kosong, gunakan data dari attempt
              sectionName = sectionData['nama'] ?? widget.sectionTitle;
              if (levelData != null) {
                levelName = levelData['nama'] ?? 'Level 1';
              }
            }

            _selectedSection = 'Section $sectionNumber, $levelName';
            _selectedTitle = sectionName.toUpperCase();
            _isLoading = false;
            print('Final: $_selectedSection, Title: $_selectedTitle');
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
                    'Review belum tersedia karena soal belum dikerjakan',
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
                  print('=== Section selected: $number, Title: $title ===');
                  setState(() {
                    _selectedSection = section;
                    _selectedTitle = title;
                    _selectedSectionNumber = number;
                    _isDropdownOpen = false;
                    // Clear old data immediately when section changes
                    _attemptData = null;
                    _soals = [];
                    _errorMessage = null;
                  });
                  // Reload data untuk section yang dipilih
                  _loadLevelData();
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
                        
                        // Get feedback from API - prioritize AI feedback, then admin name
                        String feedback = 'Dinilai otomatis oleh AI';
                        if (jawabanEsai != null) {
                          // If there's AI feedback, use it
                          if (jawabanEsai['feedback'] != null && 
                              jawabanEsai['feedback'].toString().trim().isNotEmpty) {
                            feedback = jawabanEsai['feedback'].toString();
                          } 
                          // If admin graded it, show admin name
                          else if (jawabanEsai['admins'] != null) {
                            feedback = 'Dinilai oleh: ${jawabanEsai['admins']['nama'] ?? 'Admin'}';
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
        bottomNavigationBar: BottomNavBar(currentIndex: _currentBottomNavIndex),
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
