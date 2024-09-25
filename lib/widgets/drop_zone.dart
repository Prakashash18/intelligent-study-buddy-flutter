import 'package:chatty_teacher/model/dropped_file.dart';
import 'package:chatty_teacher/widgets/files_list.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dropzone/flutter_dropzone.dart';
import 'package:provider/provider.dart';
import 'package:dotted_border/dotted_border.dart'; // Import dotted_border
import 'package:file_picker/file_picker.dart'; // Import file_picker
import 'dart:io' as io;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:universal_html/html.dart' as html;

import 'package:flutter_spinkit/flutter_spinkit.dart'; // Import flutter_spinkit
import 'package:chatty_teacher/services/chat_services.dart'; // Import ChatService

class DropZoneWidget extends StatefulWidget {
  const DropZoneWidget({Key? key}) : super(key: key);

  @override
  _DropZoneWidgetState createState() => _DropZoneWidgetState();
}

class _DropZoneWidgetState extends State<DropZoneWidget> {
  late DropzoneViewController controller;
  bool _isLoading = false; // Add a loading state

  // Dynamically adjust icon and text sizes based on screen size
  double _iconSize = 100;
  double _textSize = 20;

  bool _isHovering = false;

  @override
  void initState() {
    super.initState();
    // Calculate icon and text sizes based on screen size
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final screenSize = MediaQuery.of(context).size;
      setState(() {
        _iconSize = screenSize.width * 0.2; // Adjust multiplier as needed
        _textSize = screenSize.width * 0.05; // Adjust multiplier as needed
        // Set maximum sizes for icon and text
        _iconSize = _iconSize > 80 ? 80 : _iconSize; // Max icon size 80
        _textSize = _textSize > 16 ? 16 : _textSize; // Max text size 16
      });
    });
  }

  Future<void> _pickFiles() async {
    try {
      if (kIsWeb) {
        // Web file picking
        FilePickerResult? result = await FilePicker.platform.pickFiles(
          allowMultiple: true,
          type: FileType.custom,
          allowedExtensions: ['pdf'],
        );

        if (result != null) {
          for (var file in result.files) {
            await acceptFiles(file);
          }
        }
      } else {
        // Mobile file picking
        FilePickerResult? result = await FilePicker.platform.pickFiles(
          allowMultiple: true,
          type: FileType.custom,
          allowedExtensions: ['pdf'],
        );

        if (result != null) {
          for (var file in result.files) {
            final ioFile = io.File(file.path!);
            await acceptFiles(ioFile);
          }
        }
      }
    } catch (e) {
      print("Error picking files: $e");
    } finally {
      setState(() {
        _isLoading = false; // Hide loading indicator
      });
    }
  }

  Future acceptFiles(dynamic event) async {
    setState(() {
      _isLoading = true; // Show loading indicator
    });
    setState(() {
      _isHovering = false;
    });

    try {
      if (kIsWeb) {
        // Web-specific handling
        final file = event as PlatformFile;
        final bytes = file.bytes;
        final name = file.name;
        final mime = file.extension;
        final size = file.size;
        final url = html.Url.createObjectUrlFromBlob(html.Blob([bytes]));

        print(name);
        print(mime);
        print(size);
        print(url);

        // Check MIME type
        if (mime == 'pdf') {
          final droppedFile = DroppedFile(
            url: url,
            name: name,
            mime: mime!,
            size: size,
            uploadedDateTime: DateTime.now(),
          );

          print("Here");
          // Create the File object using the file path
          final response =
              await ChatService.uploadFileWeb(bytes!, name, context);

          // Handle the response
          if (response == 'File already exists') {
            // Show a dialog if the file already exists
            showDialog(
              context: context,
              builder: (BuildContext context) {
                return AlertDialog(
                  title: Text('File Already Exists'),
                  content: Text(
                      'A file with the same name already exists on the server.'),
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
          } else {
            // Refresh the files list
            Provider.of<FileProvider>(context, listen: false).refreshFiles();
          }

          print("Created dropped file using url");
        } else {
          // Show a dialog if the MIME type is not allowed
          showDialog(
            context: context,
            builder: (BuildContext context) {
              return AlertDialog(
                title: Text('Invalid File Type'),
                content: Text('Please upload a PDF file.'),
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
      } else {
        // Mobile-specific handling
        final names = event.name;
        final mime = await controller.getFileMIME(event);
        final size = await controller.getFileSize(event);
        final url = await controller.createFileUrl(event);

        print(names);
        print(mime);
        print(size);
        print(url);

        // Check MIME type
        if (mime == 'application/pdf') {
          final droppedFile = DroppedFile(
            url: url,
            name: names,
            mime: mime,
            size: size,
            uploadedDateTime: DateTime.now(),
          );

          print("Here");
          // Create the File object using the file path
          final bytes = await controller.getFileData(event);
          final response = await ChatService.uploadFile(
              bytes, droppedFile.name, mime, context);

          // Handle the response
          if (response == 'File already exists') {
            // Show a dialog if the file already exists
            showDialog(
              context: context,
              builder: (BuildContext context) {
                return AlertDialog(
                  title: Text('File Already Exists'),
                  content: Text(
                      'A file with the same name already exists on the server.'),
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
          } else {
            // Refresh the files list
            Provider.of<FileProvider>(context, listen: false).refreshFiles();
          }

          print("Created dropped file using url");
        } else {
          // Show a dialog if the MIME type is not allowed
          showDialog(
            context: context,
            builder: (BuildContext context) {
              return AlertDialog(
                title: Text('Invalid File Type'),
                content: Text('Please upload a PDF file.'),
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
    } catch (e) {
      // Show a dialog if there is an error
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text('Error'),
            content: Text('An error occurred while uploading the file: $e'),
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
    } finally {
      setState(() {
        _isLoading = false; // Hide loading indicator
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Container(
          padding: const EdgeInsets.all(5),
          height: 100,
          decoration: BoxDecoration(
            color: _isHovering
                ? Colors.green
                : Colors.blue, // Change color on hover
            borderRadius: BorderRadius.circular(10),
            boxShadow: [
              BoxShadow(
                blurRadius: 8,
                color: Colors.black.withOpacity(0.2),
                spreadRadius: 2,
                offset: Offset(0, 2),
              )
            ],
          ),
          // Adjust for desired dot size and spacing
          child: DottedBorder(
            color: Colors.white, // Color of the dotted border
            strokeWidth: 2, // Thickness of the border
            dashPattern: [10, 4], // Pattern of dashes and spaces
            child: Stack(
              children: [
                DropzoneView(
                  onCreated: (controller) => this.controller = controller,
                  onDrop: acceptFiles,
                  onHover: () {
                    setState(() {
                      _isHovering = true;
                    });
                  },
                  onLeave: () => setState(() {
                    _isHovering = false;
                  }),
                ),
                Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 10,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        icon: Icon(Icons.upload),
                        label: Text(
                          "Upload Notes",
                          style: TextStyle(
                            color: Colors.black,
                            fontSize: _textSize,
                          ),
                        ),
                        onPressed: _pickFiles,
                      ),
                      const SizedBox(height: 10),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        if (_isLoading)
          Center(
            child: SpinKitThreeBounce(
              color: Colors.white,
              size: 50.0,
            ),
          ),
      ],
    );
  }
}
