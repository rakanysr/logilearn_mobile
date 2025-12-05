import 'package:flutter/material.dart';
import '../widgetSoal/question_card.dart';
import '../widgetSoal/essay_field.dart';
import '../widgetSoal/finish_screen.dart';

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

final List<Question> questions = [
  Question(
    question: "Berapakah itu 2 + 2 = ....",
    options: ["2", "10", "4", "6"],
    correctIndex: 2,
  ),
  Question(
    question: "Berapakah nilai log(100) basis 10?",
    options: ["2", "10", "5", "20"],
    correctIndex: 0,
  ),
  Question(
    question:
        "Jika hari ini hujan, maka Budi membawa payung. Hari ini tidak hujan. Apakah Budi membawa payung? Jelaskan alasanmu!",
    isEssay: true,
  ),
];

class QuizScreen extends StatefulWidget {
  const QuizScreen({super.key});

  @override
  State<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends State<QuizScreen> {
  int currentIndex = 0;
  int? selectedIndex;
  String essayAnswer = "";
  int score = 0;

  void nextQuestion() {
    final currentQ = questions[currentIndex];
    if (currentQ.isEssay) {
      if (essayAnswer.trim().isNotEmpty) {
        score++;
      }
    } else {
      if (selectedIndex == currentQ.correctIndex) {
        score++;
      }
    }
    if (currentIndex < questions.length - 1) {
      setState(() {
        currentIndex++;
        selectedIndex = null;
        essayAnswer = "";
      });
    } else {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) =>
              FinishScreen(score: score, totalQuestions: questions.length),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final question = questions[currentIndex];
    final progress = (currentIndex + 1) / questions.length;

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
              QuestionCard(
                question: question.question,
                imagePath: 'assets/images/Mascot bertangan.png',
              ),

              const SizedBox(height: 20),
              if (!question.isEssay)
                Column(
                  children: List.generate(
                    question.options!.length,
                    (index) => GestureDetector(
                      onTap: () => setState(() => selectedIndex = index),
                      child: Container(
                        margin: const EdgeInsets.symmetric(vertical: 6),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        width: double.infinity,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(10),
                          color: selectedIndex == index
                              ? Colors.blueAccent
                              : Colors.white,
                          border: Border.all(
                            color: selectedIndex == index
                                ? Colors.blueAccent
                                : Colors.grey.shade400,
                          ),
                        ),
                        child: Center(
                          child: Text(
                            question.options![index],
                            style: TextStyle(
                              fontSize: 16,
                              color: selectedIndex == index
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
                EssayField(onChanged: (val) => essayAnswer = val),

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
