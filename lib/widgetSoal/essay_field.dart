import 'package:flutter/material.dart';

class EssayField extends StatelessWidget {
  final ValueChanged<String> onChanged;

  const EssayField({super.key, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return TextField(
      maxLines: 5,
      decoration: InputDecoration(
        hintText: "Ketik jawaban kamu di sini",
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
      onChanged: onChanged,
    );
  }
}