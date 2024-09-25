// import 'dart:ffi';
import 'package:chatty_teacher/services/quiz_controller.dart';
import 'package:chatty_teacher/screens/quiz_screen.dart';
import 'package:flutter/material.dart';
import 'package:chatty_teacher/screens/chat_message.dart';
import 'package:lottie/lottie.dart';

import 'package:flutter/services.dart';

import 'package:provider/provider.dart'; // Import Provider

import 'package:chatty_teacher/widgets/quiz_selector.dart'; // Import QuizSelector
import 'package:flutter_spinkit/flutter_spinkit.dart'; // Import flutter_spinkit
import 'package:chatty_teacher/widgets/files_list.dart';
import 'package:chatty_teacher/widgets/file_upload_widget.dart';
import 'package:chatty_teacher/widgets/document_previewer.dart'; // Import DocumentPreviewer
import 'package:chatty_teacher/screens/chat_helpers.dart'; // Import chat_helpers

import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart'; // Add this import
import 'dart:async'; // Add this import

class ChatScreen extends StatefulWidget {
  const ChatScreen({Key? key}) : super(key: key);

  @override
  _ChatScreenState createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final StreamController<List<ChatMessage>> _messageController =
      StreamController<List<ChatMessage>>.broadcast();

  List<ChatMessage> messages = [];
  List<ChatMessage> chatHistory = []; // Chat history variable
  final TextEditingController _textMessageController =
      TextEditingController(); // Rename the controller
  String? _previousKey = "";
  bool _isShiftPressed = false; // Add this line
  late final _focusNode = FocusNode(
    onKeyEvent: (FocusNode node, KeyEvent evt) {
      print("Key event: ${evt.logicalKey.keyLabel}");
      print("Previous key: $_previousKey");

      // Update the shift key status
      if (evt.logicalKey == LogicalKeyboardKey.shiftLeft ||
          evt.logicalKey == LogicalKeyboardKey.shiftRight) {
        if (evt is KeyDownEvent) {
          _isShiftPressed = true;
        } else if (evt is KeyUpEvent) {
          _isShiftPressed = false;
        }
      }

      if (!_isShiftPressed && evt.logicalKey.keyLabel == 'Enter') {
        if (evt is KeyDownEvent) {
          print("Submitting");
          _handleSubmit();
        }
        _previousKey = "";
        return KeyEventResult.handled;
      } else {
        _previousKey = evt.logicalKey.keyLabel;
        return KeyEventResult.ignored;
      }
    },
  );

  String? selectedFilePath; // To store the selected file path

  late PdfViewerController
      _pdfController; // Use the Syncfusion PdfViewerController
  bool _isLoading = false; // Add a flag for loading state

  bool _isQuizMode = false; // Flag to indicate if quiz mode is active

  bool _showQuiz = false; // Flag to indicate if the quiz should be shown

  List<Map<String, dynamic>> _mcqs = []; // List to store MCQs

  late QuizQuestionController _quizController; // Initialize the quiz controller

  // Add ScrollController
  late ScrollController _scrollController;

  bool _isChatWindowOpen = false; // Add this line

  String _selectedChatType = 'Chat'; // Add this line

  static const int maxCharacters = 200;

  bool _isChatHistoryLoaded = false; // Add this line

  bool isNarrowScreen = false; // Add this line

  bool _isTextSelected = false; // Define the variable here
  String _selectedText = ""; // Define the variable here

  @override
  void initState() {
    super.initState();
    _pdfController = PdfViewerController(); // Update initialization
    _quizController =
        QuizQuestionController(); // Initialize the quiz controller
    _scrollController = ScrollController(); // Initialize the controller
    _messageController
        .add(messages); // Initialize the stream with the current messages

    // Add a listener to update isNarrowScreen
    WidgetsBinding.instance.addPostFrameCallback((_) {
      setState(() {
        isNarrowScreen = MediaQuery.of(context).size.width < 1024;
      });
    });
  }

