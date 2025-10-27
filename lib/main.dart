import 'package:flutter/material.dart';
import 'view/review_attempt_view.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: const ReviewAttemptView(),

    );
  }
}
