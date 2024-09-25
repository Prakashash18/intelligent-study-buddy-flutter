import 'package:flutter/material.dart';

class QuizQuestionController extends ChangeNotifier {
  List<Map<String, dynamic>> _mcqs = []; // Make mcqs private
  int _currentQuestionIndex = 0;
  int _score = 0;
  bool _isQuizCompleted = false; // Add a boolean property to track quiz completion

  QuizQuestionController(); // Remove required mcqs from constructor

  int get currentQuestionIndex => _currentQuestionIndex;
  int get score => _score;
  int get totalQuestions => _mcqs.length; // Getter for totalQuestions
  bool get isQuizCompleted => _isQuizCompleted; // Getter for quiz completion status

  Map<String, dynamic> get currentQuestion => _mcqs[_currentQuestionIndex];

  // Getter for mcqs
  List<Map<String, dynamic>> get mcqs => _mcqs;

  // Setter for mcqs
  set mcqs(List<Map<String, dynamic>> newMcqs) {
    _mcqs = newMcqs;
    notifyListeners();
  }

  bool checkAnswer(String selectedAnswer) {
    bool isCorrect = selectedAnswer == currentQuestion['correct_answer'];
    if (isCorrect) {
      _score++;
    }
    return isCorrect;
  }

  void moveToNextQuestion() {
    if (_currentQuestionIndex < _mcqs.length - 1) {
      _currentQuestionIndex++;
    } else {
      // End of quiz
      _isQuizCompleted = true; // Set quiz completion status to true
    }
    notifyListeners();
  }

  void resetQuiz() {
    _currentQuestionIndex = 0;
    _score = 0;
    _isQuizCompleted = false; // Reset quiz completion status
    notifyListeners();
  }
}