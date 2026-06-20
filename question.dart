enum Difficulty { veryEasy, easy, medium, hard, veryHard, mixed }

extension DifficultyExtension on Difficulty {
  String get label {
    switch (this) {
      case Difficulty.veryEasy:
        return 'Çok Kolay';
      case Difficulty.easy:
        return 'Kolay';
      case Difficulty.medium:
        return 'Orta';
      case Difficulty.hard:
        return 'Zor';
      case Difficulty.veryHard:
        return 'Çok Zor';
      case Difficulty.mixed:
        return 'Karışık';
    }
  }

  String get promptDescription {
    switch (this) {
      case Difficulty.veryEasy:
        return 'temel tanımlar ve basit hatırlama gerektiren çok kolay';
      case Difficulty.easy:
        return 'genel kavramları test eden kolay';
      case Difficulty.medium:
        return 'kavramayı ve uygulama becerisini test eden orta zorlukta';
      case Difficulty.hard:
        return 'analiz ve derin anlayış gerektiren zor';
      case Difficulty.veryHard:
        return 'karmaşık sentez, eleştirel değerlendirme ve uzmanlık seviyesinde çok zor';
      case Difficulty.mixed:
        return 'tüm zorluk seviyelerinden dengeli bir karışım';
    }
  }
}

class Question {
  final String id;
  final String text;
  final List<String> options;
  final int correctAnswerIndex;
  final String explanation;
  final Difficulty difficulty;
  final String sourceText;

  Question({
    String? id,
    required this.text,
    required this.options,
    required this.correctAnswerIndex,
    this.explanation = '',
    this.difficulty = Difficulty.medium,
    this.sourceText = '',
  }) : id = id ?? '${DateTime.now().microsecondsSinceEpoch}_${text.hashCode}';

  Map<String, dynamic> toJson() => {
        'id': id,
        'text': text,
        'options': options,
        'correctAnswerIndex': correctAnswerIndex,
        'explanation': explanation,
        'difficulty': difficulty.name,
        'sourceText': sourceText,
      };

  factory Question.fromJson(Map<String, dynamic> json) {
    return Question(
      id: json['id'] as String?,
      text: json['text'] as String,
      options: List<String>.from(json['options'] as List),
      correctAnswerIndex: json['correctAnswerIndex'] as int,
      explanation: json['explanation'] as String? ?? '',
      difficulty: Difficulty.values.firstWhere(
        (d) => d.name == json['difficulty'],
        orElse: () => Difficulty.medium,
      ),
      sourceText: json['sourceText'] as String? ?? '',
    );
  }
}