  Future<void> loadChatHistory(String fileName) async {
    try {
      print("filename ${fileName}");
      // Update to use the new loadChatHistory method
      await ChatHelpers.loadChatHistory(fileName, (loadedChatHistory) {
        print("loaded chat history: $loadedChatHistory"); // Debugging line
        setState(() {
          chatHistory =
              loadedChatHistory; // Update messages with loaded chat history
        });
      }, _scrollController);
    } catch (e) {
      print('Failed to load chat history: $e');
    }
  }

  @override
  void dispose() {
    _messageController.close(); // Close the stream controller
    _textMessageController
        .dispose(); // Dispose the controller when the widget is disposed
    _scrollController.dispose(); // Dispose the scroll controller
    _focusNode.dispose(); // Dispose the FocusNode
    super.dispose();
  }

  void setLoadingState(bool isLoading) {
    setState(() {
      _isLoading = isLoading;
    });
  }

  // Add a method to show a beta testing message
  Widget _buildBetaTestingBanner() {
    return Container(
      color: Colors.yellow,
      padding: const EdgeInsets.all(8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: const [
          Icon(Icons.warning, color: Colors.black),
          SizedBox(width: 8.0),
          Text(
            'Beta Testing: Uploaded data might be lost.',
            style: TextStyle(color: Colors.black),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isNarrowScreen = constraints.maxWidth < 1024;
        return Scaffold(
          body: Stack(
            children: [
              Container(
                padding: EdgeInsets.symmetric(horizontal: 10, vertical: 20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      blurRadius: 8,
                      color: Colors.black.withOpacity(0.2),
                      spreadRadius: 2,
                      offset: Offset(0, 2),
                    )
                  ],
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                              "Intelligent Study Buddy (App under test)",
                              style: Theme.of(context)
                                  .textTheme
                                  .headlineMedium
                                  ?.copyWith(color: Colors.blue)),
                        ),
                        Lottie.asset(
                          "chat.json", // Replace with your Lottie animation file
                          height: 50,
                          width: 50,
                        ),
                      ],
                    ),
                    Divider(color: Colors.grey[300]),
                    // _buildBetaTestingBanner(), // Add the beta testing banner here
                    Expanded(
                      child: _isQuizMode
                          ? _buildQuizMode()
                          : _showQuiz
                              ? QuizScreen(
                                  quizController: _quizController,
                                  onReturnToStudyMode: _returnToStudyMode)
                              : _buildStudyMode(isNarrowScreen),
                    ),
                    if (isNarrowScreen)
                      Stack(
                        children: [
                          Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: AnimatedContainer(
                              duration: Duration(milliseconds: 300),
                              height: _isChatWindowOpen
                                  ? MediaQuery.of(context).size.height * 0.3
                                  : 0,
                              decoration: BoxDecoration(
                                color: Colors.grey[300],
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(20.0),
                                child: _buildChatWindow(),
                              ),
                            ),
                          ),
                          if (_isChatWindowOpen)
                            Positioned(
                              top: 8,
                              right: 8,
                              child: IconButton(
                                icon: Icon(Icons.keyboard_arrow_down),
                                onPressed: () {
                                  setState(() {
                                    _isChatWindowOpen = false;
                                  });
                                },
                              ),
                            ),
                        ],
                      ),
                    Padding(
                      padding: EdgeInsets.all(8),
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.grey[200] ?? Colors.grey[200],
                          border: Border.all(
                              color: Colors.grey[300] ?? Colors.grey),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                if (MediaQuery.of(context).size.width < 1024)
                                  Consumer<FileProvider>(
                                    builder: (context, fileProvider, child) {
                                      return IconButton(
                                        icon: Icon(Icons.attach_file),
                                        onPressed: () {
                                          showModalBottomSheet(
                                            context: context,
                                            builder: (context) =>
                                                FileUploadWidget(),
                                          );
                                        },
                                        color: fileProvider.selectedFileName ==
                                                null
                                            ? Colors.red
                                            : null,
                                      );
                                    },
                                  ),
                                Expanded(
                                  child: DropdownButton<String>(
                                    value: _selectedChatType,
                                    items: [
                                      DropdownMenuItem<String>(
                                        value: 'Chat',
                                        child: Row(
                                          children: [
                                            Icon(Icons
                                                .chat_bubble_outline_rounded),
                                            SizedBox(width: 8),
                                            Text('Chat'),
                                            SizedBox(width: 8),
                                            Tooltip(
                                              message:
                                                  'Chat with the file only',
                                              child: Icon(Icons.info_outline),
                                            ),
                                          ],
                                        ),
                                      ),
                                      DropdownMenuItem<String>(
                                        value: 'Web Search',
                                        child: Row(
                                          children: [
                                            Icon(Icons.web),
                                            SizedBox(width: 8),
                                            Text('Web Search'),
                                            SizedBox(width: 8),
                                            Tooltip(
                                              message:
                                                  'Chat with the file and perform web searches',
                                              child: Icon(Icons.info_outline),
                                            ),
                                          ],
                                        ),
                                      ),
                                      DropdownMenuItem<String>(
                                        value: 'Video Search',
                                        child: Row(
                                          children: [
                                            Icon(Icons.video_library),
                                            SizedBox(width: 8),
                                            Text('Video Search'),
                                            SizedBox(width: 8),
                                            Tooltip(
                                              message:
                                                  'Chat with the file and search for videos',
                                              child: Icon(Icons.info_outline),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                    onChanged: (String? newValue) {
                                      setState(() {
                                        _selectedChatType = newValue!;
                                      });
                                    },
                                  ),
                                ),
                                if (isNarrowScreen)
                                  IconButton(
                                    icon: Icon(
                                        _isChatWindowOpen
                                            ? Icons.close
                                            : Icons.chat,
                                        color: _isChatWindowOpen
                                            ? Colors.red
                                            : null),
                                    onPressed: () {
                                      setState(() {
                                        _isChatWindowOpen = !_isChatWindowOpen;
                                      });
                                    },
                                  ),
                              ],
                            ),
                            Consumer<FileProvider>(
                              builder: (context, fileProvider, child) {
                                return Column(
                                  children: [
                                    // Add the collapsible widget above the text input
                                    if (_isTextSelected)
                                      Dismissible(
                                        key: Key(_selectedText),
                                        onDismissed: (direction) {
                                          setState(() {
                                            _isTextSelected =
                                                false; // Hide the widget when dismissed
                                          });
                                        },
                                        child: Container(
                                          padding: EdgeInsets.all(8.0),
                                          color: Colors.blue[100],
                                          child: Stack(
                                            children: [
                                              Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  Text("Selected Text:",
                                                      style: TextStyle(
                                                          fontWeight: FontWeight
                                                              .bold)), // Make selected text bold
                                                  Text(_selectedText),
                                                  SizedBox(height: 20),

                                                  Text(
                                                      "What would you like to do with this text?"),
                                                  // Add follow-up question options here
                                                ],
                                              ),
                                              Positioned(
                                                top: 2,
                                                right: 2,
                                                child: IconButton(
                                                  icon: Icon(Icons.close,
                                                      size: 8), // Small icon
                                                  onPressed: () {
                                                    // Trigger the dismiss action
                                                    setState(() {
                                                      _isTextSelected =
                                                          false; // Hide the widget
                                                    });
                                                  },
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    // Move this section above the TextField
                                    Padding(
                                      padding: const EdgeInsets.all(8.0),
                                      child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.start,
                                        children: [
                                          TextButton.icon(
                                            icon: Icon(Icons.quiz),
                                            label: Text(_isQuizMode
                                                ? "Study"
                                                : "Quiz"), // Update label based on mode
                                            onPressed: () {
                                              setState(() {
                                                _isQuizMode =
                                                    !_isQuizMode; // Toggle mode
                                              });
                                            },
                                          ),
                                          SizedBox(
                                              width: 10), // Add some spacing
                                          Expanded(
                                            child: Container(
                                              color: fileProvider
                                                          .selectedFileName ==
                                                      null
                                                  ? Colors.grey[200]
                                                  : Colors.white.withOpacity(
                                                      0.9), // Grey background if no file selected, light grey otherwise
                                              child: TextField(
                                                controller:
                                                    _textMessageController,
                                                maxLines: null,
                                                autofocus: true,
                                                focusNode: _focusNode,
                                                enabled: fileProvider
                                                        .selectedFileName !=
                                                    null,
                                                keyboardType:
                                                    TextInputType.multiline,
                                                textInputAction:
                                                    TextInputAction.newline,
                                                decoration: InputDecoration(
                                                  hintText: fileProvider
                                                              .selectedFileName ==
                                                          null
                                                      ? "Select a file to chat with."
                                                      : "Chat with ${fileProvider.selectedFileName ?? 'the file'}",
                                                  border: OutlineInputBorder(),
                                                  suffixIcon: Row(
                                                    mainAxisSize:
                                                        MainAxisSize.min,
                                                    children: [
                                                      IconButton(
                                                        icon: Icon(Icons.send),
                                                        onPressed: _isLoading
                                                            ? null
                                                            : () =>
                                                                _handleSubmit(),
                                                      ),
                                                    ],
                                                  ),
                                                  counterText: '',
                                                ),
                                                // onSubmitted: (text) {
                                                //   if (!_isLoading &&
                                                //       text.isNotEmpty) {
                                                //     _handleSubmit();
                                                //   }
                                                // },
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Padding(
                                      padding: const EdgeInsets.all(8.0),
                                      child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.end,
                                        children: [
                                          Align(
                                            alignment: Alignment.bottomLeft,
                                            child: Padding(
                                              padding: EdgeInsets.only(
                                                  left: 8, top: 4, bottom: 4),
                                              child: Text(
                                                '${_textMessageController.text.length}/$maxCharacters',
                                                style: TextStyle(
                                                    color: Colors.grey),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildQuizMode() {
    return Stack(children: [
      Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: QuizSelector(
              onQuizGenerated: (mcqs) {
                setState(() {
                  _mcqs = mcqs;
                  _showQuiz = true;
                  _isQuizMode = false;
                });
              },
              setLoadingState: setLoadingState,
              quizController: _quizController,
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
    ]);
  }

  Widget _buildStudyMode(bool isNarrowScreen) {
    // Add a variable to manage the visibility of the collapsible widget

    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (!isNarrowScreen)
          Expanded(
            flex: 3, // 3/5 of the screen
            child: DocumentPreviewer(
              pdfController: _pdfController,
              setLoadingState: setLoadingState,
              messages: messages,
              chatHistory: chatHistory,
              scrollController: _scrollController,
              onTextSelected: (selectedText) {
                setState(() {
                  _selectedText = selectedText; // Store the selected text
                  _isTextSelected = true; // Show the collapsible widget
                });
              },
            ),
          ),
        if (!isNarrowScreen)
          Expanded(
            flex: 2, // 2/5 of the screen
            child: _buildChatWindow(),
          ),
        if (isNarrowScreen)
          Expanded(
            child: DocumentPreviewer(
              pdfController: _pdfController,
              setLoadingState: setLoadingState,
              messages: messages,
              chatHistory: chatHistory,
              scrollController: _scrollController,
              onTextSelected: (selectedText) {
                setState(() {
                  _selectedText = selectedText; // Store the selected text
                  _isTextSelected = true; // Show the collapsible widget
                });
              },
            ),
          ),
      ],
    );
  }

  Widget _buildChatWindow() {
    print("Building chat window..."); // Debugging line
    print(
        "Chat history length: ${chatHistory.length}"); // Check length of chatHistory

    return Container(
      child: Stack(children: [
        Consumer<FileProvider>(
          builder: (context, fileProvider, child) {
            // Load chat history when a file is selected
            if (fileProvider.selectedFileName != null) {
              // Check if the selected file has changed
              if (!_isChatHistoryLoaded ||
                  fileProvider.selectedFileName != selectedFilePath) {
                loadChatHistory(
                    fileProvider.selectedFileName!); // Load chat history
                _isChatHistoryLoaded = true;
                selectedFilePath = fileProvider
                    .selectedFileName; // Update the selected file path
              }
            }
            return ListView.builder(
              controller: _scrollController,
              itemCount: chatHistory.length, // Use the chatHistory list
              itemBuilder: (context, index) {
                print("Building message at index: $index"); // Debugging line
                print("Message:${chatHistory[index].message}");
                print("Sender:${chatHistory[index].isSender}");
                return ChatMessage(
                  message: chatHistory[index].message,
                  isSender: chatHistory[index].isSender,
                  links: chatHistory[index].links,
                  pageContentList: chatHistory[index].pageContentList,
                  pdfViewerController: chatHistory[index].pdfViewerController,
                  videoUrl: chatHistory[index].videoUrl,
                );
              },
            );
          },
        ),
        if (_isLoading)
          Center(
            child: SpinKitThreeBounce(
              color: Colors.blue,
              size: 50.0,
            ),
          ),
      ]),
    );
  }

  void _returnToStudyMode() {
    setState(() {
      _isQuizMode = false;
      _showQuiz = false;
    });
  }

  void _handleSubmit() {
    print("Hey prakash");
    print(_textMessageController.text);
    if (!_isLoading && _textMessageController.text.isNotEmpty) {
      sendMessage_with_file(
        context,
        _textMessageController,
        messages,
        chatHistory,
        _scrollController,
        _pdfController,
        setLoadingState,
        _selectedChatType,
        () => setState(() {}), // Pass setState as a callback
      );
      // bring focus back to the input field
      Future.delayed(Duration.zero, () {
        _focusNode.requestFocus();
        _textMessageController.clear();
      });
    }
  }

  void sendMessage_with_file(
    BuildContext context,
    TextEditingController messageController,
    List<ChatMessage> messages,
    List<ChatMessage> chatHistory,
    ScrollController scrollController,
    PdfViewerController pdfController,
    Function setLoadingState,
    String chatType,
    Function updateState,
  ) {
    // Implement the logic for different chat types here
    if (chatType == 'Chat') {
      // Handle chat with file only
      ChatHelpers.sendMessage(
        context,
        messageController,
        messages,
        chatHistory,
        scrollController,
        pdfController,
        setLoadingState,
        _isTextSelected ? _selectedText : null, // Pass the selected text
      );

      // Show chat window if it's not visible on narrow screens
      if (MediaQuery.of(context).size.width < 1024 && !_isChatWindowOpen) {
        setState(() {
          _isChatWindowOpen = true;
        });
      }
    } else if (chatType == 'Web Search') {
      // Handle web search
      ChatHelpers.explainText(
        // Updated to use explainText method
        context,
        messageController.text, // Pass the text to explain
        messages, // Pass messages list
        chatHistory, // Pass chatHistory list
        _scrollController, // Pass scrollController
        _pdfController, // Pass pdfController
        setLoadingState, // Pass setLoadingState function
        _isTextSelected ? _selectedText : null, // Pass the selected text
      );
    } else if (chatType == 'Video Search') {
      // Handle video search
      ChatHelpers.videoSearch(
        // Updated to use videoSearch method
        context,
        messageController.text,
        messages, // Pass messages list
        chatHistory, // Pass chatHistory list
        _scrollController, // Pass scrollController
        _pdfController, // Pass pdfController
        setLoadingState, // Pass setLoadingState function
        _isTextSelected ? _selectedText : null, // Pass the selected text
      );
    }
  }
}
