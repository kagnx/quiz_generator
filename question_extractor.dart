import '../parsers/document_parser.dart';

class ContentChunk {
  final String heading;
  final String content;
  final int chunkIndex;

  ContentChunk({
    required this.heading,
    required this.content,
    required this.chunkIndex,
  });
}

class QuestionExtractor {
  static const int _minSectionLength = 50;
  static const int _maxChunkSize = 3500; // Biraz artırıldı, denge için

  List<ContentChunk> extractKeyContent(ParsedDocument document) {
    final allChunks = <ContentChunk>[];

    for (final section in document.sections) {
      if (section.content.trim().length >= _minSectionLength) {
        allChunks.addAll(_splitIntoChunks(section));
      }
    }

    // Eğer hiç section bulunamadıysa (düz metin belgeler için)
    if (allChunks.isEmpty && document.content.trim().length >= _minSectionLength) {
      final tempSection = DocumentSection(heading: document.title, content: document.content);
      allChunks.addAll(_splitIntoChunks(tempSection));
    }

    // ÇOK ÖNEMLİ: Eğer çok fazla chunk varsa (örn: 500 sayfalık kitap),
    // hepsini AI'ya göndermek hem maliyetli hem de yavaştır.
    // Burada akıllı bir seçim yapabiliriz. Şimdilik hepsini döndürelim,
    // Generator içinde sınırlayacağız.
    return allChunks;
  }

  List<ContentChunk> _splitIntoChunks(DocumentSection section) {
    final chunks = <ContentChunk>[];
    final content = section.content;

    if (content.length <= _maxChunkSize) {
      chunks.add(ContentChunk(
        heading: section.heading,
        content: content,
        chunkIndex: 0,
      ));
      return chunks;
    }

    // Paragraflara veya sayfa sonlarına göre böl
    final paragraphs = content.split(RegExp(r'\n\s*\n'));
    final currentChunk = StringBuffer();
    var chunkIndex = 0;

    for (final paragraph in paragraphs) {
      if (paragraph.trim().isEmpty) continue;

      if (currentChunk.length + paragraph.length > _maxChunkSize) {
        if (currentChunk.isNotEmpty) {
          chunks.add(ContentChunk(
            heading: section.heading,
            content: currentChunk.toString().trim(),
            chunkIndex: chunkIndex++,
          ));
          currentChunk.clear();
        }
        
        // Eğer tek bir paragraf bile max boyuttan büyükse onu mecburen böl
        if (paragraph.length > _maxChunkSize) {
           var remaining = paragraph;
           while(remaining.length > _maxChunkSize) {
             chunks.add(ContentChunk(
               heading: section.heading,
               content: remaining.substring(0, _maxChunkSize),
               chunkIndex: chunkIndex++,
             ));
             remaining = remaining.substring(_maxChunkSize);
           }
           currentChunk.write(remaining);
        } else {
          currentChunk.writeln(paragraph);
        }
      } else {
        currentChunk.writeln(paragraph);
      }
    }

    if (currentChunk.isNotEmpty) {
      chunks.add(ContentChunk(
        heading: section.heading,
        content: currentChunk.toString().trim(),
        chunkIndex: chunkIndex,
      ));
    }

    return chunks;
  }
}
