import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart'; // Import flutter_spinkit

class SelectQuiz extends StatefulWidget {
  final Function(int, int) onQuizSettingsSelected; // Callback for quiz settings

  const SelectQuiz({Key? key, required this.onQuizSettingsSelected})
      : super(key: key);

  @override
  _SelectQuizState createState() => _SelectQuizState();
}

class _SelectQuizState extends State<SelectQuiz> {
  int _selectedDifficulty = 1; // Default difficulty (1: Easy)
  int _selectedNumQuestions = 5; // Default number of questions
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false; // Loading state

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Select Quiz'),
      ),
      body: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Difficulty:',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 10),
                  DropdownButtonFormField<int>(
                    value: _selectedDifficulty,
                    onChanged: (newValue) {
                      setState(() {
                        _selectedDifficulty = newValue!;
                      });
                    },
                    items: [
                      DropdownMenuItem(
                        value: 1,
                        child: Text('Easy'),
                      ),
                      DropdownMenuItem(
                        value: 2,
                        child: Text('Medium'),
                      ),
                      DropdownMenuItem(
                        value: 3,
                        child: Text('Hard'),
                      ),
                    ],
                    decoration: InputDecoration(
                      border: OutlineInputBorder(),
                      contentPadding:
                          EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    ),
                  ),
                  SizedBox(height: 20),
                  Text(
                    'Number of Questions:',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 10),
                  TextFormField(
                    keyboardType: TextInputType.number,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      FilteringTextInputFormatter.allow(
                          RegExp(r'^[1-9]$|^1[0-9]$|^20$')),
                    ],
                    decoration: InputDecoration(
                      hintText: 'Enter number of questions (1-20)',
                      border: OutlineInputBorder(),
                      contentPadding:
                          EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter a number';
                      }
                      final intValue = int.tryParse(value);
                      if (intValue == null || intValue < 1 || intValue > 20) {
                        return 'Please enter a number between 1 and 20';
                      }
                      return null;
                    },
                    onChanged: (value) {
                      setState(() {
                        _selectedNumQuestions = int.tryParse(value) ?? 5;
                      });
                    },
                  ),
                  SizedBox(height: 30),
                  Center(
                    child: SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          if (_formKey.currentState!.validate()) {
                            setState(() {
                              _isLoading = true; // Set loading state to true
                            });
                            // Simulate a delay for loading
                            Future.delayed(Duration(seconds: 2), () {
                              setState(() {
                                _isLoading = false; // Set loading state to false
                              });
                              // Call the callback to pass the selected settings
                              try {
                                widget.onQuizSettingsSelected(
                                    _selectedDifficulty, _selectedNumQuestions);
                              } catch (e) {
                                print(e);
                              }
                            });
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          padding: EdgeInsets.symmetric(vertical: 15),
                          textStyle: TextStyle(fontSize: 18),
                        ),
                        child: Text('Start Quiz'),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (_isLoading)
            Center(
              child: SpinKitThreeBounce(
                color: Colors.blue,
                size: 50.0,
              ),
            ),
        ],
      ),
    );
  }
}