import 'question.dart';
import 'document_type.dart';

class Quiz {
  final String id;
  final String title;
  final List<Question> questions;
  final String sourceFileName;
  final DocumentType documentType;
  final int createdAt;

  Quiz({
    String? id,
    required this.title,
    required this.questions,
    this.sourceFileName = '',
    this.documentType = DocumentType.unknown,
    int? createdAt,
  })  : id = id ?? DateTime.now().microsecondsSinceEpoch.toString(),
        createdAt = createdAt ?? DateTime.now().millisecondsSinceEpoch;

  int get totalQuestions => questions.length;

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'questions': questions.map((q) => q.toJson()).toList(),
        'sourceFileName': sourceFileName,
        'documentType': documentType.name,
        'createdAt': createdAt,
      };

  factory Quiz.fromJson(Map<String, dynamic> json) {
    return Quiz(
      id: json['id'] as String?,
      title: json['title'] as String,
      questions: (json['questions'] as List)
          .map((q) => Question.fromJson(q as Map<String, dynamic>))
          .toList(),
      sourceFileName: json['sourceFileName'] as String? ?? '',
      documentType: DocumentType.values.firstWhere(
        (d) => d.name == json['documentType'],
        orElse: () => DocumentType.unknown,
      ),
      createdAt: json['createdAt'] as int?,
    );
  }
}

class QuizResult {
  final Quiz quiz;
  final Map<String, int> userAnswers;
  final int score;
  final int totalQuestions;
  final int timeTakenMillis;

  QuizResult({
    required this.quiz,
    required this.userAnswers,
    required this.score,
    required this.totalQuestions,
    required this.timeTakenMillis,
  });

  double get scorePercentage =>
      totalQuestions > 0 ? (score / totalQuestions) * 100 : 0;

  Map<String, dynamic> toJson() => {
        'quiz': quiz.toJson(),
        'userAnswers': userAnswers,
        'score': score,
        'totalQuestions': totalQuestions,
        'timeTakenMillis': timeTakenMillis,
      };

  factory QuizResult.fromJson(Map<String, dynamic> json) {
    return QuizResult(
      quiz: Quiz.fromJson(json['quiz'] as Map<String, dynamic>),
      userAnswers: Map<String, int>.from(json['userAnswers'] as Map),
      score: json['score'] as int,
      totalQuestions: json['totalQuestions'] as int,
      timeTakenMillis: json['timeTakenMillis'] as int,
    );
  }
}
