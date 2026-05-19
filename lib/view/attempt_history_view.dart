import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:logilearn/services/api_service.dart';
import 'package:logilearn/view/review_attempt_view.dart';
import 'package:logilearn/widget/bottombar.dart';

class AttemptHistoryView extends StatefulWidget {
  const AttemptHistoryView({super.key});

  @override
  State<AttemptHistoryView> createState() => _AttemptHistoryViewState();
}

class _AttemptHistoryViewState extends State<AttemptHistoryView> {
  final _apiService = ApiService();
  final _storage = const FlutterSecureStorage();

  bool _isLoading = true;
  String? _errorMessage;
  List<Map<String, dynamic>> _attempts = [];
  List<Map<String, dynamic>> _sections = [];

  @override
  void initState() {
    super.initState();
    _loadAttempts();
  }

  int? _asInt(dynamic value) {
    if (value is int) return value;
    return int.tryParse(value?.toString() ?? '');
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

  Future<void> _loadAttempts() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final pelajarId = _asInt(await _storage.read(key: 'id_pelajar'));
    if (pelajarId == null) {
      if (!mounted) return;
      setState(() {
        _errorMessage = 'Silakan login kembali untuk melihat attempt.';
        _isLoading = false;
      });
      return;
    }

    final attemptsResult = await _apiService.getAttemptsByPelajarId(pelajarId);
    final sectionsResult = await _apiService.getSections();
    if (!mounted) return;

    if (!attemptsResult['success']) {
      setState(() {
        _errorMessage = attemptsResult['message'] ?? 'Gagal memuat attempt.';
        _isLoading = false;
      });
      return;
    }

    final attempts = _extractList(
      attemptsResult['data'],
    ).whereType<Map>().map((item) => Map<String, dynamic>.from(item)).toList();

    attempts.sort((a, b) {
      final aId = _asInt(a['id']) ?? 0;
      final bId = _asInt(b['id']) ?? 0;
      return bId.compareTo(aId);
    });

    final sections = sectionsResult['success']
        ? _extractList(sectionsResult['data'])
              .whereType<Map>()
              .map((item) => Map<String, dynamic>.from(item))
              .toList()
        : <Map<String, dynamic>>[];

    setState(() {
      _attempts = attempts;
      _sections = sections;
      _isLoading = false;
    });
  }

  int _sectionNumberFor(Map<String, dynamic>? section) {
    final sectionId = _asInt(section?['id']);
    final index = _sections.indexWhere(
      (item) => _asInt(item['id']) == sectionId,
    );
    return index >= 0 ? index + 1 : 1;
  }

  int _levelNumberFor(Map<String, dynamic>? level) {
    final rawName = level?['nama']?.toString() ?? '';
    final match = RegExp(r'\d+').firstMatch(rawName);
    return int.tryParse(match?.group(0) ?? '') ?? 1;
  }

  void _openAttempt(Map<String, dynamic> attempt) {
    final level = attempt['levels'] is Map
        ? Map<String, dynamic>.from(attempt['levels'] as Map)
        : <String, dynamic>{};
    final section = level['sections'] is Map
        ? Map<String, dynamic>.from(level['sections'] as Map)
        : <String, dynamic>{};

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ReviewAttemptView(
          sectionSlug: section['slug']?.toString() ?? 'section-1',
          levelId: _asInt(attempt['id_level'] ?? level['id']) ?? 1,
          sectionTitle:
              section['nama']?.toString().toUpperCase() ?? 'LOGIKA DASAR',
          sectionNumber: _sectionNumberFor(section),
          levelNumber: _levelNumberFor(level),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
        title: Text(
          'Riwayat Attempt',
          style: GoogleFonts.inter(
            color: Colors.black87,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: _buildBody(),
      bottomNavigationBar: const BottomNavBar(currentIndex: 1),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: Color(0xFF2977FF)),
      );
    }

    if (_errorMessage != null) {
      return _EmptyState(
        icon: Icons.error_outline,
        title: 'Gagal memuat attempt',
        message: _errorMessage!,
        actionLabel: 'Coba Lagi',
        onAction: _loadAttempts,
      );
    }

    if (_attempts.isEmpty) {
      return _EmptyState(
        icon: Icons.assignment_turned_in_outlined,
        title: 'Belum ada attempt',
        message: 'Kerjakan quiz terlebih dahulu untuk melihat hasilmu.',
        actionLabel: 'Muat Ulang',
        onAction: _loadAttempts,
      );
    }

    return RefreshIndicator(
      onRefresh: _loadAttempts,
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
        itemBuilder: (context, index) => _AttemptTile(
          attempt: _attempts[index],
          onTap: () => _openAttempt(_attempts[index]),
        ),
        separatorBuilder: (_, _) => const SizedBox(height: 12),
        itemCount: _attempts.length,
      ),
    );
  }
}

class _AttemptTile extends StatelessWidget {
  final Map<String, dynamic> attempt;
  final VoidCallback onTap;

  const _AttemptTile({required this.attempt, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final level = attempt['levels'] is Map
        ? Map<String, dynamic>.from(attempt['levels'] as Map)
        : <String, dynamic>{};
    final section = level['sections'] is Map
        ? Map<String, dynamic>.from(level['sections'] as Map)
        : <String, dynamic>{};
    final score = (attempt['skor'] as num?)?.toDouble();
    final scoreText = score == null ? '-' : '${score.toStringAsFixed(1)}%';

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            border: Border.all(color: const Color(0xFFE5E7EB)),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: const BoxDecoration(
                  color: Color(0xFFEAF2FF),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.assignment_turned_in,
                  color: Color(0xFF2977FF),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      section['nama']?.toString() ?? 'Section',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.inter(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      level['nama']?.toString() ?? 'Level',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Text(
                scoreText,
                style: GoogleFonts.inter(
                  color: const Color(0xFF2977FF),
                  fontWeight: FontWeight.w800,
                  fontSize: 16,
                ),
              ),
              const SizedBox(width: 8),
              const Icon(Icons.chevron_right, color: Colors.grey),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;
  final String actionLabel;
  final VoidCallback onAction;

  const _EmptyState({
    required this.icon,
    required this.title,
    required this.message,
    required this.actionLabel,
    required this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              title,
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(color: Colors.grey[600]),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: onAction,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2977FF),
                foregroundColor: Colors.white,
              ),
              child: Text(actionLabel),
            ),
          ],
        ),
      ),
    );
  }
}
