import 'dart:io';
import 'package:archive/archive.dart';
import 'package:xml/xml.dart' as xml;
import 'document_parser.dart';

/// .pptx dosyaları ZIP arşividir; ppt/slides/slideN.xml dosyalarını
/// sırayla okuyarak her slaytı bir DocumentSection'a çevirir.
class PowerPointParser implements DocumentParser {
  @override
  Future<ParsedDocument> parse(String filePath, String fileName) async {
    try {
      final bytes = await File(filePath).readAsBytes();
      final archive = ZipDecoder().decodeBytes(bytes);

      final slideFiles = archive.files
          .where((f) =>
              f.name.startsWith('ppt/slides/slide') &&
              f.name.endsWith('.xml') &&
              !f.name.contains('rels'))
          .toList();

      // slide1.xml, slide2.xml, ... doğru sırada işlensin
      slideFiles.sort((a, b) {
        final numA = _extractSlideNumber(a.name);
        final numB = _extractSlideNumber(b.name);
        return numA.compareTo(numB);
      });

      final sections = <DocumentSection>[];
      final fullContent = StringBuffer();

      for (var i = 0; i < slideFiles.length; i++) {
        final slideFile = slideFiles[i];
        final xmlContent = String.fromCharCodes(slideFile.content as List<int>);
        final document = xml.XmlDocument.parse(xmlContent);

        final textElements = document.findAllElements('a:t');
        final texts = textElements
            .map((e) => e.innerText.trim())
            .where((t) => t.isNotEmpty)
            .toList();

        if (texts.isEmpty) continue;

        // İlk metin genelde başlıktır
        final slideTitle = texts.first;
        final bodyTexts = texts.length > 1 ? texts.sublist(1) : <String>[];
        final slideContent = bodyTexts.join('\n');

        sections.add(DocumentSection(
          heading: slideTitle,
          content: slideContent.isNotEmpty ? slideContent : slideTitle,
          pageNumber: i + 1,
        ));

        fullContent.writeln(texts.join('\n'));
      }

      final title = sections.isNotEmpty
          ? sections.first.heading
          : fileName.replaceAll('.pptx', '');

      return ParsedDocument(
        title: title,
        content: fullContent.toString(),
        sections: sections,
      );
    } catch (e) {
      throw DocumentParseException('PowerPoint dosyası okunamadı: $e');
    }
  }

  int _extractSlideNumber(String path) {
    final match = RegExp(r'slide(\d+)\.xml').firstMatch(path);
    return match != null ? int.parse(match.group(1)!) : 0;
  }
}
