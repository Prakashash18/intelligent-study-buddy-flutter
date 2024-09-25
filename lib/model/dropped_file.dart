class DroppedFile {
  final String url;
  final String name;
  final String mime;
  final int size;
  final DateTime uploadedDateTime;

  DroppedFile({
    required this.url,
    required this.name,
    required this.mime,
    required this.size,
    required this.uploadedDateTime,
  });

  String get bytes {
    final kb = size / 1024;
    if (kb < 1024) {
      return '${kb.toStringAsFixed(2)} KB';
    }
    return '${(size / 1024 / 1024).toStringAsFixed(2)} MB';
  }
}
