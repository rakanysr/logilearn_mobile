import 'package:flutter/material.dart';
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
  int? _currentAttemptId;

  @override
  void initState() {
    super.initState();
    _initQuiz();
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
        'Loading questions for level ${widget.levelId} in section ${widget.sectionSlug}',
      );

      // getSoalsByLevel akan otomatis check cache dulu sebelum fetch dari API
      // Ini akan membuat loading lebih cepat jika soal sudah pernah di-load sebelumnya
      final result = await apiService.getSoalsByLevel(
        widget.sectionSlug,
        widget.levelId,
        useCache: true, // Gunakan cache untuk loading yang lebih cepat
      );

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

  Future<bool> _ensureAttemptCreated() async {
    if (_currentAttemptId != null) return true;

    final apiService = ApiService();
    final attemptRes = await apiService.createAttempt(widget.levelId);

    if (!attemptRes['success']) {
      if (!mounted) return false;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(attemptRes['message'] ?? 'Gagal memulai attempt'),
          backgroundColor: Colors.red,
        ),
      );
      return false;
    }

    _currentAttemptId = _readAttemptId(attemptRes['data']);
    if (_currentAttemptId == null) {
      if (!mounted) return false;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Gagal membaca ID attempt dari server'),
          backgroundColor: Colors.red,
        ),
      );
      return false;
    }

    return true;
  }

  Future<bool> _submitCurrentAnswer() async {
    final attemptReady = await _ensureAttemptCreated();
    if (!attemptReady || _currentAttemptId == null) return false;

    final currentQ = questions[currentIndex];
    final apiService = ApiService();

    try {
      if (currentQ.isEssay) {
        final answer = essayAnswer;
        if (answer.isNotEmpty) {
          debugPrint('Submitting essay answer for question ${currentQ.id}...');
          final result = await apiService.submitJawabanEsai(
            _currentAttemptId!,
            currentQ.id,
            answer,
          );
          debugPrint('Essay submission result: $result');
          if (!result['success']) {
            debugPrint('ERROR: Essay submission failed: ${result['message']}');
          }
        } else {
          debugPrint('Skipping empty essay answer');
          return false;
        }
      } else {
        if (selectedIndex != null && currentQ.optionIds != null) {
          final optId = currentQ.optionIds![selectedIndex!];
          debugPrint(
            'Submitting PG answer for question ${currentQ.id}, option $optId...',
          );
          final result = await apiService.submitJawabanPG(
            _currentAttemptId!,
            optId,
          );
          debugPrint('PG submission result: $result');
          if (!result['success']) {
            debugPrint('ERROR: PG submission failed: ${result['message']}');
          }
        } else {
          debugPrint(
            'Skipping PG answer - no option selected or optionIds missing',
          );
          return false;
        }
      }
      return true;
    } catch (e) {
      debugPrint('EXCEPTION in _submitCurrentAnswer: $e');
      return false;
    }
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

  Future<void> nextQuestion() async {
    if (questions.isEmpty || _isSubmitting) return;

    final currentQ = questions[currentIndex];
    if (!_hasAnswered(currentQ)) {
      _showAnswerRequiredMessage(currentQ);
      return;
    }

    setState(() => _isSubmitting = true);

    if (currentQ.isEssay) {
      _userEssayAnswers[currentIndex] = essayAnswer;
    } else {
      _userAnswers[currentIndex] = selectedIndex ?? -1;
      if (selectedIndex == currentQ.correctIndex) {
        score++;
      }
    }

    final submitted = await _submitCurrentAnswer();
    if (!mounted) return;
    if (!submitted) {
      setState(() => _isSubmitting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Jawaban belum berhasil dikirim. Coba lagi.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (currentIndex < questions.length - 1) {
      setState(() {
        _isSubmitting = false;
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
    } else {
      setState(() => _isLoading = true);
      double? finalScore;

      try {
        if (_currentAttemptId != null) {
          final apiService = ApiService();

          final res = await apiService.submitAttempt(_currentAttemptId!);
          debugPrint('Finish Quiz - Submit Attempt Result: $res');

          if (res['success']) {
            final data = res['data'];

            dynamic rawScore;
            if (data is Map) {
              if (data['payload'] != null && data['payload']['datas'] != null) {
                // Backend standard response format
                rawScore = data['payload']['datas']['skor'];
              } else if (data['skor'] != null) {
                // Direct attempt object
                rawScore = data['skor'];
              }
            }

            if (rawScore != null) {
              finalScore = double.tryParse(rawScore.toString());
              debugPrint('Parsed Final Score: $finalScore');
            }
          }
        }
      } catch (e) {
        debugPrint('Error fetching final score: $e');
      }

      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _isSubmitting = false;
      });

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => FinishScreen(
            score: score,
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
        body: SafeArea(
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const CircularProgressIndicator(),
                const SizedBox(height: 16),
                Text(_errorMessage ?? 'Menyiapkan Quiz...'),
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
              const SizedBox(height: 30),
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

              const Spacer(),
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
