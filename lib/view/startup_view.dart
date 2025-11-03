import 'dart:async'; // Penting untuk Timer/Future.delayed
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:logilearn/view/login_view.dart';

class StartupView extends StatefulWidget {
  const StartupView({super.key});

  @override
  _StartupViewState createState() => _StartupViewState();
}

class _StartupViewState extends State<StartupView> {
  final Color _backgroundColor = Color(0xFF2977FF);

  @override
  void initState() {
    super.initState();
    _navigateToNextScreen();
  }

  void _navigateToNextScreen() {
    Future.delayed(Duration(seconds: 3), () {
      Navigator.of(
        context,
      ).pushReplacement(MaterialPageRoute(builder: (context) => LoginView()));
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _backgroundColor,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset('assets/images/Mascot buntung.png', width: 150),
            SizedBox(height: 24),
            Text(
              'LogiLearn',
              style: GoogleFonts.inter(
                fontWeight: FontWeight.w800,
                fontSize: 48,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
