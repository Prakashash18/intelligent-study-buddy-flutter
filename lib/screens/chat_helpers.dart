import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:chatty_teacher/services/chat_services.dart';
import 'package:chatty_teacher/screens/chat_message.dart'
    as chatMessage; // Use alias

import 'package:chatty_teacher/widgets/files_list.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart'; // Add this import

class ChatHelpers {
  static Future<void> explainText(
    BuildContext context,
    String text,
    List<chatMessage.ChatMessage> messages,
    List<chatMessage.ChatMessage> chatHistory,
    ScrollController scrollController,
    PdfViewerController pdfController,
    Function setLoadingState,
    String? selectedText, // Add this parameter
  ) async {
    final fileProvider = Provider.of<FileProvider>(context, listen: false);
    final fileName = fileProvider.selectedFileName;

    setLoadingState(true);

    try {
      // Append selected text if available
      var messageText = text;
      if (selectedText != null && selectedText.isNotEmpty) {
        messageText += "\n\nSelected Text: $selectedText";
      }

      final jsonData =
          await ChatService.explainText(messageText, chatHistory, fileName!);
      print(jsonData);

      if (jsonData.containsKey('explanation') &&
          jsonData.containsKey('links')) {
        final explanation = jsonData['explanation']['output'] as String;
        final links = jsonData['links'] as List<dynamic>;

        final explanationMessage = chatMessage.ChatMessage(
          message: explanation,
          isSender: false,
          links: links.map((link) => link as String).toList(),
        );

        messages.add(explanationMessage);
        chatHistory.add(explanationMessage);
        setLoadingState(false);

        Future.delayed(const Duration(milliseconds: 100), () {
          scrollController.animateTo(
            scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
          );
        });

        if (links.isNotEmpty) {
          print('Links: $links');
        }
      } else {
        print('Invalid response format');
        setLoadingState(false);
      }
    } catch (e) {
      print('Error explaining text: $e');
      setLoadingState(false);
    }
  }

  static void videoSearch(
    BuildContext context,
    String query,
    List<chatMessage.ChatMessage> messages,
    List<chatMessage.ChatMessage> chatHistory,
    ScrollController scrollController,
    PdfViewerController pdfController,
    Function setLoadingState,
    String? selectedText, // Add this parameter
  ) {
    setLoadingState(true);

    // Append selected text if available
    var searchQuery = query;
    if (selectedText != null && selectedText.isNotEmpty) {
      searchQuery += "\n\nSelected Text: $selectedText";
    }

    ChatService.searchVideos(searchQuery).then((videoLinks) {
      if (videoLinks.isNotEmpty) {
        final explanationMessage = chatMessage.ChatMessage(
          message: "The following video links are found:\n",
          isSender: false,
          pdfViewerController: pdfController,
          videoUrl: videoLinks,
        );

        messages.add(explanationMessage);
        chatHistory.add(explanationMessage);
        setLoadingState(false);

        Future.delayed(const Duration(milliseconds: 100), () {
          scrollController.animateTo(
            scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
          );
        });
      } else {
        final explanationMessage = chatMessage.ChatMessage(
            message: "No relevant video links found.", isSender: false);
        messages.add(explanationMessage);
        chatHistory.add(explanationMessage);
        setLoadingState(false);

        Future.delayed(const Duration(milliseconds: 100), () {
          scrollController.animateTo(
            scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
          );
        });
      }
    }).catchError((error) {
      print('Error searching videos: $error');
      setLoadingState(false);
    });
  }

