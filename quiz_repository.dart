import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/quiz.dart';

class QuizRepository {
  static const _keyQuizzes = 'saved_quizzes';
  static const _keyResults = 'quiz_results';

  Future<void> saveQuiz(Quiz quiz) async {
    final prefs = await SharedPreferences.getInstance();
    final quizzes = await getAllQuizzes();
    final index = quizzes.indexWhere((q) => q.id == quiz.id);
    if (index >= 0) {
      quizzes[index] = quiz;
    } else {
      quizzes.add(quiz);
    }
    final jsonList = quizzes.map((q) => q.toJson()).toList();
    await prefs.setString(_keyQuizzes, jsonEncode(jsonList));
  }

  Future<List<Quiz>> getAllQuizzes() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString(_keyQuizzes);
    if (jsonString == null) return [];
    try {
      final List<dynamic> jsonList = jsonDecode(jsonString) as List;
      return jsonList
          .map((j) => Quiz.fromJson(j as Map<String, dynamic>))
          .toList()
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    } catch (_) {
      return [];
    }
  }

  Future<Quiz?> getQuizById(String id) async {
    final quizzes = await getAllQuizzes();
    try {
      return quizzes.firstWhere((q) => q.id == id);
    } catch (_) {
      return null;
    }
  }

  Future<void> deleteQuiz(String quizId) async {
    final prefs = await SharedPreferences.getInstance();
    final quizzes = await getAllQuizzes();
    quizzes.removeWhere((q) => q.id == quizId);
    final jsonList = quizzes.map((q) => q.toJson()).toList();
    await prefs.setString(_keyQuizzes, jsonEncode(jsonList));
  }

  Future<void> saveResult(QuizResult result) async {
    final prefs = await SharedPreferences.getInstance();
    final results = await getAllResults();
    results.add(result);
    final jsonList = results.map((r) => r.toJson()).toList();
    await prefs.setString(_keyResults, jsonEncode(jsonList));
  }

  Future<List<QuizResult>> getAllResults() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString(_keyResults);
    if (jsonString == null) return [];
    try {
      final List<dynamic> jsonList = jsonDecode(jsonString) as List;
      return jsonList
          .map((j) => QuizResult.fromJson(j as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return [];
    }
  }
}
