import 'package:flutter/services.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import 'package:flutter/material.dart';

class PdfController {
  late PdfViewerController pdfViewerController;
  OverlayEntry? overlayEntry; // Initialize to null
  final GlobalKey<SfPdfViewerState> pdfViewerKey = GlobalKey();
  double zoomLevel = 1.0; // Initial zoom level

  PdfController() {
    pdfViewerController = PdfViewerController();
  }

  void zoomIn() {
    zoomLevel += 0.1;
    zoomLevel = zoomLevel > 2.0 ? 2.0 : zoomLevel; // Clamp zoom level
    pdfViewerController.zoomLevel = zoomLevel;
  }

  void zoomOut() {
    zoomLevel -= 0.1;
    zoomLevel = zoomLevel < 1.0 ? 1.0 : zoomLevel; // Clamp zoom level
    pdfViewerController.zoomLevel = zoomLevel;
  }

  void showContextMenu(
      BuildContext context,
      PdfTextSelectionChangedDetails details,
      Function(String) explainText,
      Function(String) videoSearch) {
    const double height = 150;
    const double width = 150;
    final OverlayState overlayState = Overlay.of(context);
    final Size screenSize = MediaQuery.of(context).size;

    double top = details.globalSelectedRegion!.top >= screenSize.height / 2
        ? details.globalSelectedRegion!.top - height - 10
        : details.globalSelectedRegion!.bottom + 20;
    top = top < 0 ? 20 : top;
    top = top + height > screenSize.height
        ? screenSize.height - height - 10
        : top;

    double left = details.globalSelectedRegion!.bottomLeft.dx;
    left = left < 0 ? 10 : left;
    left =
        left + width > screenSize.width ? screenSize.width - width - 10 : left;
    overlayEntry = OverlayEntry(
      builder: (BuildContext context) => Positioned(
        top: top,
        left: left,
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(4),
            boxShadow: const <BoxShadow>[
              BoxShadow(
                color: Colors.black26,
                blurRadius: 4,
                offset: Offset(2, 2),
              ),
            ],
          ),
          constraints:
              const BoxConstraints.tightFor(width: width, height: height),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: <Widget>[
              TextButton(
                onPressed: () {
                  if (details.selectedText != null) {
                    Clipboard.setData(
                        ClipboardData(text: details.selectedText!));
                    print('Text copied to clipboard: ${details.selectedText}');
                    pdfViewerController.clearSelection();
                  }
                },
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    const Icon(Icons.copy),
                    const Text('Copy', style: TextStyle(fontSize: 15)),
                  ],
                ),
              ),
              TextButton(
                onPressed: () {
                  if (details.selectedText != null) {
                    Clipboard.setData(
                        ClipboardData(text: details.selectedText!));
                    print('Text copied to clipboard: ${details.selectedText}');
                    explainText(details.selectedText!);
                    pdfViewerController.clearSelection();
                  }
                },
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    const Icon(Icons.pest_control_outlined),
                    const Text('Explain this', style: TextStyle(fontSize: 15)),
                  ],
                ),
              ),
              TextButton(
                onPressed: () {
                  if (details.selectedText != null) {
                    Clipboard.setData(
                        ClipboardData(text: details.selectedText!));
                    print('Text copied to clipboard: ${details.selectedText}');
                    videoSearch(details.selectedText!);
                    pdfViewerController.clearSelection();
                  }
                },
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    const Icon(Icons.youtube_searched_for_outlined),
                    const Text('Video search', style: TextStyle(fontSize: 15)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
    overlayState.insert(overlayEntry!);
  }
}
