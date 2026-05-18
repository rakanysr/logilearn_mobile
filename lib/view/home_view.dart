import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:logilearn/services/api_service.dart';
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

  @override
  void initState() {
    super.initState();
    _loadUserData();
    _fetchSections();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_sections.isNotEmpty) {
      debugPrint('HomeView: didChangeDependencies - refreshing unlock status');
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

      if (fullResponse is Map &&
          fullResponse['payload'] is Map &&
          fullResponse['payload']['datas'] is List) {
        sectionsList = fullResponse['payload']['datas'];
      } else if (fullResponse is List) {
        sectionsList = fullResponse;
      }

      if (sectionsList.isNotEmpty) {
        try {
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

            String imageAsset;
            if (i % 3 == 0) {
              imageAsset = 'assets/images/Mascot halo.png';
            } else if (i % 3 == 1) {
              imageAsset = 'assets/images/Mascot banyak.png';
            } else {
              imageAsset = 'assets/images/Mascot buntung.png';
            }

            int unlocked = 1;

            List<dynamic> levels = [];
            if (item['levels'] is List) {
              levels = item['levels'];
            }
            int totalLev = levels.isNotEmpty ? levels.length : 10;

            List<int> scores = [];

            parsedSections.add({
              'section': 'SECTION ${i + 1}',
              'title': item['nama'] ?? 'LOGIKA',
              'color': sectionColor,
              'image': imageAsset,
              'unlockedLevel': unlocked,
              'completedLevels': 0,
              'levelScores': scores,
              'totalLevels': totalLev,
              'slug': item['slug'] ?? 'section-${i + 1}',
              'id': item['id'],
            });
          }

          _sections = parsedSections;

          if (_sections.isNotEmpty) {
            final firstSection = _sections[0];
            final slugSection = firstSection['slug'] as String? ?? 'section-1';
            await _loadLevelsForSection(slugSection);
            await _updateUnlockedLevels();
          }
        } catch (e) {
          debugPrint("Error parsing sections: $e");

          _sections = [];
        }
      } else {
        _sections = [];
      }
    } else {
      _sections = [];
    }

    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _loadLevelsForSection(String slugSection) async {
    debugPrint('_loadLevelsForSection called with slug: $slugSection');
    final apiService = ApiService();
    final result = await apiService.getLevelsBySection(slugSection);

    debugPrint('getLevelsBySection result success: ${result['success']}');

    if (result['success']) {
      final fullResponse = result['data'];
      List<dynamic> levelsList = [];

      if (fullResponse is Map &&
          fullResponse['payload'] is Map &&
          fullResponse['payload']['datas'] is List) {
        levelsList = fullResponse['payload']['datas'];
        debugPrint('Parsed levels from payload.datas: ${levelsList.length}');
      } else if (fullResponse is Map && fullResponse['datas'] is List) {
        levelsList = fullResponse['datas'];
        debugPrint('Parsed levels from datas: ${levelsList.length}');
      } else if (fullResponse is List) {
        levelsList = fullResponse;
        debugPrint('Parsed levels from direct list: ${levelsList.length}');
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

          _levels.sort((a, b) => (a['id'] as int).compareTo(b['id'] as int));

          debugPrint('Loaded ${_levels.length} levels into state:');
          for (var i = 0; i < _levels.length; i++) {
            debugPrint(
              '  Index $i: id=${_levels[i]['id']}, nama=${_levels[i]['nama']}',
            );
          }
        });
      }
    } else {
      debugPrint('Failed to load levels: ${result['message']}');
    }
  }

  Future<void> _updateUnlockedLevels() async {
    debugPrint('========================================');
    debugPrint('_updateUnlockedLevels called');
    final apiService = ApiService();

    final pelajarIdStr = await _storage.read(key: 'id_pelajar');
    debugPrint('Pelajar ID from storage: $pelajarIdStr');

    if (pelajarIdStr == null) {
      debugPrint('No pelajar ID found in storage');
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
      debugPrint('Invalid pelajar ID: $pelajarIdStr');
      return;
    }

    debugPrint('Fetching attempts for pelajar ID: $pelajarId');

    final result = await apiService.getAttemptsByPelajarId(pelajarId);

    if (result['success']) {
      final fullResponse = result['data'];
      List<dynamic> attemptsList = [];

      if (fullResponse is Map &&
          fullResponse['payload'] is Map &&
          fullResponse['payload']['datas'] is List) {
        attemptsList = fullResponse['payload']['datas'];
      } else if (fullResponse is List) {
        attemptsList = fullResponse;
      }

      debugPrint('Found ${attemptsList.length} attempts');

      Map<int, int> sectionMaxLevels = {};
      Map<int, Set<int>> sectionCompletedLevelIds = {};

      for (var attempt in attemptsList) {
        try {
          if (attempt['levels'] != null &&
              attempt['levels']['sections'] != null) {
            final sectionId = attempt['levels']['sections']['id'] as int;
            final levelId = attempt['levels']['id'] as int;

            final skor = attempt['skor'] != null
                ? (attempt['skor'] is num
                      ? (attempt['skor'] as num).toDouble()
                      : 0.0)
                : 0.0;

            debugPrint(
              'Attempt: sectionId=$sectionId, levelId=$levelId, skor=$skor',
            );

            if (skor >= 75.0) {
              if (!sectionMaxLevels.containsKey(sectionId) ||
                  levelId > sectionMaxLevels[sectionId]!) {
                sectionMaxLevels[sectionId] = levelId;
              }

              if (!sectionCompletedLevelIds.containsKey(sectionId)) {
                sectionCompletedLevelIds[sectionId] = <int>{};
              }
              sectionCompletedLevelIds[sectionId]!.add(levelId);
            } else {
              debugPrint(
                '  Score $skor is below 75, not counting as completed',
              );
            }
          }
        } catch (e) {
          debugPrint('Error processing attempt: $e');
        }
      }

      debugPrint('Section max levels: $sectionMaxLevels');
      debugPrint('Section completed level IDs: $sectionCompletedLevelIds');

      for (var i = 0; i < _sections.length; i++) {
        final section = _sections[i];
        final sectionId = section['id'] as int?;
        final sectionSlug = section['slug'] as String?;

        if (sectionId == null || sectionSlug == null) {
          debugPrint('Section $i has no ID or slug, skipping');
          continue;
        }

        int unlockedLevel = 1;
        int completedLevels = 0;

        if (sectionMaxLevels.containsKey(sectionId)) {
          if (sectionCompletedLevelIds.containsKey(sectionId)) {
            completedLevels = sectionCompletedLevelIds[sectionId]!.length;
            debugPrint(
              'Section $sectionId: completed $completedLevels levels (score >= 75)',
            );
          }

          final maxCompletedLevelId = sectionMaxLevels[sectionId]!;

          final levelsResult = await apiService.getLevelsBySection(sectionSlug);

          if (levelsResult['success']) {
            final levelsResponse = levelsResult['data'];
            List<dynamic> sectionLevelsList = [];

            if (levelsResponse is Map &&
                levelsResponse['payload'] is Map &&
                levelsResponse['payload']['datas'] is List) {
              sectionLevelsList = levelsResponse['payload']['datas'];
            } else if (levelsResponse is List) {
              sectionLevelsList = levelsResponse;
            }

            sectionLevelsList.sort((a, b) {
              final aId = a['id'] is int ? a['id'] as int : 0;
              final bId = b['id'] is int ? b['id'] as int : 0;
              return aId.compareTo(bId);
            });

            debugPrint(
              'Section $sectionId ($sectionSlug) has ${sectionLevelsList.length} levels',
            );

            int completedLevelIndex = -1;
            for (var j = 0; j < sectionLevelsList.length; j++) {
              final levelId = sectionLevelsList[j]['id'] as int;
              if (levelId == maxCompletedLevelId) {
                completedLevelIndex = j;
                debugPrint('  Completed level at index $j (id=$levelId)');
                break;
              }
            }

            if (completedLevelIndex != -1) {
              unlockedLevel = completedLevelIndex + 2;

              if (unlockedLevel > sectionLevelsList.length) {
                unlockedLevel = sectionLevelsList.length;
              }

              debugPrint(
                'Section $sectionId: completed index $completedLevelIndex, unlocking level $unlockedLevel',
              );
            } else {
              unlockedLevel = 1;
              debugPrint(
                'Section $sectionId: completed level not found in list, unlocking level 1',
              );
            }
          } else {
            unlockedLevel = 1;
            debugPrint(
              'Section $sectionId: failed to fetch levels, unlocking level 1',
            );
          }
        }

        if (mounted) {
          setState(() {
            _sections[i]['unlockedLevel'] = unlockedLevel;
            _sections[i]['completedLevels'] = completedLevels;
          });
        }

        debugPrint(
          'Section ${i + 1} (id=$sectionId): unlocked up to level $unlockedLevel, completed $completedLevels levels (score >= 75)',
        );
      }

      if (mounted) {
        setState(() {
          for (var i = 0; i < _sections.length; i++) {
            if ((_sections[i]['unlockedLevel'] as int) < 1) {
              _sections[i]['unlockedLevel'] = 1;
            }
          }
        });
      }

      debugPrint('========================================');
      debugPrint('FINAL UNLOCK STATUS:');
      for (var i = 0; i < _sections.length; i++) {
        debugPrint(
          '  Section ${i + 1}: ${_sections[i]['title']} - Unlocked Level: ${_sections[i]['unlockedLevel']}',
        );
      }
      debugPrint('========================================');
    } else {
      debugPrint('Failed to fetch attempts: ${result['message']}');
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

    debugPrint('_navigateToLevelDetail called:');
    debugPrint('  levelIndex: $levelIndex');
    debugPrint('  slugSection: $slugSection');
    debugPrint('  _levels.length: ${_levels.length}');

    await _loadLevelsForSection(slugSection);

    await Future.delayed(const Duration(milliseconds: 100));
    if (!mounted) return;

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
    final levelId = level['id'] is int
        ? level['id'] as int
        : int.tryParse(level['id'].toString()) ?? 0;
    final sectionTitle = selectedSection['title'] as String;
    final sectionNumber = _selectedSectionIndex + 1;

    debugPrint('Navigating to QuizScreen:');
    debugPrint('  sectionSlug: $slugSection');
    debugPrint('  levelId: $levelId');
    debugPrint('  sectionTitle: $sectionTitle');
    debugPrint('  sectionNumber: $sectionNumber');
    debugPrint('  levelNumber: ${levelIndex + 1}');

    if (levelId == 0) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('ID Level tidak valid')));
      return;
    }

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
      debugPrint('Returned from quiz - refreshing unlock status and progress');
      await Future.delayed(const Duration(milliseconds: 500));
      await _updateUnlockedLevels();
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

    if (_sections.isEmpty) {
      return Scaffold(
        backgroundColor: Colors.white,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 64, color: Colors.grey[400]),
              const SizedBox(height: 16),
              Text(
                'Gagal memuat data',
                style: GoogleFonts.inter(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[700],
                ),
              ),
              const SizedBox(height: 8),
              ElevatedButton(
                onPressed: _fetchSections,
                child: const Text('Coba Lagi'),
              ),
            ],
          ),
        ),
      );
    }

    final selected = _sections[_selectedSectionIndex];
    final screenWidth = MediaQuery.of(context).size.width;

    int unlocked = 0;
    if (selected['unlockedLevel'] is int) {
      unlocked = selected['unlockedLevel'];
    }

    int completed = 0;
    if (selected['completedLevels'] is int) {
      completed = selected['completedLevels'];
    }

    int total = _levels.isNotEmpty ? _levels.length : 10;
    if (selected['totalLevels'] is int && _levels.isEmpty) {
      total = selected['totalLevels'];
    }

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
                              fontSize: 18,
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
                            color: selected['color'] as Color,
                            borderRadius: BorderRadius.circular(18),
                            boxShadow: [
                              BoxShadow(
                                color: (selected['color'] as Color).withValues(
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
                              final isUnlocked = index < unlocked;
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
                                                            .withValues(
                                                              alpha: 0.3,
                                                            ),
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
                                                            .withValues(
                                                              alpha: 0.3,
                                                            ),
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
                              _levels = [];
                            });
                            final selectedSection = _sections[index];
                            final slugSection =
                                selectedSection['slug'] as String? ??
                                'section-${index + 1}';
                            await _loadLevelsForSection(slugSection);
                            await _updateUnlockedLevels();
                            if (mounted) {
                              setState(() {
                                for (var i = 0; i < _sections.length; i++) {
                                  if ((_sections[i]['unlockedLevel'] as int) <
                                      1) {
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
                                  color: (s['color'] as Color).withValues(
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
