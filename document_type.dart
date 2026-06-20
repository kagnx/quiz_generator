enum DocumentType { word, excel, powerpoint, unknown }

extension DocumentTypeExtension on DocumentType {
  String get extension {
    switch (this) {
      case DocumentType.word:
        return 'docx';
      case DocumentType.excel:
        return 'xlsx';
      case DocumentType.powerpoint:
        return 'pptx';
      case DocumentType.unknown:
        return '';
    }
  }

  String get label {
    switch (this) {
      case DocumentType.word:
        return 'Word';
      case DocumentType.excel:
        return 'Excel';
      case DocumentType.powerpoint:
        return 'PowerPoint';
      case DocumentType.unknown:
        return 'Bilinmiyor';
    }
  }

  static DocumentType fromExtension(String ext) {
    final clean = ext.toLowerCase().replaceAll('.', '');
    switch (clean) {
      case 'docx':
        return DocumentType.word;
      case 'xlsx':
        return DocumentType.excel;
      case 'pptx':
        return DocumentType.powerpoint;
      default:
        return DocumentType.unknown;
    }
  }

  static List<String> get supportedExtensions => ['docx', 'xlsx', 'pptx'];
}
