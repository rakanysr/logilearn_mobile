import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:logilearn/services/api_service.dart';
import 'package:logilearn/services/auth_service.dart';
import 'package:logilearn/view/login_view.dart';
import 'package:logilearn/view/quiz_view.dart';
import 'package:logilearn/widget/bottombar.dart';

class HomeView extends StatefulWidget {
  const HomeView({super.key});

  @override
  State<HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends State<HomeView> {
  bool _isDropdownOpen = false;
  int _selectedSectionIndex = 0;
  final int _currentBottomNavIndex = 0;
  String? _username;
  bool _isLoading = true;

  List<Map<String, dynamic>> _sections = [];
  List<Map<String, dynamic>> _levels = [];
  final _storage = const FlutterSecureStorage();

  // Default Sections (Fallback)
  final List<Map<String, dynamic>> _defaultSections = [
    {
      'section': 'SECTION 1',
      'title': 'LOGIKA DASAR',
      'color': const Color(0xFF2F80ED),
      'image': 'assets/images/Mascot halo.png',
      'unlockedLevel': 0,
      'completedLevels': 0, // Jumlah level yang sudah diselesaikan
      'levelScores': <int>[], // Explicit type
      'totalLevels': 10,
    },
    {
      'section': 'SECTION 2',
      'title': 'LOGIKA PEMROGRAMAN',
      'color': const Color(0xFF2D9CDB),
      'image': 'assets/images/Mascot banyak.png',
      'unlockedLevel': 0,
      'completedLevels': 0, // Jumlah level yang sudah diselesaikan
      'levelScores': <int>[], // Explicit type
      'totalLevels': 10,
    },
    {
      'section': 'SECTION 3',
      'title': 'LOGIKA SILOGISME',
      'color': const Color(0xFF27AE60),
      'image': 'assets/images/Mascot buntung.png',
      'unlockedLevel': 0,
      'completedLevels': 0, // Jumlah level yang sudah diselesaikan
      'levelScores': <int>[], // Explicit type
      'totalLevels': 10,
    },
  ];

  @override
  void initState() {
    super.initState();
    _loadUserData();
    _fetchSections();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Refresh unlock status when returning to this screen
    if (_sections.isNotEmpty) {
      print('HomeView: didChangeDependencies - refreshing unlock status');
      _updateUnlockedLevels();
    }
  }

  Future<void> _loadUserData() async {
    final name = await _storage.read(key: 'nama_pelajar');
    if (mounted) {
      setState(() {
        _username = name ?? 'Teman';
      });
    }
  }

  Future<void> _fetchSections() async {
    setState(() {
      _isLoading = true;
    });

    final apiService = ApiService();
    final result = await apiService.getSections();

    if (result['success']) {
      final fullResponse = result['data'];
      List<dynamic> sectionsList = [];

      // Parsing the specific structure from helpers/response.js
      // Structure: { payload: { datas: [...] } }
      if (fullResponse is Map &&
          fullResponse['payload'] is Map &&
          fullResponse['payload']['datas'] is List) {
        sectionsList = fullResponse['payload']['datas'];
      } else if (fullResponse is List) {
        // Fallback if structure changes
        sectionsList = fullResponse;
      }

      if (sectionsList.isNotEmpty) {
        try {
          final List<Map<String, dynamic>> parsedSections = [];

          for (var i = 0; i < sectionsList.length; i++) {
            final item = sectionsList[i];

            // Color Assignment based on index
            Color sectionColor;
            if (i % 3 == 0)
              sectionColor = const Color(0xFF2F80ED);
            else if (i % 3 == 1)
              sectionColor = const Color(0xFF2D9CDB);
            else
              sectionColor = const Color(0xFF27AE60);

            // Image Assignment based on index
            String imageAsset;
            if (i % 3 == 0)
              imageAsset = 'assets/images/Mascot halo.png';
            else if (i % 3 == 1)
              imageAsset = 'assets/images/Mascot banyak.png';
            else
              imageAsset = 'assets/images/Mascot buntung.png';

            // Unlocked Level Logic
            // Semua section bisa dikerjakan dari awal tanpa harus menyelesaikan section sebelumnya
            // Setiap section di-unlock level 1 secara default
            int unlocked = 1;

            // Levels parsing
            List<dynamic> levels = [];
            if (item['levels'] is List) {
              levels = item['levels'];
            }
            // Calculate total levels from backend data
            int totalLev = levels.isNotEmpty ? levels.length : 10;

            // Generate empty scores for now
            List<int> scores = [];

            parsedSections.add({
              'section': 'SECTION ${i + 1}',
              'title': item['nama'] ?? 'LOGIKA',
              'color': sectionColor,
              'image': imageAsset,
              'unlockedLevel': unlocked,
              'completedLevels': 0, // Jumlah level yang sudah diselesaikan
              'levelScores': scores,
              'totalLevels': totalLev,
              'slug': item['slug'] ?? 'section-${i + 1}',
              'id': item['id'],
            });
          }

          _sections = parsedSections;

          // Load levels for the first section and unlock based on attempts
          if (_sections.isNotEmpty) {
            final firstSection = _sections[0];
            final slugSection = firstSection['slug'] as String? ?? 'section-1';
            await _loadLevelsForSection(slugSection);
            await _updateUnlockedLevels(); // Update unlock status based on attempts
          }
        } catch (e) {
          print("Error parsing sections: $e");
          _useDefaultSections();
        }
      } else {
        _useDefaultSections();
      }
    } else {
      _useDefaultSections();
    }

    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _useDefaultSections() {
    _sections = List.from(_defaultSections);
    // Semua section bisa dikerjakan dari awal - unlock level 1 untuk semua section
    for (var i = 0; i < _sections.length; i++) {
      final section = Map<String, dynamic>.from(_sections[i]);
      // Setiap section di-unlock level 1 secara default
      if ((section['unlockedLevel'] as int) < 1) {
        section['unlockedLevel'] = 1;
      }
      section['slug'] = 'section-${i + 1}';
      section['id'] = i + 1;
      section['completedLevels'] = 0; // Initialize completed levels
      _sections[i] = section;
    }

    // Load levels for the first section
    if (_sections.isNotEmpty) {
      final firstSection = _sections[0];
      final slugSection = firstSection['slug'] as String? ?? 'section-1';
      _loadLevelsForSection(slugSection);
    }
  }

  void _logout() async {
    final authService = AuthService();
    await authService.logout();
    if (mounted) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const LoginView()),
        (route) => false,
      );
    }
  }

  Future<void> _loadLevelsForSection(String slugSection) async {
    print('_loadLevelsForSection called with slug: $slugSection');
    final apiService = ApiService();
    final result = await apiService.getLevelsBySection(slugSection);

    print('getLevelsBySection result success: ${result['success']}');

    if (result['success']) {
      final fullResponse = result['data'];
      List<dynamic> levelsList = [];

      // Parse response structure from helpers/response.js
      // Structure: { payload: { datas: [...] } }
      if (fullResponse is Map &&
          fullResponse['payload'] is Map &&
          fullResponse['payload']['datas'] is List) {
        levelsList = fullResponse['payload']['datas'];
        print('Parsed levels from payload.datas: ${levelsList.length}');
      } else if (fullResponse is Map && fullResponse['datas'] is List) {
        levelsList = fullResponse['datas'];
        print('Parsed levels from datas: ${levelsList.length}');
      } else if (fullResponse is List) {
        levelsList = fullResponse;
        print('Parsed levels from direct list: ${levelsList.length}');
      }

      if (mounted) {
        setState(() {
          _levels = levelsList.map<Map<String, dynamic>>((level) {
            final levelMap = level is Map<String, dynamic>
                ? level
                : (level is Map
                      ? Map<String, dynamic>.from(level)
                      : <String, dynamic>{});
            return {'id': levelMap['id'], 'nama': levelMap['nama'] ?? 'Level'};
          }).toList();

          // Sort levels by id to ensure consistent ordering
          _levels.sort((a, b) => (a['id'] as int).compareTo(b['id'] as int));

          print('Loaded ${_levels.length} levels into state:');
          for (var i = 0; i < _levels.length; i++) {
            print(
              '  Index $i: id=${_levels[i]['id']}, nama=${_levels[i]['nama']}',
            );
          }
        });
      }
    } else {
      print('Failed to load levels: ${result['message']}');
    }
  }

  Future<void> _updateUnlockedLevels() async {
    print('========================================');
    print('_updateUnlockedLevels called');
    final apiService = ApiService();

    // Get pelajar ID from storage
    final pelajarIdStr = await _storage.read(key: 'id_pelajar');
    print('Pelajar ID from storage: $pelajarIdStr');

    if (pelajarIdStr == null) {
      print('No pelajar ID found in storage');
      // Default: unlock level 1 untuk semua section
      if (_sections.isNotEmpty && mounted) {
        setState(() {
          for (var i = 0; i < _sections.length; i++) {
            _sections[i]['unlockedLevel'] = 1;
            _sections[i]['completedLevels'] = 0;
          }
        });
      }
      return;
    }

    final pelajarId = int.tryParse(pelajarIdStr);
    if (pelajarId == null) {
      print('Invalid pelajar ID: $pelajarIdStr');
      return;
    }

    print('Fetching attempts for pelajar ID: $pelajarId');

    // Get user's attempts to determine progress
    final result = await apiService.getAttemptsByPelajarId(pelajarId);

    if (result['success']) {
      final fullResponse = result['data'];
      List<dynamic> attemptsList = [];

      // Parse response structure: { payload: { datas: [...] } }
      if (fullResponse is Map &&
          fullResponse['payload'] is Map &&
          fullResponse['payload']['datas'] is List) {
        attemptsList = fullResponse['payload']['datas'];
      } else if (fullResponse is List) {
        attemptsList = fullResponse;
      }

      print('Found ${attemptsList.length} attempts');

      // Create a map to track the highest completed level for each section (with score >= 75)
      Map<int, int> sectionMaxLevels = {};
      // Create a map to track completed level IDs per section (to count unique completed levels with score >= 75)
      Map<int, Set<int>> sectionCompletedLevelIds = {};

      // Process all attempts to find the highest level completed per section
      for (var attempt in attemptsList) {
        try {
          // Structure: attempt['levels']['sections']['id'] = section ID
          // Structure: attempt['levels']['id'] = level ID
          // Structure: attempt['skor'] = score (0-100)
          if (attempt['levels'] != null &&
              attempt['levels']['sections'] != null) {
            final sectionId = attempt['levels']['sections']['id'] as int;
            final levelId = attempt['levels']['id'] as int;

            // Get the score from the attempt
            final skor = attempt['skor'] != null
                ? (attempt['skor'] is num
                      ? (attempt['skor'] as num).toDouble()
                      : 0.0)
                : 0.0;

            print(
              'Attempt: sectionId=$sectionId, levelId=$levelId, skor=$skor',
            );

            // Hanya menghitung attempts dengan score >= 75 sebagai completed
            // Progress bar akan bertambah hanya jika user mendapatkan nilai >= 75
            if (skor >= 75.0) {
              // Track the highest level ID for this section
              if (!sectionMaxLevels.containsKey(sectionId) ||
                  levelId > sectionMaxLevels[sectionId]!) {
                sectionMaxLevels[sectionId] = levelId;
              }

              // Track unique completed level IDs for progress calculation
              // Set ini digunakan untuk menghitung jumlah level yang sudah diselesaikan dengan score >= 75
              if (!sectionCompletedLevelIds.containsKey(sectionId)) {
                sectionCompletedLevelIds[sectionId] = <int>{};
              }
              sectionCompletedLevelIds[sectionId]!.add(levelId);
            } else {
              print('  Score $skor is below 75, not counting as completed');
            }
          }
        } catch (e) {
          print('Error processing attempt: $e');
        }
      }

      print('Section max levels: $sectionMaxLevels');
      print('Section completed level IDs: $sectionCompletedLevelIds');

      // Now update each section's unlocked level
      for (var i = 0; i < _sections.length; i++) {
        final section = _sections[i];
        final sectionId = section['id'] as int?;
        final sectionSlug = section['slug'] as String?;

        if (sectionId == null || sectionSlug == null) {
          print('Section $i has no ID or slug, skipping');
          continue;
        }

        // Default: unlock level 1 untuk semua section (semua section bisa dikerjakan dari awal)
        int unlockedLevel = 1;
        // Jumlah level yang sudah diselesaikan dengan score >= 75
        // Progress bar akan bertambah berdasarkan nilai ini
        int completedLevels = 0;

        // If this section has completed attempts, unlock the next level
        if (sectionMaxLevels.containsKey(sectionId)) {
          // Calculate completed levels count (hanya level dengan score >= 75)
          // Set sectionCompletedLevelIds berisi unique level IDs yang sudah diselesaikan dengan score >= 75
          if (sectionCompletedLevelIds.containsKey(sectionId)) {
            completedLevels = sectionCompletedLevelIds[sectionId]!.length;
            print('Section $sectionId: completed $completedLevels levels (score >= 75)');
          }
          // User has completed at least one level in this section
          final maxCompletedLevelId = sectionMaxLevels[sectionId]!;

          // Fetch levels for THIS specific section to find the level index
          final levelsResult = await apiService.getLevelsBySection(sectionSlug);

          if (levelsResult['success']) {
            final levelsResponse = levelsResult['data'];
            List<dynamic> sectionLevelsList = [];

            // Parse levels response
            if (levelsResponse is Map &&
                levelsResponse['payload'] is Map &&
                levelsResponse['payload']['datas'] is List) {
              sectionLevelsList = levelsResponse['payload']['datas'];
            } else if (levelsResponse is List) {
              sectionLevelsList = levelsResponse;
            }

            // Sort levels by ID to ensure correct ordering
            sectionLevelsList.sort((a, b) {
              final aId = a['id'] is int ? a['id'] as int : 0;
              final bId = b['id'] is int ? b['id'] as int : 0;
              return aId.compareTo(bId);
            });

            print(
              'Section $sectionId ($sectionSlug) has ${sectionLevelsList.length} levels',
            );

            // Find the index of the highest completed level
            int completedLevelIndex = -1;
            for (var j = 0; j < sectionLevelsList.length; j++) {
              final levelId = sectionLevelsList[j]['id'] as int;
              if (levelId == maxCompletedLevelId) {
                completedLevelIndex = j;
                print('  Completed level at index $j (id=$levelId)');
                break;
              }
            }

            if (completedLevelIndex != -1) {
              // Unlock the next level after the completed one
              // Level numbers are 1-based, index is 0-based
              // If user completed index 0 (level 1), unlock index 1 (level 2)
              unlockedLevel = completedLevelIndex + 2;

              // Don't unlock more than total levels
              if (unlockedLevel > sectionLevelsList.length) {
                unlockedLevel = sectionLevelsList.length;
              }

              print(
                'Section $sectionId: completed index $completedLevelIndex, unlocking level $unlockedLevel',
              );
            } else {
              // Completed level not found in list? Unlock level 1
              unlockedLevel = 1;
              print(
                'Section $sectionId: completed level not found in list, unlocking level 1',
              );
            }
          } else {
            // Failed to fetch levels, but has attempts - unlock level 1
            unlockedLevel = 1;
            print(
              'Section $sectionId: failed to fetch levels, unlocking level 1',
            );
          }
        }

        // Update the section's unlocked level and completed levels
        // completedLevels hanya menghitung level dengan score >= 75
        // Progress bar akan bertambah berdasarkan nilai completedLevels ini
        if (mounted) {
          setState(() {
            _sections[i]['unlockedLevel'] = unlockedLevel;
            _sections[i]['completedLevels'] = completedLevels;
          });
        }

        print(
          'Section ${i + 1} (id=$sectionId): unlocked up to level $unlockedLevel, completed $completedLevels levels (score >= 75)',
        );
      }

      // Pastikan semua section minimal level 1 terbuka (semua section bisa dikerjakan dari awal)
      if (mounted) {
        setState(() {
          for (var i = 0; i < _sections.length; i++) {
            if ((_sections[i]['unlockedLevel'] as int) < 1) {
              _sections[i]['unlockedLevel'] = 1;
            }
          }
        });
      }

      // Print final summary
      print('========================================');
      print('FINAL UNLOCK STATUS:');
      for (var i = 0; i < _sections.length; i++) {
        print(
          '  Section ${i + 1}: ${_sections[i]['title']} - Unlocked Level: ${_sections[i]['unlockedLevel']}',
        );
      }
      print('========================================');
    } else {
      print('Failed to fetch attempts: ${result['message']}');
      // If we can't fetch attempts, unlock level 1 untuk semua section
      if (_sections.isNotEmpty && mounted) {
        setState(() {
          for (var i = 0; i < _sections.length; i++) {
            _sections[i]['unlockedLevel'] = 1;
            _sections[i]['completedLevels'] = 0;
          }
        });
      }
    }
  }

  void _navigateToLevelDetail(int levelIndex) async {
    if (_sections.isEmpty || _selectedSectionIndex >= _sections.length) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Section tidak ditemukan')));
      return;
    }

    final selectedSection = _sections[_selectedSectionIndex];
    final slugSection =
        selectedSection['slug'] as String? ??
        'section-${_selectedSectionIndex + 1}';

    print('_navigateToLevelDetail called:');
    print('  levelIndex: $levelIndex');
    print('  slugSection: $slugSection');
    print('  _levels.length: ${_levels.length}');

    // Always load levels for this section to ensure we have the latest data
    await _loadLevelsForSection(slugSection);

    // Wait a bit for state to update
    await Future.delayed(const Duration(milliseconds: 100));

    // Check if level exists
    if (levelIndex >= _levels.length || _levels.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Level tidak ditemukan. Total levels: ${_levels.length}',
          ),
        ),
      );
      return;
    }

    final level = _levels[levelIndex];
    // Ensure levelId is int
    final levelId = level['id'] is int
        ? level['id'] as int
        : int.tryParse(level['id'].toString()) ?? 0;
    final sectionTitle = selectedSection['title'] as String;
    final sectionNumber = _selectedSectionIndex + 1;

    print('Navigating to QuizScreen:');
    print('  sectionSlug: $slugSection');
    print('  levelId: $levelId');
    print('  sectionTitle: $sectionTitle');
    print('  sectionNumber: $sectionNumber');
    print('  levelNumber: ${levelIndex + 1}');

    if (levelId == 0) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('ID Level tidak valid')));
      return;
    }

    // Navigate to quiz screen with level data
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => QuizScreen(
          sectionSlug: slugSection,
          levelId: levelId,
          sectionTitle: sectionTitle,
          sectionNumber: sectionNumber,
          levelNumber: levelIndex + 1,
        ),
      ),
    ).then((_) async {
      // Refresh unlock status and progress when returning from quiz
      print('Returned from quiz - refreshing unlock status and progress');
      // Wait a bit to ensure backend has processed the attempt
      await Future.delayed(const Duration(milliseconds: 500));
      await _updateUnlockedLevels();
      // Force rebuild to update progress bar
      if (mounted) {
        setState(() {});
      }
    });
  }

  void _showLockedPopup() {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (_) => Center(
        child: TweenAnimationBuilder<double>(
          tween: Tween(begin: 0.8, end: 1.0),
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOutBack,
          builder: (context, scale, child) {
            return Transform.scale(
              scale: scale,
              child: AlertDialog(
                backgroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                title: Text(
                  "Level Terkunci",
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                content: Text(
                  "Selesaikan level sebelumnya dengan nilai minimal 75 untuk membuka level ini.",
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(color: Colors.black54),
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
                    child: Text(
                      "Oke",
                      style: GoogleFonts.inter(color: Colors.white),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: Colors.white,
        body: Center(child: CircularProgressIndicator()),
      );
    }

    // Ensure we have valid selection index
    if (_selectedSectionIndex >= _sections.length) {
      _selectedSectionIndex = 0;
    }

    final selected = _sections.isNotEmpty
        ? _sections[_selectedSectionIndex]
        : _defaultSections[0];
    final screenWidth = MediaQuery.of(context).size.width;

    // Safely handle types
    int unlocked = 0;
    if (selected['unlockedLevel'] is int) {
      unlocked = selected['unlockedLevel'];
    }

    // Get completed levels count (hanya level dengan score >= 75)
    // completedLevels dihitung di _updateUnlockedLevels() berdasarkan attempts dengan skor >= 75
    int completed = 0;
    if (selected['completedLevels'] is int) {
      completed = selected['completedLevels'];
    }

    // Use actual levels count from backend, or fallback to totalLevels
    int total = _levels.isNotEmpty ? _levels.length : 10;
    if (selected['totalLevels'] is int && _levels.isEmpty) {
      total = selected['totalLevels'];
    }

    // Progress dihitung berdasarkan level yang sudah diselesaikan dengan nilai >= 75
    // Progress bar akan bertambah hanya jika user mendapatkan nilai >= 75 pada level tersebut
    double sectionProgress = total > 0 ? completed / total : 0.0;
    int percentageDisplay = (sectionProgress * 100).toInt();

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Stack(
          children: [
            SingleChildScrollView(
              child: Column(
                children: [
                  Container(
                    width: double.infinity,
                    alignment: Alignment.centerLeft,
                    padding: const EdgeInsets.only(
                      top: 15.0,
                      left: 15.0,
                      right: 15.0,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            'Selamat Datang, ${_username ?? 'Teman'}',
                            style: GoogleFonts.inter(
                              fontSize:
                                  18, // Slightly reduced font size to fit name
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      
                      ],
                    ),
                  ),

                  Container(
                    width: screenWidth,
                    margin: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () {
                          setState(() => _isDropdownOpen = !_isDropdownOpen);
                        },
                        borderRadius: BorderRadius.circular(18),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            vertical: 18,
                            horizontal: 20,
                          ),
                          decoration: BoxDecoration(
                            color: selected['color'] as Color, // Cast to Color
                            borderRadius: BorderRadius.circular(18),
                            boxShadow: [
                              BoxShadow(
                                color: (selected['color'] as Color).withOpacity(
                                  0.3,
                                ),
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
                                    '${selected['section']}',
                                    style: GoogleFonts.inter(
                                      color: Colors.white,
                                      fontSize: 13,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  Text(
                                    '${selected['title']}',
                                    style: GoogleFonts.inter(
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
                    ),
                  ),

                  const SizedBox(height: 20),
                  Image.asset('${selected['image']}', height: 120),
                  const SizedBox(height: 12),

                  // Progress Section
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 40.0),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Progress Belajar',
                              style: GoogleFonts.inter(
                                fontSize: 14,
                                color: Colors.grey[600],
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            Text(
                              '$percentageDisplay%',
                              style: GoogleFonts.inter(
                                fontSize: 14,
                                color: selected['color'] as Color,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: LinearProgressIndicator(
                            value: sectionProgress,
                            minHeight: 10,
                            backgroundColor: Colors.grey[200],
                            color: selected['color'] as Color,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    '${selected['section']}',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      color: Colors.black54,
                    ),
                  ),
                  Text(
                    '${selected['title']}',
                    style: GoogleFonts.inter(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 20.0),
                    child: _levels.isEmpty
                        ? Column(
                            children: [
                              const SizedBox(height: 40),
                              Icon(
                                Icons.info_outline,
                                size: 64,
                                color: Colors.grey[400],
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'Belum Ada Level',
                                style: GoogleFonts.inter(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.grey[700],
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Level untuk section ini belum tersedia',
                                textAlign: TextAlign.center,
                                style: GoogleFonts.inter(
                                  fontSize: 14,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          )
                        : Column(
                            children: List.generate(_levels.length, (index) {
                              // Use actual levels from backend
                              final isUnlocked = index < unlocked;
                              // Handle list safety
                              List scores = [];
                              if (selected['levelScores'] is List) {
                                scores = selected['levelScores'];
                              }

                              final Color sectionColor =
                                  selected['color'] as Color;

                              final dx = (index % 4 == 0)
                                  ? -screenWidth * 0.2
                                  : (index % 4 == 1)
                                  ? 0.0
                                  : (index % 4 == 2)
                                  ? screenWidth * 0.2
                                  : 0.0;

                              return Padding(
                                padding: const EdgeInsets.only(bottom: 20.0),
                                child: Transform.translate(
                                  offset: Offset(dx, 0),
                                  child: GestureDetector(
                                    onTap: () {
                                      if (isUnlocked) {
                                        _navigateToLevelDetail(index);
                                      } else {
                                        _showLockedPopup();
                                      }
                                    },
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Stack(
                                          alignment: Alignment.center,
                                          children: [
                                            Container(
                                              width: 88,
                                              height: 88,
                                              decoration: BoxDecoration(
                                                shape: BoxShape.circle,
                                                color: isUnlocked
                                                    ? sectionColor
                                                    : Colors.grey[300],
                                                boxShadow: [
                                                  BoxShadow(
                                                    color:
                                                        (isUnlocked
                                                                ? sectionColor
                                                                : Colors
                                                                      .grey[300])!
                                                            .withOpacity(0.3),
                                                    blurRadius: 10,
                                                    offset: const Offset(0, 6),
                                                  ),
                                                ],
                                              ),
                                              child: Column(
                                                mainAxisAlignment:
                                                    MainAxisAlignment.center,
                                                children: [
                                                  Text(
                                                    '${index + 1}',
                                                    style: GoogleFonts.inter(
                                                      color: isUnlocked
                                                          ? Colors.white
                                                          : Colors.grey[600],
                                                      fontSize: 26,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                    ),
                                                  ),
                                                  if (isUnlocked &&
                                                      index < scores.length)
                                                    Text(
                                                      '${scores[index]}%',
                                                      style: GoogleFonts.inter(
                                                        color: Colors.white,
                                                        fontSize: 14,
                                                        fontWeight:
                                                            FontWeight.w500,
                                                      ),
                                                    ),
                                                ],
                                              ),
                                            ),
                                            if (!isUnlocked)
                                              const Positioned(
                                                right: 0,
                                                top: 0,
                                                child: Icon(
                                                  Icons.lock,
                                                  color: Colors.grey,
                                                  size: 26,
                                                ),
                                              ),
                                            if (isUnlocked &&
                                                index < scores.length)
                                              Positioned(
                                                right: 0,
                                                top: 0,
                                                child: Container(
                                                  padding: const EdgeInsets.all(
                                                    5,
                                                  ),
                                                  decoration: BoxDecoration(
                                                    color: Colors.white,
                                                    shape: BoxShape.circle,
                                                    boxShadow: [
                                                      BoxShadow(
                                                        color: sectionColor
                                                            .withOpacity(0.3),
                                                        blurRadius: 4,
                                                        offset: const Offset(
                                                          0,
                                                          2,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                  child: Icon(
                                                    Icons.check_circle,
                                                    color: sectionColor,
                                                    size: 22,
                                                  ),
                                                ),
                                              ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            }),
                          ),
                  ),
                ],
              ),
            ),

            if (_isDropdownOpen)
              Positioned(
                top: 55,
                left: 16,
                right: 16,
                child: Material(
                  elevation: 8,
                  color: Colors.transparent,
                  borderRadius: BorderRadius.circular(18),
                  child: Column(
                    children: List.generate(_sections.length, (index) {
                      final s = _sections[index];
                      return Padding(
                        padding: EdgeInsets.only(
                          bottom: index == _sections.length - 1 ? 0 : 8.0,
                        ),
                        child: InkWell(
                          onTap: () async {
                            setState(() {
                              _selectedSectionIndex = index;
                              _isDropdownOpen = false;
                              _levels = []; // Reset levels when section changes
                            });
                            // Load levels for selected section
                            final selectedSection = _sections[index];
                            final slugSection =
                                selectedSection['slug'] as String? ??
                                'section-${index + 1}';
                            await _loadLevelsForSection(slugSection);
                            // Update progress for the selected section
                            await _updateUnlockedLevels();
                            // Pastikan level 1 selalu terbuka untuk semua section
                            if (mounted) {
                              setState(() {
                                for (var i = 0; i < _sections.length; i++) {
                                  if ((_sections[i]['unlockedLevel'] as int) < 1) {
                                    _sections[i]['unlockedLevel'] = 1;
                                  }
                                }
                              });
                            }
                          },
                          borderRadius: BorderRadius.circular(18),
                          child: Container(
                            width: screenWidth - 32,
                            padding: const EdgeInsets.symmetric(
                              vertical: 18,
                              horizontal: 20,
                            ),
                            margin: const EdgeInsets.symmetric(
                              horizontal: 0,
                              vertical: 0,
                            ),
                            decoration: BoxDecoration(
                              color: s['color'] as Color,
                              borderRadius: BorderRadius.circular(18),
                              boxShadow: [
                                BoxShadow(
                                  color: (s['color'] as Color).withOpacity(0.3),
                                  blurRadius: 8,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '${s['section']}',
                                  style: GoogleFonts.inter(
                                    color: Colors.white,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                Text(
                                  '${s['title']}',
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
                    }),
                  ),
                ),
              ),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavBar(currentIndex: _currentBottomNavIndex),
    );
  }
}
