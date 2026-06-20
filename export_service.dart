import 'dart:io';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../models/quiz.dart';

class ExportService {
  /// PDF Çıktısı Üretir
  Future<void> exportToPdf(Quiz quiz) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return [
            pw.Header(
              level: 0,
              child: pw.Text(quiz.title,
                  style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold)),
            ),
            pw.SizedBox(height: 20),
            ...quiz.questions.asMap().entries.map((entry) {
              final index = entry.key + 1;
              final q = entry.value;
              return pw.Padding(
                padding: const pw.EdgeInsets.only(bottom: 20),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text('$index. ${q.text}',
                        style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
                    pw.SizedBox(height: 8),
                    ...q.options.asMap().entries.map((optEntry) {
                      final optIndex = optEntry.key;
                      final letter = String.fromCharCode(65 + optIndex); // A, B, C...
                      return pw.Text('  $letter) ${optEntry.value}',
                          style: const pw.TextStyle(fontSize: 12));
                    }),
                  ],
                ),
              );
            }),
            pw.NewPage(),
            pw.Header(level: 1, child: pw.Text('Cevap Anahtarı')),
            pw.Wrap(
              spacing: 20,
              children: quiz.questions.asMap().entries.map((entry) {
                final letter = String.fromCharCode(65 + entry.value.correctAnswerIndex);
                return pw.Text('${entry.key + 1}: $letter',
                    style: const pw.TextStyle(fontSize: 12));
              }).toList(),
            ),
          ];
        },
      ),
    );

    final output = await getTemporaryDirectory();
    final file = File("${output.path}/${quiz.title.replaceAll(' ', '_')}.pdf");
    await file.writeAsBytes(await pdf.save());
    await Share.shareXFiles([XFile(file.path)], text: '${quiz.title} PDF Quiz');
  }

  /// İnteraktif HTML Çıktısı Üretir
  Future<void> exportToHtml(Quiz quiz) async {
    final buffer = StringBuffer();
    buffer.write('''
<!DOCTYPE html>
<html lang="tr">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>${quiz.title}</title>
    <style>
        body { font-family: sans-serif; line-height: 1.6; max-width: 800px; margin: 40px auto; padding: 20px; background: #f4f4f9; }
        .card { background: white; padding: 20px; border-radius: 8px; margin-bottom: 20px; box-shadow: 0 2px 5px rgba(0,0,0,0.1); }
        h1 { color: #6200EE; }
        .option { display: block; padding: 10px; margin: 5px 0; border: 1px solid #ddd; border-radius: 4px; cursor: pointer; transition: 0.3s; }
        .option:hover { background: #eee; }
        .correct { background: #d4edda !important; border-color: #c3e6cb !important; }
        .incorrect { background: #f8d7da !important; border-color: #f5c6cb !important; }
        .hidden { display: none; }
        button { background: #6200EE; color: white; border: none; padding: 10px 20px; border-radius: 4px; cursor: pointer; }
    </style>
</head>
<body>
    <h1>${quiz.title}</h1>
    <div id="quiz-container">
''');

    for (var i = 0; i < quiz.questions.length; i++) {
      final q = quiz.questions[i];
      buffer.write('''
        <div class="card" id="q-$i">
            <h3>${i + 1}. ${q.text}</h3>
            <div class="options">
      ''');
      for (var j = 0; j < q.options.length; j++) {
        final letter = String.fromCharCode(65 + j);
        buffer.write('''
                <div class="option" onclick="checkAnswer($i, $j, ${q.correctAnswerIndex})">
                    $letter) ${q.options[j]}
                </div>
        ''');
      }
      buffer.write('''
            </div>
            <p id="feedback-$i" class="hidden"></p>
        </div>
      ''');
    }

    buffer.write('''
    </div>
    <script>
        function checkAnswer(qIdx, selectedIdx, correctIdx) {
            const card = document.getElementById('q-' + qIdx);
            const options = card.getElementsByClassName('option');
            const feedback = document.getElementById('feedback-' + qIdx);
            
            if (feedback.className !== 'hidden') return; // Zaten cevaplanmış
            
            for (let i = 0; i < options.length; i++) {
                if (i === correctIdx) options[i].classList.add('correct');
                if (i === selectedIdx && i !== correctIdx) options[i].classList.add('incorrect');
            }
            
            feedback.className = '';
            feedback.innerText = selectedIdx === correctIdx ? '✅ Doğru!' : '❌ Yanlış. Doğru cevap: ' + String.fromCharCode(65 + correctIdx);
        }
    </script>
</body>
</html>
''');

    final output = await getTemporaryDirectory();
    final file = File("${output.path}/${quiz.title.replaceAll(' ', '_')}.html");
    await file.writeAsString(buffer.toString());
    await Share.shareXFiles([XFile(file.path)], text: '${quiz.title} İnteraktif HTML Quiz');
  }

  /// Basit Word (RTF) veya Markdown olarak dışa aktarır (En uyumlu yöntem)
  Future<void> exportToWord(Quiz quiz) async {
    final buffer = StringBuffer();
    buffer.writeln(quiz.title);
    buffer.writeln('=' * quiz.title.length);
    buffer.writeln();

    for (var i = 0; i < quiz.questions.length; i++) {
      final q = quiz.questions[i];
      buffer.writeln('${i + 1}. ${q.text}');
      for (var j = 0; j < q.options.length; j++) {
        final letter = String.fromCharCode(65 + j);
        buffer.writeln('  $letter) ${q.options[j]}');
      }
      buffer.writeln();
    }
    
    buffer.writeln('CEVAP ANAHTARI');
    buffer.writeln('-' * 15);
    for (var i = 0; i < quiz.questions.length; i++) {
      final letter = String.fromCharCode(65 + quiz.questions[i].correctAnswerIndex);
      buffer.writeln('${i + 1}: $letter');
    }

    final output = await getTemporaryDirectory();
    final file = File("${output.path}/${quiz.title.replaceAll(' ', '_')}.docx");
    await file.writeAsString(buffer.toString()); // Basit bir metin tabanlı docx paylaşımı
    await Share.shareXFiles([XFile(file.path)], text: '${quiz.title} Word Quiz');
  }
}
