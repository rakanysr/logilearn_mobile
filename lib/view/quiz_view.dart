import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../widgetSoal/question_card.dart' as quiz_widget;
import '../widgetSoal/finish_screen.dart';
import '../services/api_service.dart';

class Question {
  final int id;
  final String question;
  final List<String>? options;
  final List<int>? optionIds;
  final int? correctIndex;
  final bool isEssay;

  Question({
    required this.id,
    required this.question,
    this.options,
    this.optionIds,
    this.correctIndex,
    this.isEssay = false,
  });
}

class QuizScreen extends StatefulWidget {
  final String sectionSlug;
  final int levelId;
  final String sectionTitle;
  final int sectionNumber;
  final int levelNumber;

  const QuizScreen({
    super.key,
    required this.sectionSlug,
    required this.levelId,
    required this.sectionTitle,
    required this.sectionNumber,
    required this.levelNumber,
  });

  @override
  State<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends State<QuizScreen> {
  int currentIndex = 0;
  int? selectedIndex;
  String essayAnswer = "";
  int score = 0;
  List<Question> questions = [];
  bool _isLoading = true;
  bool _isSubmitting = false;
  String? _errorMessage;
  final Map<int, int> _userAnswers = {};
  final Map<int, String> _userEssayAnswers = {};
  TextEditingController? _essayController;
  int? _attemptId;
  final List<Future<void>> _activeSubmissions = [];

  @override
  void initState() {
    super.initState();
    _initQuiz();
  }

  String _getDraftKey() {
    return 'quiz_draft_level_${widget.levelId}';
  }

  Future<void> _saveDraftLocally() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      final stringUserAnswers = _userAnswers.map((key, value) => MapEntry(key.toString(), value));
      final stringEssayAnswers = _userEssayAnswers.map((key, value) => MapEntry(key.toString(), value));

      final draftData = {
        'currentIndex': currentIndex,
        'userAnswers': stringUserAnswers,
        'userEssayAnswers': stringEssayAnswers,
      };

      await prefs.setString(_getDraftKey(), jsonEncode(draftData));
      debugPrint('💾 Draft saved locally for level ${widget.levelId}');
    } catch (e) {
      debugPrint('❌ Error saving draft: $e');
    }
  }

  Future<void> _loadDraftLocally() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final draftString = prefs.getString(_getDraftKey());
      if (draftString != null) {
        final draftData = jsonDecode(draftString) as Map<String, dynamic>;
        
        setState(() {
          currentIndex = draftData['currentIndex'] as int? ?? 0;
          
          final rawAnswers = draftData['userAnswers'] as Map<String, dynamic>? ?? {};
          rawAnswers.forEach((key, value) {
            final intKey = int.tryParse(key);
            if (intKey != null && value is int) {
              _userAnswers[intKey] = value;
            }
          });

          final rawEssayAnswers = draftData['userEssayAnswers'] as Map<String, dynamic>? ?? {};
          rawEssayAnswers.forEach((key, value) {
            final intKey = int.tryParse(key);
            if (intKey != null && value is String) {
              _userEssayAnswers[intKey] = value;
            }
          });

          if (_userAnswers.containsKey(currentIndex)) {
            final savedIndex = _userAnswers[currentIndex];
            selectedIndex = savedIndex == -1 ? null : savedIndex;
          } else {
            selectedIndex = null;
          }
          essayAnswer = _userEssayAnswers[currentIndex] ?? "";
          _updateEssayController();
        });
        debugPrint('💾 Draft loaded successfully for level ${widget.levelId}. Resuming at question $currentIndex.');
      }
    } catch (e) {
      debugPrint('❌ Error loading draft: $e');
    }
  }

  Future<void> _clearDraftLocally() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_getDraftKey());
      debugPrint('🧹 Draft cleared for level ${widget.levelId}');
    } catch (e) {
      debugPrint('❌ Error clearing draft: $e');
    }
  }

  Future<void> _initQuiz() async {
    debugPrint('');
    debugPrint('========================================');
    debugPrint('🚀 _initQuiz STARTED for level ${widget.levelId}');
    debugPrint('========================================');
    debugPrint('');

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final apiService = ApiService();

      debugPrint(
        'Loading questions and creating attempt in parallel for level ${widget.levelId} in section ${widget.sectionSlug}',
      );

      final List<Future<Map<String, dynamic>>> futures = [
        apiService.getSoalsByLevel(
          widget.sectionSlug,
          widget.levelId,
          useCache: true,
        ),
        apiService.createAttempt(widget.levelId),
      ];

      final results = await Future.wait(futures);
      final result = results[0];
      final attemptResult = results[1];

      if (attemptResult['success']) {
        _attemptId = _readAttemptId(attemptResult['data']);
        debugPrint('✅ Attempt created in background. Attempt ID: $_attemptId');
      } else {
        debugPrint('❌ Failed to create attempt in background: ${attemptResult['message']}');
      }

      if (result['success']) {
        final fullResponse = result['data'];
        List<dynamic> soalsList = [];

        if (fullResponse is Map && fullResponse['payload'] is Map) {
          final payload = fullResponse['payload'] as Map;
          if (payload['datas'] is List) {
            soalsList = payload['datas'] as List;
          } else if (payload['datas'] is Map) {
            soalsList = [payload['datas']];
          }
        } else if (fullResponse is Map && fullResponse['datas'] is List) {
          soalsList = fullResponse['datas'] as List;
        } else if (fullResponse is List) {
          soalsList = fullResponse;
        }

        if (soalsList.isNotEmpty) {
          final parsedQuestions = soalsList.map<Question>((soal) {
            final soalMap = soal is Map<String, dynamic>
                ? soal
                : (soal is Map
                      ? Map<String, dynamic>.from(soal)
                      : <String, dynamic>{});

            final id = soalMap['id'];
            final tipe = soalMap['tipe'] as String? ?? 'pg';
            final textSoal = soalMap['text_soal'] as String? ?? '';
            final isEssay = tipe == 'esai';

            if (isEssay) {
              return Question(id: id, question: textSoal, isEssay: true);
            } else {
              List<dynamic> opsisList = [];
              if (soalMap['opsis'] is List) {
                opsisList = soalMap['opsis'] as List;
              }

              List<String> options = [];
              List<int> optionIds = [];
              int? correctIndex;

              for (int i = 0; i < opsisList.length; i++) {
                final opsi = opsisList[i];
                final opsiMap = opsi is Map<String, dynamic>
                    ? opsi
                    : (opsi is Map
                          ? Map<String, dynamic>.from(opsi)
                          : <String, dynamic>{});

                final text = (opsiMap['text_opsi'] ?? opsiMap['text'] ?? '')
                    .toString();
                final optId = opsiMap['id'];

                options.add(text);
                optionIds.add(optId);

                if ((opsiMap['is_correct'] == true) ||
                    (opsiMap['is_benar'] == true)) {
                  correctIndex = i;
                }
              }

              return Question(
                id: id,
                question: textSoal,
                options: options,
                optionIds: optionIds,
                correctIndex: correctIndex,
                isEssay: false,
              );
            }
          }).toList();

          setState(() {
            questions = parsedQuestions;
            _isLoading = false;
          });
          debugPrint('Loaded ${questions.length} questions');
          
          await _loadDraftLocally();
        } else {
          setState(() {
            _errorMessage = 'Tidak ada soal ditemukan untuk level ini';
            _isLoading = false;
          });
        }
      } else {
        setState(() {
          _errorMessage = result['message'] ?? 'Gagal memuat soal dari server';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error: ${e.toString()}';
        _isLoading = false;
      });
      debugPrint('Exception in _initQuiz: $e');
    }
  }

  int? _readAttemptId(dynamic attemptData) {
    if (attemptData is! Map) return null;
    final payload = attemptData['payload'];
    final datas = payload is Map ? payload['datas'] : null;
    final data = attemptData['data'];
    final rawId = datas is Map
        ? datas['id']
        : attemptData['id'] ?? (data is Map ? data['id'] : null);

    if (rawId is int) return rawId;
    return int.tryParse(rawId?.toString() ?? '');
  }

  bool _hasAnswered(Question question) {
    if (question.isEssay) return essayAnswer.trim().isNotEmpty;
    return selectedIndex != null || _userAnswers[currentIndex] != null;
  }

  void _showAnswerRequiredMessage(Question question) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          question.isEssay
              ? 'Tulis jawaban terlebih dahulu'
              : 'Pilih salah satu jawaban terlebih dahulu',
        ),
        backgroundColor: Colors.red,
      ),
    );
  }

  int _calculateLocalPGScore() {
    int localScore = 0;
    for (int i = 0; i < questions.length; i++) {
      final q = questions[i];
      if (!q.isEssay) {
        if (_userAnswers[i] == q.correctIndex) {
          localScore++;
        }
      }
    }
    return localScore;
  }

  void prevQuestion() {
    if (currentIndex > 0 && !_isSubmitting) {
      setState(() {
        currentIndex--;
        if (_userAnswers.containsKey(currentIndex)) {
          final savedIndex = _userAnswers[currentIndex];
          selectedIndex = savedIndex == -1 ? null : savedIndex;
        } else {
          selectedIndex = null;
        }
        essayAnswer = _userEssayAnswers[currentIndex] ?? "";
        _updateEssayController();
      });
    }
  }

  Future<void> _submitAnswerInBackground(int qIndex) async {
    final attemptId = _attemptId;
    if (attemptId == null) {
      debugPrint('⚠️ Cannot submit answer in background: _attemptId is null');
      return;
    }

    final q = questions[qIndex];
    final apiService = ApiService();

    try {
      if (q.isEssay) {
        final answer = _userEssayAnswers[qIndex];
        if (answer != null && answer.trim().isNotEmpty) {
          debugPrint('Uploading essay answer in background for question index $qIndex');
          await apiService.submitJawabanEsai(attemptId, q.id, answer);
        }
      } else {
        final savedSelIndex = _userAnswers[qIndex];
        if (savedSelIndex != null && savedSelIndex != -1 && q.optionIds != null) {
          final optId = q.optionIds![savedSelIndex];
          debugPrint('Uploading PG answer in background for question index $qIndex');
          await apiService.submitJawabanPG(attemptId, optId);
        }
      }
    } catch (e) {
      debugPrint('Background submit error: $e');
    }
  }

  Future<void> nextQuestion() async {
    if (questions.isEmpty || _isSubmitting) return;

    final currentQ = questions[currentIndex];
    if (!_hasAnswered(currentQ)) {
      _showAnswerRequiredMessage(currentQ);
      return;
    }

    if (currentIndex < questions.length - 1) {
      // 1. Save state locally first
      setState(() {
        if (currentQ.isEssay) {
          _userEssayAnswers[currentIndex] = essayAnswer;
        } else {
          _userAnswers[currentIndex] = selectedIndex ?? -1;
        }
      });

      // 2. Trigger background submission for the current question
      final qIndexToSubmit = currentIndex;
      final fut = _submitAnswerInBackground(qIndexToSubmit);
      _activeSubmissions.add(fut);
      fut.then((_) => _activeSubmissions.remove(fut));

      // 3. Move to next question immediately
      setState(() {
        currentIndex++;

        if (_userAnswers.containsKey(currentIndex)) {
          final savedIndex = _userAnswers[currentIndex];
          selectedIndex = savedIndex == -1 ? null : savedIndex;
        } else {
          selectedIndex = null;
        }
        essayAnswer = _userEssayAnswers[currentIndex] ?? "";

        _updateEssayController();
      });
      
      await _saveDraftLocally();
    } else {
      // Final submission (SELESAI clicked)
      setState(() {
        if (currentQ.isEssay) {
          _userEssayAnswers[currentIndex] = essayAnswer;
        } else {
          _userAnswers[currentIndex] = selectedIndex ?? -1;
        }
        _isSubmitting = true;
      });

      await _saveDraftLocally();

      try {
        final apiService = ApiService();

        // 1. Ensure we have an attemptId
        int? finalAttemptId = _attemptId;
        if (finalAttemptId == null) {
          debugPrint('⚠️ No _attemptId found at finalization. Creating attempt now...');
          final attemptRes = await apiService.createAttempt(widget.levelId);
          if (!attemptRes['success']) {
            throw Exception(attemptRes['message'] ?? 'Gagal membuat attempt di server');
          }
          finalAttemptId = _readAttemptId(attemptRes['data']);
          if (finalAttemptId == null) {
            throw Exception('Gagal membaca ID attempt dari server');
          }
          _attemptId = finalAttemptId;
        }

        // 2. Submit the last question and wait for all background tasks to complete
        await _submitAnswerInBackground(currentIndex);
        if (_activeSubmissions.isNotEmpty) {
          await Future.wait(_activeSubmissions);
        }

        // 3. Finalize the attempt
        final finalizeRes = await apiService.submitAttempt(finalAttemptId);
        if (!finalizeRes['success']) {
          throw Exception(finalizeRes['message'] ?? 'Gagal memfinalisasi kuis');
        }

        double? finalScore;
        final data = finalizeRes['data'];
        dynamic rawScore;
        if (data is Map) {
          if (data['payload'] != null && data['payload']['datas'] != null) {
            rawScore = data['payload']['datas']['skor'];
          } else if (data['skor'] != null) {
            rawScore = data['skor'];
          }
        }

        if (rawScore != null) {
          finalScore = double.tryParse(rawScore.toString());
        }

        await _clearDraftLocally();

        if (!mounted) return;
        setState(() {
          _isSubmitting = false;
        });

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => FinishScreen(
              score: _calculateLocalPGScore(),
              finalPercentage: finalScore,
              totalQuestions: questions.length,
              sectionSlug: widget.sectionSlug,
              levelId: widget.levelId,
              sectionTitle: widget.sectionTitle,
              sectionNumber: widget.sectionNumber,
              levelNumber: widget.levelNumber,
            ),
          ),
        );
      } catch (e) {
        if (!mounted) return;
        setState(() {
          _isSubmitting = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Terjadi kendala pengiriman: ${e.toString().replaceAll('Exception: ', '')}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    }
  }

  void _updateEssayController() {
    final savedAnswer = _userEssayAnswers[currentIndex] ?? "";
    _essayController?.dispose();
    _essayController = TextEditingController(text: savedAnswer);
    essayAnswer = savedAnswer;
  }

  Widget _buildEssayField() {
    final savedAnswer = _userEssayAnswers[currentIndex] ?? "";
    if (_essayController == null || _essayController!.text != savedAnswer) {
      _essayController?.dispose();
      _essayController = TextEditingController(text: savedAnswer);
      essayAnswer = savedAnswer;
    }

    return Directionality(
      textDirection: TextDirection.ltr,
      child: TextField(
        key: ValueKey('essay_$currentIndex'),
        controller: _essayController,
        maxLines: 5,
        textDirection: TextDirection.ltr,
        textAlign: TextAlign.start,
        keyboardType: TextInputType.text,
        decoration: InputDecoration(
          hintText: "Ketik jawaban kamu di sini",
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        ),
        onChanged: (val) {
          setState(() {
            essayAnswer = val;
            _userEssayAnswers[currentIndex] = val;
          });
          _saveDraftLocally();
        },
      ),
    );
  }

  @override
  void dispose() {
    _essayController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: Colors.white,
        body: SafeArea(
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Image.asset('assets/images/Mascot halo.png', height: 120),
                const SizedBox(height: 24),
                const CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF2977FF)),
                ),
                const SizedBox(height: 24),
                Text(
                  _errorMessage ?? 'Menyiapkan Kuis...',
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.black54,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    if (_errorMessage != null || questions.isEmpty) {
      return Scaffold(
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
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _errorMessage ?? 'Tidak ada soal ditemukan',
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: _initQuiz,
                    child: const Text('Coba Lagi'),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    final question = questions[currentIndex];
    final progress = (currentIndex + 1) / questions.length;

    if (question.isEssay && _essayController == null) {
      _updateEssayController();
    }

    final currentSelectedIndex =
        !question.isEssay && _userAnswers.containsKey(currentIndex)
        ? (_userAnswers[currentIndex] == -1 ? null : _userAnswers[currentIndex])
        : selectedIndex;
    final canContinue = _hasAnswered(question) && !_isSubmitting;

    return Scaffold(
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                  Expanded(
                    child: LinearProgressIndicator(
                      value: progress,
                      backgroundColor: Colors.grey.shade300,
                      color: Colors.blueAccent,
                      minHeight: 8,
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              
              Expanded(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: Column(
                    children: [
                      quiz_widget.QuestionCard(
                        question: question.question,
                        imagePath: 'assets/images/Mascot bertangan.png',
                      ),
                      const SizedBox(height: 20),
                      if (!question.isEssay)
                        Column(
                          children: List.generate(
                            question.options!.length,
                            (index) => GestureDetector(
                              onTap: () {
                                setState(() {
                                  selectedIndex = index;
                                  _userAnswers[currentIndex] = index;
                                });
                                _saveDraftLocally();
                              },
                              child: Container(
                                margin: const EdgeInsets.symmetric(vertical: 6),
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                width: double.infinity,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(10),
                                  color: currentSelectedIndex == index
                                      ? Colors.blueAccent
                                      : Colors.white,
                                  border: Border.all(
                                    color: currentSelectedIndex == index
                                        ? Colors.blueAccent
                                        : Colors.grey.shade400,
                                  ),
                                ),
                                child: Center(
                                  child: Text(
                                    question.options![index],
                                    style: TextStyle(
                                      fontSize: 16,
                                      color: currentSelectedIndex == index
                                          ? Colors.white
                                          : Colors.black,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        )
                      else
                        _buildEssayField(),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 10),
              if (currentIndex > 0)
                Row(
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.grey.shade300, width: 1.5),
                      ),
                      child: IconButton(
                        icon: const Icon(Icons.arrow_back_ios_new, color: Colors.black54, size: 18),
                        onPressed: _isSubmitting ? null : prevQuestion,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: canContinue ? nextQuestion : null,
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          backgroundColor: Colors.blueAccent,
                        ),
                        child: _isSubmitting
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              )
                            : Text(
                                currentIndex == questions.length - 1
                                    ? "SELESAI"
                                    : "LANJUT",
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                      ),
                    ),
                  ],
                )
              else
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: canContinue ? nextQuestion : null,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      backgroundColor: Colors.blueAccent,
                    ),
                    child: _isSubmitting
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : Text(
                            currentIndex == questions.length - 1
                                ? "SELESAI"
                                : "LANJUT",
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
