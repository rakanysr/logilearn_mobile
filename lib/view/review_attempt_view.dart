import 'package:flutter/material.dart';
import 'package:logilearn/view/widgetAttempt/dropdown_button.dart' as dropdown_widget;
import 'package:logilearn/view/widgetAttempt/header_section.dart';
import 'package:logilearn/view/widgetAttempt/question_card.dart';
import 'package:logilearn/view/widgetAttempt/question_card_with_feedback.dart';
import 'package:logilearn/widget/bottombar.dart';

class ReviewAttemptView extends StatefulWidget {
  const ReviewAttemptView({super.key});

  @override
  State<ReviewAttemptView> createState() => _ReviewAttemptViewState();
}

class _ReviewAttemptViewState extends State<ReviewAttemptView> {
  bool _isDropdownOpen = false;
  String _selectedSection = 'Section 1, Level 1';
  String _selectedTitle = 'LOGIKA DASAR';
  int _currentBottomNavIndex = 1; 

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        child: Column(
          children: [
            dropdown_widget.SectionDropdownButton(
              selectedSection: _selectedSection,
              selectedTitle: _selectedTitle,
              isDropdownOpen: _isDropdownOpen,
              onToggleDropdown: () {
                setState(() {
                  _isDropdownOpen = !_isDropdownOpen;
                });
              },
              onSelectSection: (section, title, number) {
                setState(() {
                  _selectedSection = section;
                  _selectedTitle = title;
                  _isDropdownOpen = false;
                });
              },
            ),
            
            const SizedBox(height: 24),
      
            HeaderSection(
              selectedSection: _selectedSection,
              selectedTitle: _selectedTitle,
              onNextSection: _nextSection,
            ),
            
            const SizedBox(height: 32),
            

            if (_selectedTitle != 'LOGIKA SILOGISME' && _selectedTitle != 'LOGIKA PEMROGRAMAN')
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  children: [
                    QuestionCard(
                      questionNumber: 1,
                      score: '1/1',
                      isCorrect: true,
                      question: 'Berapa itu 2 + 2 = ....',
                      answer: '2',
                    ),
                    const SizedBox(height: 16),
                    QuestionCard(
                      questionNumber: 2,
                      score: '1/1',
                      isCorrect: true,
                      question: 'Berapakah nilai log(100) basis 10?',
                      answer: '2',
                    ),
                    const SizedBox(height: 16),
                    QuestionCardWithFeedback(
                      questionNumber: 3,
                      score: '0/1',
                      isCorrect: false,
                      question: 'Jika hari ini hujan, maka Budi membawa payung. Hari ini tidak hujan. Apakah Budi membawa payung? Jelaskan alasanmu!',
                      answer: 'bawa, karena siaga',
                      feedback: 'Jawaban "bawa, karena siaga" kurang tepat secara logika formal.\n\nPremis yang diberikan:\n1. Jika hari ini hujan, maka Budi membawa payung.\nIni adalah bentuk implikasi logika: P → Q, di mana:\n   P = Hari ini hujan\n   Q = Budi membawa payung\n2. Hari ini tidak hujan\nIni berarti: ~P',
                    ),
                  ],
                ),
              ),
            
            const SizedBox(height: 30),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavBar(
        currentIndex: _currentBottomNavIndex,
        onTap: (index) {
          setState(() {
            _currentBottomNavIndex = index;
          });
          // Handle navigation based on index
          if (index == 0) {
     
          } else if (index == 1) {
        
          } else if (index == 2) {
           
          }
        },
      ),
    );
  }

  void _nextSection() {
    setState(() {
      if (_selectedTitle == 'LOGIKA DASAR') {
        _selectedSection = 'Section 2, Level 1';
        _selectedTitle = 'LOGIKA PEMROGRAMAN';
      } else if (_selectedTitle == 'LOGIKA PEMROGRAMAN') {
        _selectedSection = 'Section 3, Level 1';
        _selectedTitle = 'LOGIKA SILOGISME';
      } else if (_selectedTitle == 'LOGIKA SILOGISME') {
        _selectedSection = 'Section 1, Level 1';
        _selectedTitle = 'LOGIKA DASAR';
      }
    });
  }
}
