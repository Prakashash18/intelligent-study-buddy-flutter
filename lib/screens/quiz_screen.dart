import 'package:chatty_teacher/screens/quiz_summary.dart';
import 'package:chatty_teacher/services/quiz_controller.dart';
import 'package:chatty_teacher/services/chat_services.dart'; // Import ChatService
import 'package:flutter/material.dart';
import 'package:animated_text_kit/animated_text_kit.dart';
import 'package:flutter_tex/flutter_tex.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart'; // Import flutter_spinkit
import 'package:flutter_markdown_latex/flutter_markdown_latex.dart';
import 'package:flutter_markdown/flutter_markdown.dart'; // Import for Markdown rendering
import 'package:markdown/markdown.dart' as md;

class QuizScreen extends StatefulWidget {
  final QuizQuestionController quizController;
  final VoidCallback onReturnToStudyMode;

  const QuizScreen(
      {Key? key,
      required this.quizController,
      required this.onReturnToStudyMode})
      : super(key: key);

  @override
  _QuizScreenState createState() => _QuizScreenState();
}

class _QuizScreenState extends State<QuizScreen> {
  String? _selectedAnswer;
  Key _animatedTextKey = UniqueKey();
  bool? _isAnswerCorrect;
  bool _isLoadingExplanation = false;
  String? _explanation;

  bool _endQuiz = false;

  @override
  void initState() {
    super.initState();
    widget.quizController.addListener(() {
      setState(() {});
    });
  }

  Future<void> _askForExplanation(Map<String, dynamic> questionData) async {
    setState(() {
      _isLoadingExplanation = true;
    });

    try {
      final jsonData = await ChatService.askForExplanation(questionData);
      print(jsonData);
      setState(() {
        _explanation = jsonData['explanation'];
        _isLoadingExplanation = false;
      });
      _showExplanationDialog(_explanation!);
    } catch (e) {
      setState(() {
        _explanation = 'Error: $e';
        _isLoadingExplanation = false;
      });
      _showExplanationDialog(_explanation!);
    }
  }

