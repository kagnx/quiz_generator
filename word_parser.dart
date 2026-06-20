import 'dart:io';
import 'package:archive/archive.dart';
import 'package:xml/xml.dart' as xml;
import 'document_parser.dart';

/// .docx dosyaları aslında ZIP arşividir; içindeki word/document.xml
/// dosyasını okuyarak paragrafları ve başlıkları çıkarır.
class WordParser implements DocumentParser {
  @override
  Future<ParsedDocument> parse(String filePath, String fileName) async {
    try {
      final bytes = await File(filePath).readAsBytes();
      final archive = ZipDecoder().decodeBytes(bytes);

      final docFile = archive.files.firstWhere(
        (f) => f.name == 'word/document.xml',
        orElse: () => throw DocumentParseException('Geçersiz Word dosyası'),
      );

      final xmlContent = String.fromCharCodes(docFile.content as List<int>);
      final document = xml.XmlDocument.parse(xmlContent);

      final sections = <DocumentSection>[];
      final fullContent = StringBuffer();
      String currentHeading = '';
      final currentContent = StringBuffer();

      final paragraphs = document.findAllElements('w:p');

      for (final paragraph in paragraphs) {
        final textRuns = paragraph.findAllElements('w:t');
        final text = textRuns.map((t) => t.innerText).join().trim();
        if (text.isEmpty) continue;

        // Başlık stilini kontrol et (pStyle değeri "Heading" içeriyorsa
        // veya tüm metin kalın (bold) ve kısaysa başlık kabul edilir)
        final pStyle = paragraph
            .findAllElements('w:pStyle')
            .map((e) => e.getAttribute('w:val') ?? '')
            .firstOrNull;
        final hasBold = paragraph.findAllElements('w:b').isNotEmpty;
        final isHeading = (pStyle?.toLowerCase().contains('heading') ?? false) ||
            (hasBold && text.length < 100);

        if (isHeading) {
          if (currentContent.isNotEmpty) {
            sections.add(DocumentSection(
              heading: currentHeading,
              content: currentContent.toString(),
            ));
            currentContent.clear();
          }
          currentHeading = text;
        } else {
          currentContent.writeln(text);
          fullContent.writeln(text);
        }
      }

      if (currentContent.isNotEmpty) {
        sections.add(DocumentSection(
          heading: currentHeading,
          content: currentContent.toString(),
        ));
      }

      final title = sections.isNotEmpty && sections.first.heading.isNotEmpty
          ? sections.first.heading
          : fileName.replaceAll('.docx', '');

      return ParsedDocument(
        title: title,
        content: fullContent.toString(),
        sections: sections,
      );
    } catch (e) {
      throw DocumentParseException('Word dosyası okunamadı: $e');
    }
  }
}

extension _FirstOrNull<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
