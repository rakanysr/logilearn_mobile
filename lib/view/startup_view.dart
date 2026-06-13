import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:logilearn/view/login_view.dart';
import 'package:logilearn/view/home_view.dart';

class StartupView extends StatefulWidget {
  const StartupView({super.key});

  @override
  State<StartupView> createState() => _StartupViewState();
}

class _StartupViewState extends State<StartupView>
    with SingleTickerProviderStateMixin {
  final Color _backgroundColor = const Color(0xFF2977FF);
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;
  Widget _nextScreen = const LoginView();

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );

    _fadeAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    );

    _scaleAnimation = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.elasticOut));

    _controller.forward();
    _initApp();
  }

  Future<void> _initApp() async {
    // Jalankan pengecekan token dan durasi minimum splash screen secara paralel
    await Future.wait([
      _checkLoginStatus(),
      Future.delayed(const Duration(milliseconds: 2500)),
    ]);

    if (mounted) {
      Navigator.of(context).pushReplacement(_createRoute(_nextScreen));
    }
  }

  Future<void> _checkLoginStatus() async {
    try {
      const storage = FlutterSecureStorage();
      final token = await storage.read(key: 'token');
      if (token != null && token.isNotEmpty) {
        // Token exists in secure storage, keep the user logged in until logout.
        setState(() {
          _nextScreen = const HomeView();
        });
      }
    } catch (e) {
      debugPrint('Error checking login status: $e');
    }
  }

  Route _createRoute(Widget destination) {
    return PageRouteBuilder(
      transitionDuration: const Duration(milliseconds: 600),
      pageBuilder: (context, animation, secondaryAnimation) => destination,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        const begin = Offset(1.0, 0.0);
        const end = Offset.zero;
        final tween = Tween(
          begin: begin,
          end: end,
        ).chain(CurveTween(curve: Curves.easeInOut));

        final opacityTween = Tween<double>(begin: 0.0, end: 1.0);

        return SlideTransition(
          position: animation.drive(tween),
          child: FadeTransition(
            opacity: animation.drive(opacityTween),
            child: child,
          ),
        );
      },
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _backgroundColor,
      body: Center(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: ScaleTransition(
            scale: _scaleAnimation,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Image.asset('assets/images/Mascot buntung.png', width: 150),
                const SizedBox(height: 24),
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
        ),
      ),
    );
  }
}
