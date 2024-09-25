import 'package:chatty_teacher/screens/chat_message.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:typed_data'; // Import for Uint8List
import 'package:http_parser/http_parser.dart';
import 'package:flutter/material.dart'; // Import for showing dialogs

class ChatService {
  // Base URL for your API
  // static const String baseUrl = "https://study-buddy-backend-2-ca808db2e238.herokuapp.com";
  static const String baseUrl = "http://127.0.0.1:8000";

  // Method to get the ID token
  static Future<String> getIdToken() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final idToken = await user.getIdToken();
      if (idToken != null) {
        return idToken;
      } else {
        throw Exception('Failed to retrieve ID token');
      }
    } else {
      throw Exception('User not logged in');
    }
  }

  // Method to get the user ID
  static Future<String> getUserId() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      return user.uid; // Return the user ID
    } else {
      throw Exception('User not logged in');
    }
  }

  // Method to ask for explanation
  static Future<Map<String, dynamic>> askForExplanation(
      Map<String, dynamic> questionData) async {
    final idToken = await getIdToken();
    final response = await http.post(
      Uri.parse('$baseUrl/explain'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $idToken',
      },
      body: jsonEncode({
        'question': questionData['question'],
        'options': questionData['options'],
        'correctAnswer': questionData['correctAnswer'],
      }),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to get explanation: ${response.statusCode}');
    }
  }

  // Method to fetch files
  static Future<List<dynamic>> fetchFiles() async {
    try {
      final idToken = await getIdToken();
      final response = await http.get(
        Uri.parse('$baseUrl/files'),
        headers: {
          'Authorization': 'Bearer $idToken',
        },
      );

      if (response.statusCode == 200) {
        print(response.body);
        return jsonDecode(response.body) as List<dynamic>;
      } else {
        throw Exception('Failed to fetch files: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching files: $e');
      rethrow;
    }
  }

  // Method to delete a file
  static Future<void> deleteFile(String fileName) async {
    final idToken = await getIdToken();
    final response = await http.delete(
      Uri.parse('$baseUrl/delete/$fileName'),
      headers: {
        'Authorization': 'Bearer $idToken',
      },
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to delete file: ${response.statusCode}');
    }
  }

  // Method to download a file
  static Future<Uint8List> downloadFile(String fileName) async {
    final idToken = await getIdToken();
    final response = await http.get(
      Uri.parse('$baseUrl/download/$fileName'),
      headers: {
        'Authorization': 'Bearer $idToken',
      },
    );

    if (response.statusCode == 200) {
      return response.bodyBytes;
    } else {
      throw Exception('Failed to download file: ${response.statusCode}');
    }
  }

  // Method to upload a file (Web)
  static Future<String> uploadFileWeb(
      Uint8List bytes, String fileName, BuildContext context) async {
    final idToken = await getIdToken();
    final uri =
        Uri.parse('$baseUrl/upload_file'); // Replace with your server URL

    final request = http.MultipartRequest('POST', uri);

    // Add the file to the request
    request.files.add(http.MultipartFile.fromBytes(
      'file',
      bytes,
      filename: fileName,
      contentType: MediaType('application', 'octet-stream'),
    ));

    request.headers['Authorization'] = 'Bearer $idToken';

    final response = await request.send();
    final responseBody = await response.stream.bytesToString();
    final responseData = jsonDecode(responseBody);

    if (response.statusCode == 200) {
      return responseData['message'];
    } else {
      throw Exception(
          'Failed to upload file: ${response.statusCode}, ${responseData['message']}');
    }
  }

  // Method to upload a file (Mobile)
  static Future<String> uploadFile(Uint8List bytes, String fileName,
      String mime, BuildContext context) async {
    final idToken = await getIdToken();
    final uri =
        Uri.parse('$baseUrl/upload_file'); // Replace with your server URL

    final request = http.MultipartRequest('POST', uri);

    // Add the file to the request
    request.files.add(http.MultipartFile.fromBytes(
      'file',
      bytes,
      filename: fileName,
      contentType: MediaType.parse(mime),
    ));

    request.headers['Authorization'] = 'Bearer $idToken';

    final response = await request.send();
    final responseBody = await response.stream.bytesToString();
    final responseData = jsonDecode(responseBody);

    if (response.statusCode == 200) {
      return responseData['message'];
    } else {
      throw Exception(
          'Failed to upload file: ${response.statusCode}, ${responseData['message']}');
    }
  }

  // Method to send a message to the chatbot
  static Future<Map<String, dynamic>> sendMessage(
      String fileName, String message, List<dynamic> chatHistory) async {
    final url = Uri.parse('$baseUrl/ask/$fileName');
    final idToken = await getIdToken();

    final response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $idToken',
      },
      body: jsonEncode({
        'question': message,
        'chat_history': chatHistory
            .map((msg) => {
                  'role': msg.isSender ? 'user' : 'assistant',
                  'content': msg.message,
                })
            .toList(),
      }),
    );

    if (response.statusCode == 200) {
      print(response.body);
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to send message: ${response.statusCode}');
    }
  }

  // Method to explain a text
  static Future<Map<String, dynamic>> explainText(
      String text, List<dynamic> chatHistory, String fileName) async {
    final url = Uri.parse('$baseUrl/explain/$fileName');
    final idToken = await getIdToken();
    final response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $idToken',
      },
      body: jsonEncode({
        'question': text,
        'chat_history': chatHistory
            .map((msg) => {
                  'role': msg.isSender ? 'user' : 'assistant',
                  'content': msg.message,
                })
            .toList(),
      }),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to explain text: ${response.statusCode}');
    }
  }

  // Method to fetch quiz questions
  static Future<Map<String, dynamic>> fetchQuizQuestions(
      String fileName, int difficulty, int numQuestions) async {
    final url = Uri.parse('$baseUrl/generate-mcqs');
    final idToken = await getIdToken();

    // Convert difficulty integer to string
    String difficultyStr;
    switch (difficulty) {
      case 1:
        difficultyStr = 'easy';
        break;
      case 2:
        difficultyStr = 'medium';
        break;
      case 3:
        difficultyStr = 'hard';
        break;
      default:
        throw Exception('Invalid difficulty level');
    }

    final response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $idToken',
      },
      body: jsonEncode({
        'filename': fileName,
        'difficulty': difficultyStr, // Use the string value
        'num_questions': numQuestions,
      }),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception(
          'Failed to fetch quiz questions: ${response.statusCode}, ${response.body}');
    }
  }

  // Method to search videos
  static Future<List<String>> searchVideos(String query) async {
    final url = Uri.parse('$baseUrl/video_search');
    final idToken = await getIdToken(); // Get the ID token
    final response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $idToken', // Add the Authorization header
      },
      body: jsonEncode({'query': query}),
    );

    if (response.statusCode == 200) {
      final Map<String, dynamic> data = jsonDecode(response.body);
      final videoLinks = data['video_links'];
      if (videoLinks is List) {
        return videoLinks.whereType<String>().toList();
      } else {
        return [];
      }
    } else {
      throw Exception('Failed to search videos');
    }
  }

  static Future<List<ChatMessage>> loadChatHistory(String fileName) async {
    final idToken = await getIdToken(); // Fetch ID token for authorization
    final response = await http.get(
      Uri.parse('$baseUrl/chat_history/$fileName'), // Updated URI
      headers: {
        'Authorization': 'Bearer $idToken', // Add the Authorization header
      },
    );

    if (response.statusCode == 200) {
      final List<dynamic> chatHistoryJson =
          json.decode(response.body)['chat_history'];
      print("ChatHistory Raw:$chatHistoryJson");
      return chatHistoryJson.map((json) => ChatMessage.fromJson(json)).toList();
    } else {
      print('Failed to load chat history: ${response.statusCode}');
      return []; // Return an empty list on failure
    }
  }
}
