import 'package:flutter/material.dart';

class SummaryPage extends StatelessWidget {
  final int score;
  final int totalQuestions;
  final VoidCallback onReturnToStudyMode;

  const SummaryPage({
    Key? key,
    required this.score,
    required this.totalQuestions,
    required this.onReturnToStudyMode,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            'Quiz Completed!',
            style: TextStyle(
              fontSize: 24.0,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 20),
          Text(
            'Your Score: $score / $totalQuestions',
            style: TextStyle(
              fontSize: 20.0,
              fontWeight: FontWeight.bold,
              color: score == totalQuestions ? Colors.green : Colors.red,
            ),
          ),
          SizedBox(height: 20),
          ElevatedButton(
            onPressed: onReturnToStudyMode,
            child: Text('Return to Study Mode'),
          ),
        ],
      ),
    );
  }
}
