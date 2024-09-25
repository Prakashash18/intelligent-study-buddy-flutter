import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:chatty_teacher/services/chat_services.dart';
import 'package:chatty_teacher/screens/select_quiz.dart';
import 'package:chatty_teacher/services/quiz_controller.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:chatty_teacher/widgets/files_list.dart';

class QuizSelector extends StatefulWidget {
  final Function(List<Map<String, dynamic>>) onQuizGenerated;
  final Function(bool) setLoadingState;
  final QuizQuestionController quizController;

  const QuizSelector({
    Key? key,
    required this.onQuizGenerated,
    required this.setLoadingState,
    required this.quizController,
  }) : super(key: key);

  @override
  _QuizSelectorState createState() => _QuizSelectorState();
}

class _QuizSelectorState extends State<QuizSelector> {
  bool _isLoading = false;
  int _selectedDifficulty = 1;
  int _selectedNumQuestions = 5;
  List<Map<String, dynamic>> _mcqs = [];

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: SelectQuiz(
                onQuizSettingsSelected: (difficulty, numQuestions) async {
                  setState(() {
                    _selectedDifficulty = difficulty;
                    _selectedNumQuestions = numQuestions;
                    _isLoading = true;
                  });

                  try {
                    final fileProvider =
                        Provider.of<FileProvider>(context, listen: false);
                    final fileName = fileProvider.selectedFileName;

                    if (fileName == null) {
                      _showFileSelectionDialog(context);
                      setState(() {
                        _isLoading = false;
                      });
                      return;
                    }

                    final jsonData = await ChatService.fetchQuizQuestions(
                      fileName,
                      _selectedDifficulty,
                      _selectedNumQuestions,
                    );

                    if (jsonData.containsKey('questions')) {
                      _mcqs = jsonData['questions']
                          .cast<Map<String, dynamic>>()
                          .toList();
                      widget.quizController.mcqs = _mcqs;
                      widget.onQuizGenerated(_mcqs);
                    } else {
                      print('Invalid response format');
                    }
                  } catch (e) {
                    print('Error generating MCQs: $e');
                  } finally {
                    setState(() {
                      _isLoading = false;
                    });
                  }
                },
              ),
            ),
          ],
        ),
        if (_isLoading)
          Center(
            child: SpinKitThreeBounce(
              color: Colors.blue,
              size: 50.0,
            ),
          ),
      ],
    );
  }

  void _showFileSelectionDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('File Selection Required'),
          content: Text('Please select a file first.'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('OK'),
            ),
          ],
        );
      },
    );
  }
}
