import 'dart:convert';
import 'dart:math';
import 'package:http/http.dart' as http;
import '../models/question.dart';
import '../models/ai_provider.dart';
import 'question_extractor.dart';

class AIGenerationException implements Exception {
  final String message;
  AIGenerationException(this.message);

  @override
  String toString() => message;
}

class AIQuestionGenerator {
  final AIProviderConfig config;

  AIQuestionGenerator(this.config);

  /// Ana üretim fonksiyonu - Chunking mimarisi ile güncellendi
  Future<List<Question>> generateQuestions(
    List<ContentChunk> chunks,
    int totalRequestedCount, {
    Difficulty difficulty = Difficulty.medium,
  }) async {
    if (!config.isConfigured) {
      throw AIGenerationException(
          'API key eksik. Lütfen ayarlardan ${config.info.displayName} için key girin.');
    }
    if (chunks.isEmpty) {
      throw AIGenerationException('Belgeden işlenebilir içerik bulunamadı.');
    }

    // 1. CHUNKING STRATEJİSİ:
    // Eğer belge çok büyükse (yüzlerce chunk), hepsini işlemek yerine 
    // belgenin geneline yayılmış stratejik chunklar seçilir.
    const int maxChunksToProcess = 12; 
    List<ContentChunk> selectedChunks;

    if (chunks.length > maxChunksToProcess) {
      // Belgenin başından, ortasından ve sonundan dengeli örnekler al
      selectedChunks = [];
      double step = chunks.length / maxChunksToProcess;
      for (int i = 0; i < maxChunksToProcess; i++) {
        selectedChunks.add(chunks[(i * step).toInt()]);
      }
    } else {
      selectedChunks = chunks;
    }

    final allQuestions = <Question>[];
    
    // Her chunk'tan kaç soru isteneceği (Örn: 50 soru / 10 chunk = chunk başı 5 soru)
    int questionsPerChunk = (totalRequestedCount / selectedChunks.length).ceil();
    // AI'nın tek seferde çok yorulmaması için chunk başı limiti
    questionsPerChunk = questionsPerChunk.clamp(2, 15);

    // 2. PARALEL İŞLEME (Opsiyonel ama güvenli olması için seri devam ediyoruz)
    for (final chunk in selectedChunks) {
      try {
        // Her chunk için ayrı bir API çağrısı ve zaman aşımı kontrolü
        final chunkQuestions = await _generateForChunk(
          chunk, 
          questionsPerChunk, 
          difficulty
        ).timeout(const Duration(seconds: 45)); // Her istek için 45sn limit
        
        allQuestions.addAll(chunkQuestions);
        
        // Eğer hedefe ulaştıysak ve yeterince fazladan sorumuz varsa durabiliriz
        if (allQuestions.length >= totalRequestedCount * 1.2) break;
        
      } catch (e) {
        // Bir bölüm hata verirse (timeout vb.) devam et
        continue;
      }
    }

    if (allQuestions.isEmpty) {
      throw AIGenerationException(
          'Yapay zeka şu an yanıt vermiyor veya içerik çok karmaşık. '
          'Lütfen daha kısa bir bölüm seçmeyi veya farklı bir AI modelini deneyin.');
    }

    // 3. FİNALİZASYON VE KALİTE KONTROLÜ
    return _processAndFinalizeQuestions(allQuestions, totalRequestedCount);
  }

  List<Question> _processAndFinalizeQuestions(List<Question> rawQuestions, int limit) {
    rawQuestions.shuffle();
    // İstenen sayıdan biraz fazla üretilmiş olabilir, tam sayıyı al
    final selected = rawQuestions.take(limit).toList();
    
    final finalized = <Question>[];
    int? lastKey;
    int? secondLastKey;

    for (var i = 0; i < selected.length; i++) {
      final q = selected[i];
      final options = List<String>.from(q.options);
      final correctText = options[q.correctAnswerIndex];
      
      options.shuffle();
      var newCorrectIndex = options.indexOf(correctText);

      // KURAL: Aynı seçenek (örn: üst üste 3 tane A şıkkı) gelmemeli
      var attempts = 0;
      while (attempts < 10 && _isViolatingSequence(newCorrectIndex, lastKey, secondLastKey)) {
        options.shuffle();
        newCorrectIndex = options.indexOf(correctText);
        attempts++;
      }

      finalized.add(Question(
        text: q.text,
        options: options,
        correctAnswerIndex: newCorrectIndex,
        explanation: q.explanation,
        difficulty: q.difficulty,
        sourceText: q.sourceText,
      ));

      secondLastKey = lastKey;
      lastKey = newCorrectIndex;
    }

    return finalized;
  }

  bool _isViolatingSequence(int current, int? last, int? secondLast) {
    if (last == null || secondLast == null) return false;
    return current == last && current == secondLast;
  }

