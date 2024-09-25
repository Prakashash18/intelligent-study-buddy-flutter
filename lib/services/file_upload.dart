import 'dart:io';
import 'package:http/http.dart' as http;



Future<void> uploadFile(File file) async {
  // Replace with your actual API endpoint
  final apiEndpoint = 'http://localhost:8000/upload_file';

  try {
    // Check if the file exists and is readable
    if (!file.existsSync()) {
      print('Error: File does not exist or is not readable: ${file.path}');
    }

    // Create a multipart request
    final request = http.MultipartRequest('POST', Uri.parse(apiEndpoint));

    // Add the file to the request
    request.files.add(http.MultipartFile(
      'file',
      file.readAsBytes().asStream(),
      file.lengthSync(),
      filename: file.path.split('/').last,
    ));

    print("Inside file upload $file");

    // Send the request
    final response = await request.send();

    // Check for success
    if (response.statusCode == 200) {
      // Handle successful upload
      final responseBody = await response.stream.bytesToString();
      print('File uploaded successfully: $responseBody');
    } else {
      // Handle error
      print('Error uploading file: ${response.statusCode}');
    }
  } catch (error) {
    print('Error uploading file: $error');
  }
}
