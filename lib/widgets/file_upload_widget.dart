import 'package:flutter/material.dart';
import 'package:chatty_teacher/widgets/drop_zone.dart';
import 'package:chatty_teacher/widgets/files_list.dart';

class FileUploadWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        DropZoneWidget(),
        SizedBox(
          width: 20,
        ),
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Text(
            "Uploaded Files:",
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        FilesWidget()
      ],
    );
  }
}