  Future<List<Question>> _generateForChunk(
    ContentChunk chunk,
    int count,
    Difficulty difficulty,
  ) async {
    final prompt = _buildPrompt(chunk, count, difficulty);
    late http.Response response;

    switch (config.provider) {
      case AIProvider.claude: response = await _callClaude(prompt); break;
      case AIProvider.openai: response = await _callOpenAI(prompt); break;
      case AIProvider.gemini: response = await _callGemini(prompt); break;
      case AIProvider.deepseek: response = await _callDeepSeek(prompt); break;
      case AIProvider.ollama: response = await _callOllama(prompt); break;
    }

    if (response.statusCode != 200) {
      throw Exception('HTTP ${response.statusCode}');
    }

    return _parseQuestionsFromResponse(response.body, chunk.content, difficulty);
  }

  // --- API Çağrıları (Daha uzun zaman aşımları ve optimize edilmiş tokenlar) ---

  Future<http.Response> _callClaude(String prompt) {
    return http.post(
      Uri.parse(config.info.baseUrl),
      headers: {
        'x-api-key': config.apiKey,
        'anthropic-version': '2023-06-01',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'model': config.effectiveModel,
        'max_tokens': 2000,
        'messages': [{'role': 'user', 'content': prompt}],
      }),
    );
  }

  Future<http.Response> _callOpenAI(String prompt) {
    return http.post(
      Uri.parse(config.info.baseUrl),
      headers: {
        'Authorization': 'Bearer ${config.apiKey}',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'model': config.effectiveModel,
        'messages': [
          {'role': 'system', 'content': 'Sen bir eğitim asistanısın. Sadece JSON döndür.'},
          {'role': 'user', 'content': prompt}
        ],
      }),
    );
  }

  Future<http.Response> _callGemini(String prompt) {
    final url = '${config.info.baseUrl}/${config.effectiveModel}:generateContent?key=${config.apiKey}';
    return http.post(
      Uri.parse(url),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'contents': [{'parts': [{'text': prompt}]}],
        'generationConfig': {'temperature': 0.7, 'maxOutputTokens': 2000},
      }),
    );
  }

  Future<http.Response> _callDeepSeek(String prompt) {
    return http.post(
      Uri.parse(config.info.baseUrl),
      headers: {
        'Authorization': 'Bearer ${config.apiKey}',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'model': config.effectiveModel,
        'messages': [{'role': 'user', 'content': prompt}],
      }),
    );
  }

  Future<http.Response> _callOllama(String prompt) {
    return http.post(
      Uri.parse(config.effectiveBaseUrl),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'model': config.effectiveModel,
        'stream': false,
        'messages': [{'role': 'user', 'content': prompt}],
      }),
    );
  }

  List<Question> _parseQuestionsFromResponse(
    String responseBody,
    String sourceText,
    Difficulty difficulty,
  ) {
    try {
      final raw = jsonDecode(responseBody) as Map<String, dynamic>;
      String? textContent;

      // Sağlayıcıya göre yanıt metnini ayıkla
      if (config.provider == AIProvider.claude) {
        textContent = (raw['content'] as List?)?.first['text'];
      } else if (config.provider == AIProvider.gemini) {
        textContent = raw['candidates']?[0]['content']?['parts']?[0]?['text'];
      } else if (config.provider == AIProvider.ollama) {
        textContent = raw['message']?['content'];
      } else {
        textContent = raw['choices']?[0]?['message']?['content'];
      }

      if (textContent == null) return [];

      // Regex ile JSON dizisini bul (Hatalı AI yanıtlarını kurtarmak için)
      final regex = RegExp(r'\[[\s\S]*\]');
      final match = regex.firstMatch(textContent);
      if (match == null) return [];
      
      final cleanJson = match.group(0)!;
      final List<dynamic> arr = jsonDecode(cleanJson);

      return arr.map((obj) {
        try {
          final options = List<String>.from(obj['options']);
          if (options.length != 5) return null;
          
          return Question(
            text: obj['text'],
            options: options,
            correctAnswerIndex: obj['correctAnswerIndex'],
            explanation: obj['explanation'] ?? '',
            difficulty: difficulty,
            sourceText: sourceText.substring(0, min(sourceText.length, 300)),
          );
        } catch (_) { return null; }
      }).whereType<Question>().toList();
    } catch (e) {
      // Ayrıştırma hatası
      return [];
    }
  }

  String _buildPrompt(ContentChunk chunk, int count, Difficulty difficulty) {
    return '''
Aşağıdaki metne dayanarak $count adet 5 seçenekli çoktan seçmeli soru oluştur.
Zorluk Seviyesi: ${difficulty.label}

Metin:
${chunk.content}

Yanıtını SADECE şu JSON yapısında döndür (başka metin ekleme):
[
  {
    "text": "Soru?",
    "options": ["A", "B", "C", "D", "E"],
    "correctAnswerIndex": 0,
    "explanation": "Açıklama..."
  }
]
''';
  }
}
