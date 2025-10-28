import 'package:flutter/material.dart';

void main() {
  runApp(const QuizApp());
}

class QuizApp extends StatelessWidget {
  const QuizApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Quiz Logika',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        fontFamily: 'Poppins',
      ),
      home: const QuizScreen(),
    );
  }
}


// MODEL SOAL

class Question {
  final String question;
  final List<String>? options; // null jika soal isian
  final int? correctIndex;
  final bool isEssay;

  Question({
    required this.question,
    this.options,
    this.correctIndex,
    this.isEssay = false,
  });
}

// DATA SOAL 
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


// QUIZ SCREEN

class QuizScreen extends StatefulWidget {
  const QuizScreen({super.key});

  @override
  State<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends State<QuizScreen> {
  int currentIndex = 0;
  int? selectedIndex;
  String essayAnswer = "";

  void nextQuestion() {
    if (currentIndex < questions.length - 1) {
      setState(() {
        currentIndex++;
        selectedIndex = null;
        essayAnswer = "";
      });
    } else {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const FinishScreen()),
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
              // Tombol keluar + progress bar
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

              // Pertanyaan
              Text(
                question.question,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 20),

              // Maskot
              Image.asset(
                'assets/Mascot bertangan.png',
                height: 120,
              ),
              const SizedBox(height: 20),

              // Pilihan atau isian
              if (!question.isEssay)
                ...List.generate(
                  question.options!.length,
                  (index) => GestureDetector(
                    onTap: () {
                      setState(() {
                        selectedIndex = index;
                      });
                    },
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
                )
              else
                TextField(
                  maxLines: 5,
                  decoration: InputDecoration(
                    hintText: "Ketik jawaban kamu di sini",
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  onChanged: (val) => essayAnswer = val,
                ),

              const Spacer(),

              // Tombol Lanjut / Selesai
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
                        fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}


// FINISH SCREEN
class FinishScreen extends StatelessWidget {
  const FinishScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset('assets/Mascot banyak.png', height: 150),
              const SizedBox(height: 20),
              const Text(
                "Selamat! Kamu sudah menyelesaikan quiz",
                textAlign: TextAlign.center,
                style: TextStyle(
                    fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 40),
              ElevatedButton(
                onPressed: () {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (_) => const QuizScreen()),
                  );
                },
                style: ElevatedButton.styleFrom(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 40, vertical: 14),
                  backgroundColor: Colors.blueAccent,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
                child: const Text("ULANGI QUIZ"),
              )
            ],
          ),
        ),
      ),
    );
  }
}