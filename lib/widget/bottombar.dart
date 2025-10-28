import 'package:flutter/material.dart';
import 'package:logilearn/view/home_view.dart';
import 'package:logilearn/view/review_attempt_view.dart';

class BottomNavBar extends StatelessWidget {
  final int currentIndex;
  final Function(int)? onTap;

  const BottomNavBar({super.key, required this.currentIndex, this.onTap});

  void _handleTap(BuildContext context, int index) {
    if (index == currentIndex) return; // biar gak reload page yang sama

    switch (index) {
      case 0:
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => const HomeView(),
          ),
        );
        break;
      case 1:
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const ReviewAttemptView()),
        );
        break;
      case 2:
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Halaman Akun belum tersedia 👷‍♂️')),
        );
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: BottomNavigationBar(
        currentIndex: currentIndex,
        onTap: (index) {
          if (onTap != null) {
            onTap!(index);
          }
          _handleTap(context, index);
        },
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.white,
        selectedItemColor: Colors.black87,
        unselectedItemColor: Colors.black54,
        selectedFontSize: 12,
        unselectedFontSize: 12,
        iconSize: 24,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            activeIcon: Icon(Icons.home),
            label: 'Beranda',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.assignment_turned_in_outlined),
            activeIcon: Icon(Icons.assignment_turned_in),
            label: 'Attempts',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            activeIcon: Icon(Icons.person),
            label: 'Akun',
          ),
        ],
      ),
    );
  }
}
