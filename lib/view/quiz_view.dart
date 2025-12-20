import 'package:flutter/material.dart';
import '../widgetSoal/question_card.dart' as quiz_widget;
import '../widgetSoal/finish_screen.dart';
import '../services/api_service.dart';

class Question {
  final String question;
  final List<String>? options;
  final int? correctIndex;
  final bool isEssay;

  Question({
    required this.question,
    this.options,
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
  String? _errorMessage;
  Map<int, int> _userAnswers = {}; // Store user's selected answers for PG questions
  Map<int, String> _userEssayAnswers = {}; // Store user's essay answers
  TextEditingController? _essayController;

  @override
  void initState() {
    super.initState();
    _loadQuestions();
  }

  Future<void> _loadQuestions() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final apiService = ApiService();
      print('Loading questions for level ${widget.levelId} in section ${widget.sectionSlug}');
      
      final result = await apiService.getSoalsByLevel(widget.sectionSlug, widget.levelId);

      if (result['success']) {
        final fullResponse = result['data'];
        List<dynamic> soalsList = [];

        // Parse response structure
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
                : (soal is Map ? Map<String, dynamic>.from(soal) : <String, dynamic>{});
            
            final tipe = soalMap['tipe'] as String? ?? 'pg';
            final textSoal = soalMap['text_soal'] as String? ?? '';
            final isEssay = tipe == 'esai';
            
            if (isEssay) {
              return Question(
                question: textSoal,
                isEssay: true,
              );
            } else {
              // Parse options for PG questions
              List<dynamic> opsisList = [];
              if (soalMap['opsis'] is List) {
                opsisList = soalMap['opsis'] as List;
              }
              
              List<String> options = [];
              int? correctIndex;
              
              for (int i = 0; i < opsisList.length; i++) {
                final opsi = opsisList[i];
                final opsiMap = opsi is Map<String, dynamic>
                    ? opsi
                    : (opsi is Map ? Map<String, dynamic>.from(opsi) : <String, dynamic>{});
                
                final text = (opsiMap['text_opsi'] ?? opsiMap['text'] ?? '').toString();
                options.add(text);
                
                // Check if this is the correct answer
                if ((opsiMap['is_correct'] == true) || (opsiMap['is_benar'] == true)) {
                  correctIndex = i;
                }
              }
              
              return Question(
                question: textSoal,
                options: options,
                correctIndex: correctIndex,
                isEssay: false,
              );
            }
          }).toList();

          setState(() {
            questions = parsedQuestions;
            _isLoading = false;
          });
          print('Loaded ${questions.length} questions');
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
      print('Exception in _loadQuestions: $e');
    }
  }

  void nextQuestion() {
    if (questions.isEmpty) return;
    
    final currentQ = questions[currentIndex];
    
    // Save user's answer
    if (currentQ.isEssay) {
      _userEssayAnswers[currentIndex] = essayAnswer;
      // For essay, we'll check later (not auto-scoring)
    } else {
      _userAnswers[currentIndex] = selectedIndex ?? -1;
      // Check if answer is correct
      if (selectedIndex == currentQ.correctIndex) {
        score++;
      }
    }
    
    if (currentIndex < questions.length - 1) {
      setState(() {
        currentIndex++;
        // Restore previous answer if exists, otherwise reset
        if (_userAnswers.containsKey(currentIndex)) {
          final savedIndex = _userAnswers[currentIndex];
          selectedIndex = savedIndex == -1 ? null : savedIndex;
        } else {
          selectedIndex = null;
        }
        essayAnswer = _userEssayAnswers[currentIndex] ?? "";
        // Update essay controller for new question
        _updateEssayController();
      });
    } else {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => FinishScreen(
            score: score,
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
    // Dispose old controller if exists
    _essayController?.dispose();
    // Create new controller with saved answer
    _essayController = TextEditingController(text: savedAnswer);
    essayAnswer = savedAnswer;
  }

  Widget _buildEssayField() {
    // Ensure controller is initialized with current answer
    final savedAnswer = _userEssayAnswers[currentIndex] ?? "";
    if (_essayController == null || _essayController!.text != savedAnswer) {
      _essayController?.dispose();
      _essayController = TextEditingController(text: savedAnswer);
      essayAnswer = savedAnswer;
    }
    
    return Directionality(
      textDirection: TextDirection.ltr, // Force left-to-right direction
      child: TextField(
        key: ValueKey('essay_$currentIndex'), // Unique key per question
        controller: _essayController,
        maxLines: 5,
        textDirection: TextDirection.ltr, // Force left-to-right text direction
        textAlign: TextAlign.start, // Use start instead of left for better RTL support
        keyboardType: TextInputType.text,
        decoration: InputDecoration(
          hintText: "Ketik jawaban kamu di sini",
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
          ),
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
                Text(_errorMessage ?? 'Memuat soal...'),
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
                  Icon(
                    Icons.error_outline,
                    size: 64,
                    color: Colors.red[300],
                  ),
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
                    onPressed: _loadQuestions,
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
    
    // Initialize essay controller if needed (for essay questions)
    if (question.isEssay && _essayController == null) {
      _updateEssayController();
    }
    
    // Get current answer state (for display only, don't modify state here)
    final currentSelectedIndex = !question.isEssay && _userAnswers.containsKey(currentIndex)
        ? (_userAnswers[currentIndex] == -1 ? null : _userAnswers[currentIndex])
        : selectedIndex;

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
                  onPressed: nextQuestion,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    backgroundColor: Colors.blueAccent,
                  ),
                  child: Text(
                    currentIndex == questions.length - 1 ? "SELESAI" : "LANJUT",
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
