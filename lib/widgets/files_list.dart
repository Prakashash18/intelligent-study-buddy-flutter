import 'dart:math'; // Import the math library

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'dart:convert';

// ignore: avoid_web_libraries_in_flutter
import 'dart:html';
import 'package:provider/provider.dart'; // Import Provider
import '../services/chat_services.dart'; // Import ChatService

class FilesWidget extends StatefulWidget {
  const FilesWidget({Key? key}) : super(key: key);

  @override
  State<FilesWidget> createState() => _FilesWidgetState();
}

class _FilesWidgetState extends State<FilesWidget> {
  @override
  void initState() {
    super.initState();
    print("Trying to fetch");
    _fetchFiles();
  }

  Future<void> _fetchFiles() async {
    try {
      final files = await ChatService.fetchFiles();
      print('Fetched files: $files');
      Provider.of<FileProvider>(context, listen: false).setFiles(files);
      Provider.of<FileProvider>(context, listen: false)
          .refreshFiles(); // Refresh files after fetching
    } catch (e) {
      print('Error fetching files: $e');
    }
  }

  String bytesFormat(int? bytes) {
    if (bytes == null) {
      return '0 B';
    }
    const suffixes = ['B', 'KB', 'MB', 'GB', 'TB'];
    var i = (bytes == 0) ? 0 : (log(bytes) / log(1024)).floor();
    var size = bytes / pow(1024, i);
    return '${size.toStringAsFixed(2)} ${suffixes[i]}';
  }

  Future<void> _deleteFile(String fileName) async {
    try {
      await ChatService.deleteFile(fileName);
      _fetchFiles(); // Refresh the file list
      print('File deleted successfully');
    } catch (e) {
      print('Error deleting file: $e');
    }
  }

  Future<void> _downloadFile(String fileName) async {
    try {
      final bytes = await ChatService.downloadFile(fileName);
      final _base64 = base64Encode(bytes);
      final anchor =
          AnchorElement(href: 'data:application/octet-stream;base64,$_base64')
            ..target = 'blank'
            ..download = fileName;
      document.body?.append(anchor);
      anchor.click();
      anchor.remove();
    } catch (e) {
      print('Error downloading file: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 0, horizontal: 10),
        child: Consumer<FileProvider>(builder: (context, fileProvider, child) {
          if (fileProvider.files.isEmpty) {
            return Center(
                child: Text(
              'Upload a PDF file to get started',
              style: TextStyle(fontSize: 16),
            ));
          }
          return ListView.builder(
            itemCount: fileProvider.files.length,
            itemBuilder: (context, index) {
              final fileData = fileProvider.files[index];
              final fileName = fileData['file_name'] ?? 'Unknown';
              final fileSize = bytesFormat(fileData['file_size']);
              final uploadedDateTime = fileData['upload_datetime'] != null
                  ? DateTime.parse(fileData['upload_datetime'])
                  : DateTime.now();

              return Dismissible(
                key: Key(fileName),
                onDismissed: (direction) {
                  // Show confirmation dialog before deleting
                  showDialog(
                    context: context,
                    builder: (BuildContext context) {
                      return AlertDialog(
                        title: Text('Confirm Delete'),
                        content: Text(
                            'Are you sure you want to delete "$fileName"? This action cannot be undone.'),
                        actions: <Widget>[
                          TextButton(
                            child: Text('Cancel'),
                            onPressed: () {
                              Navigator.of(context).pop();
                              // Restore the dismissed item
                              setState(() {});
                            },
                          ),
                          TextButton(
                            child: Text('Delete'),
                            onPressed: () {
                              Navigator.of(context).pop();
                              _deleteFile(fileName);
                            },
                          ),
                        ],
                      );
                    },
                  );
                },
                background: Container(
                  color: Colors.red,
                  alignment: AlignmentDirectional.centerEnd,
                  child: Icon(Icons.delete, color: Colors.white),
                ),
                child: Container(
                  decoration: BoxDecoration(
                    color: fileProvider.selectedFileName == fileName
                        ? Colors.blue[100]
                        : Colors.grey[200], // Change color if selected
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: ListTile(
                          title: Text(fileName,
                              style: TextStyle(
                                  fontSize: 18, fontWeight: FontWeight.bold)),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(fileSize),
                              Text(
                                  'Uploaded: ${DateFormat('MMM dd, yyyy  h:mm a').format(uploadedDateTime)}'),
                            ],
                          ),
                          onTap: () {
                            //todo
                            print(fileName);
                            if (fileProvider.selectedFileName == fileName) {
                              Provider.of<FileProvider>(context, listen: false)
                                  .selectedFileName = null;
                            } else {
                              Provider.of<FileProvider>(context, listen: false)
                                  .selectedFileName = fileName;
                            }
                          },
                        ),
                      ),
                      IconButton(
                        icon: Icon(
                          fileProvider.selectedFileName == fileName
                              ? Icons.check_circle
                              : Icons
                                  .check_circle_outline, // Change icon based on selection
                          color: fileProvider.selectedFileName == fileName
                              ? Colors.blue
                              : Colors
                                  .grey, // Change icon color based on selection
                        ),
                        onPressed: () {
                          // Toggle selection
                          if (fileProvider.selectedFileName == fileName) {
                            Provider.of<FileProvider>(context, listen: false)
                                .selectedFileName = null;
                          } else {
                            Provider.of<FileProvider>(context, listen: false)
                                .selectedFileName = fileName;
                          }
                        },
                      ),
                      IconButton(
                        icon: Icon(Icons.download),
                        onPressed: () {
                          _downloadFile(fileName);
                        },
                      ),
                      IconButton(
                        icon: Icon(Icons.cancel),
                        onPressed: () {
                          // Implement logic to remove file from server
                          _deleteFile(fileName);
                        },
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        }),
      ),
    );
  }
}

class FileProvider extends ChangeNotifier {
  List<dynamic> _files = [];
  String? _selectedFileName;

  List<dynamic> get files => _files;
  String? get selectedFileName => _selectedFileName;
  set selectedFileName(String? value) {
    _selectedFileName = value;
    notifyListeners();
  }

  void setFiles(List<dynamic> files) {
    _files = files;
    notifyListeners();
  }

  void refreshFiles() {
    print("Inside refreshFiles");
    ChatService.fetchFiles().then((files) {
      setFiles(files);
    }).catchError((e) {
      print('Error refreshing files: $e');
    });
  }
}
