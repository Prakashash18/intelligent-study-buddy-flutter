import 'dart:typed_data';

import 'package:chatty_teacher/screens/chat_message.dart';
import 'package:chatty_teacher/widgets/file_upload_widget.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart'; // Import Syncfusion PDF viewer
import 'package:lottie/lottie.dart';
import 'package:chatty_teacher/services/chat_services.dart';
import 'package:chatty_teacher/widgets/files_list.dart';

class DocumentPreviewer extends StatefulWidget {
  // Change to StatefulWidget
  final PdfViewerController pdfController; // Use Syncfusion PdfViewerController
  final Function setLoadingState;
  final List<ChatMessage> messages;
  final List<ChatMessage> chatHistory;
  final ScrollController scrollController;
  final Function(String) onTextSelected; // Add this line

  const DocumentPreviewer({
    // Keep const constructor
    Key? key,
    required this.pdfController,
    required this.setLoadingState,
    required this.messages,
    required this.chatHistory,
    required this.scrollController,
    required this.onTextSelected, // Add this line
  }) : super(key: key);

  @override
  _DocumentPreviewerState createState() =>
      _DocumentPreviewerState(); // Create state
}

class _DocumentPreviewerState extends State<DocumentPreviewer> {
  OverlayEntry? _overlayEntry; // Move overlayEntry to state

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(10),
      child: Consumer<FileProvider>(
        builder: (context, fileProvider, _) {
          print(fileProvider.selectedFileName);
          return fileProvider.selectedFileName != null
              ? FutureBuilder<Uint8List>(
                  future:
                      ChatService.downloadFile(fileProvider.selectedFileName!),
                  builder: (context, snapshot) {
                    if (snapshot.hasData) {
                      final pdfData = snapshot.data!;
                      return SfPdfViewer.memory(
                        pdfData,
                        controller:
                            widget.pdfController, // Use widget.pdfController
                        onDocumentLoaded: (details) {
                          // Handle document loaded
                        },
                        onPageChanged: (details) {
                          // Handle page changed
                        },
                        onTextSelectionChanged:
                            (PdfTextSelectionChangedDetails details) {
                          if (details.selectedText == null) {
                            if (_overlayEntry != null) {
                              _overlayEntry!.remove();
                              _overlayEntry = null; // Set to null after removal
                            }
                          } else if (details.selectedText != null &&
                              _overlayEntry == null) {
                            _showCustomContextMenu(
                                context, details, widget.onTextSelected);
                          }
                          // if (details.selectedText != null) {
                          //   _showCustomContextMenu(context, details);
                          // }
                        },
                        canShowTextSelectionMenu: false, // Disable default menu
                      );
                    } else if (snapshot.hasError) {
                      return Center(child: Text('Error loading file'));
                    } else {
                      return Center(child: CircularProgressIndicator());
                    }
                  },
                )
              : Center(
                  child: Column(
                    children: [
                      LayoutBuilder(
                        builder:
                            (BuildContext context, BoxConstraints constraints) {
                          final double screenWidth =
                              MediaQuery.of(context).size.width;
                          final String animationFile = fileProvider
                                  .files.isEmpty
                              ? "attach_file.json" // Show attach file animation if no file uploaded
                              : "select_file.json"; // Show select file animation if a file is uploaded
                          Widget content = Column(
                            children: [
                              Lottie.asset(
                                animationFile,
                                height: 60,
                                width: 60,
                              ),
                              Text(fileProvider.files.isEmpty
                                  ? 'Please upload a PDF' // Prompt to upload PDF
                                  : 'Select a file'), // Prompt to select file
                            ],
                          );

                          if (screenWidth < 1024) {
                            content = GestureDetector(
                              onTap: () {
                                showModalBottomSheet(
                                  context: context,
                                  builder: (context) => FileUploadWidget(),
                                );
                              },
                              child: content,
                            );
                          }

                          return content;
                        },
                      ),
                    ],
                  ),
                );
        },
      ),
    );
  }

  void _showCustomContextMenu(BuildContext context,
      PdfTextSelectionChangedDetails details, Function(String) onTextSelected) {
    // Implement your custom context menu logic here
    final overlay = Overlay.of(context);
    _overlayEntry = OverlayEntry(
      // Use _overlayEntry from state
      builder: (context) {
        return Positioned(
          top: details.globalSelectedRegion!.top,
          left: details.globalSelectedRegion!.left,
          child: Material(
            color: Colors.blue, // Change background color here
            child: Column(
              children: [
                TextButton(
                  onPressed: () {
                    // Handle "Add to Chat" action
                    print('Added to chat: ${details.selectedText}');
                    onTextSelected(
                        details.selectedText!); // Pass selected text back
                    _overlayEntry?.remove(); // Remove overlay after action
                    _overlayEntry = null; // Set to null after removal
                  },
                  child: Text(
                    'Add to Chat',
                    style: TextStyle(
                        color: Colors.black), // Change text color to black
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );

    overlay
        .insert(_overlayEntry!); // Insert the overlay entry after declaration
  }
}
