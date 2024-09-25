import 'package:flutter/material.dart';
import 'package:expandable/expandable.dart';
import 'package:lottie/lottie.dart';
import 'package:flutter_markdown/flutter_markdown.dart'; // Import for Markdown rendering
import 'package:flutter_markdown_latex/flutter_markdown_latex.dart';
import 'package:markdown/markdown.dart' as md;
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart'; // Add this import
import 'package:url_launcher/url_launcher.dart'; // Import the url_launcher package

class ChatMessage extends StatefulWidget {
  final String message; // Changed from Stream<String> to String
  final bool isSender;
  final List<dynamic>? pageContentList;
  final PdfViewerController? pdfViewerController;
  final List<String>? links;
  final List<String>? videoUrl;

  ChatMessage({
    required this.message, // Updated constructor parameter
    required this.isSender,
    this.pageContentList,
    this.pdfViewerController,
    this.links,
    this.videoUrl,
  });

  // Add this factory constructor for fromJson
  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      message: json['content'], // Adjust based on your JSON structure
      isSender: json['role'] == 'user', // Adjust based on your JSON structure
      // Initialize other fields if necessary
    );
  }

  @override
  _ChatMessageState createState() => _ChatMessageState();
}

class _ChatMessageState extends State<ChatMessage> {
  String _message = ""; // Holds the current state of the message being built

  @override
  Widget build(BuildContext context) {
    _message = widget.message; // Directly assign the message

    final availableWidth = MediaQuery.of(context).size.width;
    print("Available Width: $availableWidth"); // Debugging line
    print("Message: $_message"); // Debugging line

    final margin = widget.isSender
        ? EdgeInsets.symmetric(
            vertical: 8,
            horizontal: availableWidth * 0.01) // Adjusted horizontal margin
        : EdgeInsets.symmetric(
            vertical: 8,
            horizontal: availableWidth * 0.01); // Adjusted horizontal margin

    double fontSize = 16;
    if (availableWidth < 1024) {
      fontSize = 12;
    } else if (availableWidth > 1024) {
      fontSize = 16;
    }

    return Container(
      width: double.infinity,
      margin: margin,
      padding: EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: widget.isSender ? Colors.blue[200] : Colors.grey[200],
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisAlignment: widget.isSender
            ? MainAxisAlignment.end
            : MainAxisAlignment.start, // Align based on sender
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Avatar Image with Lottie Animation
          Container(
            height: 40,
            width: 40,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white,
            ),
            child: Center(
              child: Lottie.asset(
                widget.isSender
                    ? 'assets/images/human_animation.json'
                    : 'assets/images/ai_animation.json',
                height: 30,
                width: 30,
                fit: BoxFit.cover,
              ),
            ),
          ),
          SizedBox(width: 10),
          Expanded(
            child: Container(
              width: availableWidth *
                  0.9, // Adjusted width for better responsiveness
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (_message.contains('#') ||
                      _message.contains('*') ||
                      _message.contains('`') ||
                      _message.contains('\\') ||
                      _message.contains('['))
                    MarkdownBody(
                      selectable: true,
                      data: _message,
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
                      styleSheet: MarkdownStyleSheet(
                        p: TextStyle(
                          fontFamily:
                              'NotoColorEmoji', // Updated font family for Markdown
                          fontSize: 16,
                        ),
                      ),
                    )
                  else
                    RichText(
                      text: TextSpan(
                        text: _message,
                        style: TextStyle(
                          fontSize: fontSize,
                          fontFamily:
                              'NotoColorEmoji', // Updated font family to NotoColorEmoji
                        ),
                      ),
                    ),
                  if (widget.pageContentList != null)
                    for (final pageContent in widget.pageContentList!)
                      if (pageContent.containsKey('page_content'))
                        Column(
                          children: [
                            Divider(),
                            ExpandablePanel(
                              header: Text('From Notes',
                                  style:
                                      TextStyle(fontWeight: FontWeight.bold)),
                              collapsed: SizedBox(
                                width: availableWidth * 0.5,
                                child: Text(
                                  pageContent['page_content'] != null
                                      ? _truncateText(
                                          pageContent['page_content']!,
                                          maxLength: 50,
                                        )
                                      : 'No page content available',
                                  softWrap: true,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              expanded: SizedBox(
                                width: availableWidth * 0.5,
                                child: Text(
                                  pageContent['page_content'] != null
                                      ? pageContent['page_content']!
                                      : 'No page content available',
                                  softWrap: true,
                                ),
                              ),
                              theme: ExpandableThemeData(
                                tapBodyToCollapse: true,
                                scrollAnimationDuration:
                                    Duration(milliseconds: 200),
                                hasIcon: false,
                                iconColor: Colors.lightBlue[100],
                              ),
                            ),
                            if (widget.pdfViewerController != null &&
                                pageContent.containsKey('page_number'))
                              TextButton(
                                onPressed: () {
                                  // Jump to the specified page
                                  widget.pdfViewerController!
                                      .jumpToPage(pageContent['page_number']);
                                },
                                child: Text('Jump to Page'),
                              ),
                          ],
                        ),
                  if (widget.links != null && widget.links!.isNotEmpty)
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(height: 8),
                        Text('Links:',
                            style: TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 14)),
                        for (final link in widget.links!)
                          Column(
                            children: [
                              Divider(),
                              TextButton(
                                onPressed: () {
                                  launchUrl(Uri.parse(link));
                                },
                                child: Text(link,
                                    style: TextStyle(
                                        color: Colors.blue, fontSize: 14)),
                              ),
                            ],
                          ),
                      ],
                    ),
                  if (widget.videoUrl != null)
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(height: 8),
                        Text('Recommended Videos:',
                            style: TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 14)),
                        for (final url in widget.videoUrl!)
                          TextButton(
                            onPressed: () async {
                              if (await canLaunchUrl(Uri.parse(url))) {
                                await launchUrl(Uri.parse(url));
                              } else {
                                print('Could not launch $url');
                              }
                            },
                            child: Text(
                              'Open Video',
                              style:
                                  TextStyle(color: Colors.blue, fontSize: 14),
                            ),
                          ),
                      ],
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _truncateText(String text, {int maxLength = 50}) {
    if (text.length <= maxLength) {
      return text;
    } else {
      return text.substring(0, maxLength) + '...';
    }
  }
}
