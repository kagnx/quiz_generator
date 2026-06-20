class DocumentSection {
  final String heading;
  final String content;
  final int pageNumber;

  DocumentSection({
    this.heading = '',
    required this.content,
    this.pageNumber = 0,
  });
}

class ParsedDocument {
  final String title;
  final String content;
  final List<DocumentSection> sections;

  ParsedDocument({
    required this.title,
    required this.content,
    required this.sections,
  });
}

abstract class DocumentParser {
  Future<ParsedDocument> parse(String filePath, String fileName);
}

class DocumentParseException implements Exception {
  final String message;
  DocumentParseException(this.message);

  @override
  String toString() => message;
}