  void _showExplanationDialog(String explanation) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(
            'AI Explanation',
            style: TextStyle(fontSize: 32.0, fontWeight: FontWeight.bold),
          ),
          content: SingleChildScrollView(
            child: Container(
              width: MediaQuery.of(context).size.width *
                  0.6, // Set max width to 60% of screen
              child: MarkdownBody(
                selectable: true,
                data: explanation,
                builders: {
                  'latex': LatexElementBuilder(
                    textStyle: const TextStyle(
                      fontWeight: FontWeight.w100,
                    ),
                    textScaleFactor: 1.2,
                  ),
                },
                extensionSet: md.ExtensionSet(
                  [LatexBlockSyntax()],
                  [LatexInlineSyntax()],
                ),
              ),
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: Text(
                'Close',
                style: TextStyle(fontSize: 24.0), // Increase font size
              ),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  Widget renderText(String text, {TextStyle? style}) {
    return containsLatex(text)
        ? TeXView(
            child: TeXViewDocument(text),
            style: TeXViewStyle(),
          )
        : Text(text, style: style);
  }

  bool containsLatex(String text) {
    return text.contains(r'$') ||
        text.contains(r'\[') ||
        text.contains(r'\begin');
  }

  void _showQuitConfirmationDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Quit Quiz'),
          content: Text('Are you sure you want to quit the quiz?'),
          actions: <Widget>[
            TextButton(
              child: Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop(); // Close dialog
              },
            ),
            TextButton(
              child: Text('Yes'),
              onPressed: () {
                setState(() {
                  Navigator.of(context).pop(); // Close dialog
                  _endQuiz = true;
                });
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentQuestion = widget.quizController.currentQuestion;
    final currentQuestionIndex = widget.quizController.currentQuestionIndex;
    final totalQuestions = widget.quizController.totalQuestions;

    return Scaffold(
      body: Center(
        child: widget.quizController.isQuizCompleted || _endQuiz
            ? SummaryPage(
                score: widget.quizController.score,
                totalQuestions: totalQuestions,
                onReturnToStudyMode: () {
                  widget.quizController.resetQuiz();
                  widget.onReturnToStudyMode();
                },
              )
            : Stack(
                children: [
                  Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Padding(
                              padding: const EdgeInsets.only(bottom: 8.0),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'Question ${widget.quizController.currentQuestionIndex + 1} of ${widget.quizController.totalQuestions}',
                                    style: TextStyle(
                                      fontSize: 16.0,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      AnimatedTextKit(
                                        key: _animatedTextKey,
                                        animatedTexts: [
                                          TypewriterAnimatedText(
                                            'Score: ${widget.quizController.score}',
                                            textStyle: TextStyle(
                                              fontSize: 24.0,
                                              fontWeight: FontWeight.bold,
                                              color: widget.quizController
                                                          .score ==
                                                      widget.quizController
                                                          .currentQuestionIndex
                                                  ? Colors.green
                                                  : Colors.red,
                                            ),
                                            speed: const Duration(
                                                milliseconds: 100),
                                          ),
                                        ],
                                      ),
                                      IconButton(
                                        icon: Icon(
                                            Icons.close), // Cross button icon
                                        onPressed: () {
                                          _showQuitConfirmationDialog(); // Show confirmation dialog
                                        },
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            LinearProgressIndicator(
                              value:
                                  widget.quizController.currentQuestionIndex /
                                      widget.quizController.totalQuestions,
                              minHeight: 10,
                            ),
                          ],
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Container(
                          padding: const EdgeInsets.all(16.0),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            border: Border.all(
                              color: Colors.grey,
                              width: 2.0,
                            ),
                            borderRadius: BorderRadius.circular(10.0),
                          ),
                          child: Center(
                            child: renderText(
                              currentQuestion['question'],
                              style: TextStyle(
                                fontSize: 16.0,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ),
                      SizedBox(height: 10),
                      Expanded(
                        child: ListView.builder(
                          itemCount: currentQuestion['options'].length,
                          itemBuilder: (context, i) {
                            return RadioListTile<String>(
                              title: renderText(
                                currentQuestion['options'][i],
                                style: TextStyle(fontSize: 12.0),
                              ),
                              value: currentQuestion['options'][i],
                              groupValue: _selectedAnswer,
                              onChanged: (value) {
                                setState(() {
                                  _selectedAnswer = value;
                                });
                              },
                            );
                          },
                        ),
                      ),
                      SizedBox(height: 10),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          ElevatedButton(
                            onPressed: _selectedAnswer != null
                                ? () {
                                    bool isCorrect = widget.quizController
                                        .checkAnswer(_selectedAnswer!);
                                    setState(() {
                                      _isAnswerCorrect = isCorrect;
                                      _selectedAnswer = null;
                                      _animatedTextKey = UniqueKey();
                                    });
                                  }
                                : null,
                            child: Text('Check Answer'),
                          ),
                          SizedBox(width: 5),
                          if (_isAnswerCorrect != null)
                            ElevatedButton(
                              onPressed: () {
                                widget.quizController.moveToNextQuestion();
                                setState(() {
                                  _isAnswerCorrect = null;
                                });
                              },
                              child: Text('Next Question'),
                            ),
                          SizedBox(width: 10),
                          if (_isAnswerCorrect == false)
                            ElevatedButton.icon(
                              onPressed: () {
                                _askForExplanation({
                                  'question': currentQuestion['question'],
                                  'options': currentQuestion['options'],
                                  'correctAnswer':
                                      currentQuestion['correct_answer'],
                                });
                              },
                              icon: Icon(Icons.help_outline),
                              label: Text('Ask AI'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors
                                    .amberAccent, // Set button color to red
                              ),
                            ),
                        ],
                      ),
                      SizedBox(height: 20),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          if (_isAnswerCorrect != null)
                            Text(
                              _isAnswerCorrect! ? 'Correct!' : 'Wrong!',
                              style: TextStyle(
                                fontSize: 24.0,
                                fontWeight: FontWeight.bold,
                                color: _isAnswerCorrect!
                                    ? Colors.green
                                    : Colors.red,
                              ),
                            ),
                          SizedBox(width: 10),
                        ],
                      ),
                    ],
                  ),
                  if (_isLoadingExplanation)
                    Center(
                      child: SpinKitThreeBounce(
                        color: Colors.blue,
                        size: 50.0,
                      ),
                    ),
                ],
              ),
      ),
    );
  }
}