  static Future<void> sendMessage(
    BuildContext context,
    TextEditingController messageController,
    List<chatMessage.ChatMessage> messages,
    List<chatMessage.ChatMessage> chatHistory,
    ScrollController scrollController,
    PdfViewerController pdfController,
    Function setLoadingState,
    String? selectedText, // Add this parameter
  ) async {
    print("sendMessage called");

    setLoadingState(true);

    final fileProvider = Provider.of<FileProvider>(context, listen: false);
    final fileName = fileProvider.selectedFileName;

    print(fileName);
    print(messageController.text.trim());

    if (messageController.text.trim().isNotEmpty && fileName != null) {
      // Append selected text if available
      var messageText = messageController.text.trim(); // Change final to var

      if (selectedText != null && selectedText.isNotEmpty) {
        messageText +=
            "\n\nSelected Text: $selectedText"; // Append selected text
      }

      final message = chatMessage.ChatMessage(
        message: messageText,
        isSender: true,
      );
      messages.add(message); // Add the message here
      chatHistory.add(message);
      messageController.clear();
      print("Message sent: ${messageController.text.trim()}");

      Future.delayed(const Duration(milliseconds: 100), () {
        scrollController.animateTo(
          scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
      });

      try {
        final jsonData =
            await ChatService.sendMessage(fileName, messageText, chatHistory);

        setLoadingState(
            false); // Set loading state to false after receiving response

        if (jsonData.containsKey('output')) {
          final answer = jsonData['output'];
          print("hey: $answer");
          if (jsonData.containsKey('context') &&
              jsonData['context'].isNotEmpty) {
            try {
              print("Heyhbejkbkjbe");
              final pageContentList = jsonData['context']
                  .where((page) =>
                      page is Map<String, dynamic> &&
                      page.containsKey('page_content'))
                  .map((page) => {
                        'page_content': page['page_content'] as String?,
                        'page_number': page['page_number'] as int?
                      })
                  .toList();
              print("Heyhbejkbkjbe  2222");

              final aiResponse = chatMessage.ChatMessage(
                message: answer,
                isSender: false,
                pageContentList: pageContentList,
                pdfViewerController: pdfController,
              );

              messages.add(aiResponse);
              chatHistory.add(aiResponse);

              Future.delayed(const Duration(milliseconds: 100), () {
                scrollController.animateTo(
                  scrollController.position.maxScrollExtent,
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOut,
                );
              });
            } catch (e) {
              print(e);
            }
          } else {
            final aiResponse = chatMessage.ChatMessage(
              message: answer,
              isSender: false,
              pageContentList: null,
              pdfViewerController: pdfController,
            );

            messages.add(aiResponse);
            chatHistory.add(aiResponse);

            Future.delayed(const Duration(milliseconds: 100), () {
              scrollController.animateTo(
                scrollController.position.maxScrollExtent,
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut,
              );
            });
          }
        }

        // if (jsonData.containsKey('output')) {
        //   final answer = jsonData['output'];
        //   print(answer);
        //   if (answer.containsKey('context')) {
        //     try {
        //       final pageContentList = answer['context']
        //           .where((page) =>
        //               page is Map<String, dynamic> &&
        //               page.containsKey('page_content'))
        //           .map((page) => {
        //                 'page_content': page['page_content'] as String?,
        //                 'page_number': page['page_number'] as int?
        //               })
        //           .toList();
        //       if (answer['output'].isNotEmpty) {
        //         print(answer['output']);
        //         if (answer.containsKey('message')) {
        //           final aiResponse = chatMessage.ChatMessage(
        //             message: answer['message'],
        //             isSender: false,
        //             pageContentList: pageContentList,
        //             pdfViewerController: pdfController,
        //           );

        //           messages.add(aiResponse);
        //           chatHistory.add(aiResponse);
        //           print("AI response: ${answer['output']}");

        //           Future.delayed(const Duration(milliseconds: 100), () {
        //             scrollController.animateTo(
        //               scrollController.position.maxScrollExtent,
        //               duration: const Duration(milliseconds: 300),
        //               curve: Curves.easeInOut,
        //             );
        //           });
        //         } else {
        //           print("No message key found in jsonData.");
        //         }
        //       } else {
        //         print("AI response is empty.");
        //       }
        //     } catch (e) {
        //       print(e);
        //     }
        //   }
        // } else if (jsonData.containsKey('message')) {
        //   final errorMessage =
        //       chatMessage.ChatMessage(message: jsonData['message'], isSender: false);
        //   messages.add(errorMessage);
        //   print("Error: ${jsonData['message']}");
        // } else {
        //   print("No appropriate key found in jsonData.");
        // }
      } catch (e) {
        print('Error sending message: $e');
      }
    }
  }

  static Future<void> loadChatHistory(
    String fileName,
    Function(List<chatMessage.ChatMessage>) updateMessages,
    ScrollController scrollController,

    // Use alias here
  ) async {
    final chatHistory = await ChatService.loadChatHistory(
        fileName); // Use ChatService to load chat history
    print("ChatHistory Raw:$chatHistory");
    Future.delayed(const Duration(milliseconds: 100), () {
      scrollController.animateTo(
        scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    });
    updateMessages(chatHistory); // Update messages with the loaded chat history
  }
}
