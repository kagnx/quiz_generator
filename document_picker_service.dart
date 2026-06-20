import 'package:file_picker/file_picker.dart';
import '../models/document_type.dart';

class PickedDocument {
  final String filePath;
  final String fileName;
  final DocumentType documentType;
  final int fileSize;

  PickedDocument({
    required this.filePath,
    required this.fileName,
    required this.documentType,
    required this.fileSize,
  });
}

class DocumentPickerService {
  Future<PickedDocument?> pickDocument() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: DocumentTypeExtension.supportedExtensions,
      withData: false,
    );

    if (result == null || result.files.isEmpty) return null;

    final file = result.files.first;
    if (file.path == null) return null;

    final extension = file.extension ?? '';
    final docType = DocumentTypeExtension.fromExtension(extension);

    if (docType == DocumentType.unknown) {
      throw Exception('Desteklenmeyen dosya türü: .$extension');
    }

    return PickedDocument(
      filePath: file.path!,
      fileName: file.name,
      documentType: docType,
      fileSize: file.size,
    );
  }

  String formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(0)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
}
