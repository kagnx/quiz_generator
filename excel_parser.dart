import 'dart:io';
import 'package:excel/excel.dart';
import 'document_parser.dart';

/// .xlsx dosyalarını `excel` paketi ile okur, her sheet'i ayrı bir
/// DocumentSection olarak döner.
class ExcelParser implements DocumentParser {
  @override
  Future<ParsedDocument> parse(String filePath, String fileName) async {
    try {
      final bytes = await File(filePath).readAsBytes();
      final excel = Excel.decodeBytes(bytes);

      final sections = <DocumentSection>[];
      final fullContent = StringBuffer();
      int pageIndex = 0;

      for (final sheetName in excel.tables.keys) {
        final sheet = excel.tables[sheetName];
        if (sheet == null) continue;

        final sheetContent = StringBuffer();

        for (final row in sheet.rows) {
          final cellTexts = row
              .where((cell) => cell != null && cell.value != null)
              .map((cell) => cell!.value.toString())
              .where((text) => text.trim().isNotEmpty)
              .toList();

          if (cellTexts.isNotEmpty) {
            final rowText = cellTexts.join(' | ');
            sheetContent.writeln(rowText);
            fullContent.writeln(rowText);
          }
        }

        if (sheetContent.isNotEmpty) {
          sections.add(DocumentSection(
            heading: sheetName,
            content: sheetContent.toString(),
            pageNumber: pageIndex,
          ));
        }
        pageIndex++;
      }

      final title = fileName.replaceAll('.xlsx', '');

      return ParsedDocument(
        title: title,
        content: fullContent.toString(),
        sections: sections,
      );
    } catch (e) {
      throw DocumentParseException('Excel dosyası okunamadı: $e');
    }
  }
}
