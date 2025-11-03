import 'package:flutter/material.dart';

class QuestionCard extends StatelessWidget {
  final String question;
  final String imagePath;

  const QuestionCard({
    super.key,
    required this.question,
    required this.imagePath,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          question,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 20),
        Image.asset(imagePath, height: 120),
      ],
    );
  }
}