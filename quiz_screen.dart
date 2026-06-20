import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../models/quiz.dart';
import '../services/quiz_repository.dart';
import '../services/export_service.dart';
import '../widgets/option_tile.dart';

class QuizScreen extends StatefulWidget {
  final String quizId;

  const QuizScreen({super.key, required this.quizId});

  @override
  State<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends State<QuizScreen> {
  final _repository = QuizRepository();
  final _exportService = ExportService();

  Quiz? _quiz;
  int _currentIndex = 0;
  final Map<String, int> _selectedAnswers = {};
  bool _isCompleted = false;
  int? _score;
  late int _startTimeMillis;

  @override
  void initState() {
    super.initState();
    _startTimeMillis = DateTime.now().millisecondsSinceEpoch;
    _loadQuiz();
  }

  Future<void> _loadQuiz() async {
    final quiz = await _repository.getQuizById(widget.quizId);
    if (!mounted) return;
    setState(() => _quiz = quiz);
  }

  void _selectAnswer(int answerIndex) {
    if (_isCompleted) return;
    final question = _quiz!.questions[_currentIndex];
    setState(() => _selectedAnswers[question.id] = answerIndex);
  }

  void _goNext() {
    if (_currentIndex < _quiz!.questions.length - 1) {
      setState(() => _currentIndex++);
    }
  }

  void _goPrevious() {
    if (_currentIndex > 0) {
      setState(() => _currentIndex--);
    }
  }

  Future<void> _submitQuiz() async {
    final quiz = _quiz!;
    var score = 0;
    for (final question in quiz.questions) {
      if (_selectedAnswers[question.id] == question.correctAnswerIndex) {
        score++;
      }
    }

    final timeTaken = DateTime.now().millisecondsSinceEpoch - _startTimeMillis;

    final result = QuizResult(
      quiz: quiz,
      userAnswers: Map.from(_selectedAnswers),
      score: score,
      totalQuestions: quiz.questions.length,
      timeTakenMillis: timeTaken,
    );

    await _repository.saveResult(result);

    if (!mounted) return;
    setState(() {
      _score = score;
      _isCompleted = true;
    });
  }

  void _restart() {
    setState(() {
      _currentIndex = 0;
      _selectedAnswers.clear();
      _isCompleted = false;
      _score = null;
      _startTimeMillis = DateTime.now().millisecondsSinceEpoch;
    });
  }

  @override
  Widget build(BuildContext context) {
    final quiz = _quiz;
    if (quiz == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(quiz.title),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.download_outlined),
            onSelected: (val) {
              switch (val) {
                case 'pdf': _exportService.exportToPdf(quiz); break;
                case 'html': _exportService.exportToHtml(quiz); break;
                case 'word': _exportService.exportToWord(quiz); break;
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(value: 'pdf', child: Text('PDF Kaydet')),
              const PopupMenuItem(value: 'word', child: Text('Word Kaydet')),
              const PopupMenuItem(value: 'html', child: Text('İnteraktif HTML')),
            ],
          ),
        ],
      ),
      body: _isCompleted ? _buildResults(quiz) : _buildActiveQuiz(quiz),
    );
  }

  Widget _buildActiveQuiz(Quiz quiz) {
    final question = quiz.questions[_currentIndex];
    final total = quiz.questions.length;
    final progress = (_currentIndex + 1) / total;
    final isLast = _currentIndex == total - 1;
    final selectedAnswer = _selectedAnswers[question.id];

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Soru ${_currentIndex + 1} / $total',
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: Theme.of(context).colorScheme.primary,
                    fontWeight: FontWeight.bold,
                  )),
              _buildTimer(),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(value: progress, minHeight: 10),
          ),
          const SizedBox(height: 24),
          Expanded(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Column(
                children: [
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Text(
                        question.text,
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  ...List.generate(question.options.length, (index) => OptionTile(
                    label: String.fromCharCode(65 + index),
                    text: question.options[index],
                    isSelected: selectedAnswer == index,
                    onTap: () => _selectAnswer(index),
                  )),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _currentIndex > 0 ? _goPrevious : null,
                    child: const Text('Geri'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton(
                    onPressed: isLast ? _submitQuiz : _goNext,
                    child: Text(isLast ? 'Bitir' : 'İleri'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimer() {
    final elapsed = DateTime.now().millisecondsSinceEpoch - _startTimeMillis;
    final seconds = (elapsed / 1000).floor();
    final minutes = (seconds / 60).floor();
    final remainingSecs = seconds % 60;
    return Text(
      '${minutes.toString().padLeft(2, '0')}:${remainingSecs.toString().padLeft(2, '0')}',
      style: Theme.of(context).textTheme.labelLarge,
    );
  }

  Widget _buildResults(Quiz quiz) {
    final score = _score ?? 0;
    final total = quiz.questions.length;
    final incorrect = total - score;
    final percentage = total > 0 ? (score / total * 100).round() : 0;

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          Text('Sınav Tamamlandı', style: Theme.of(context).textTheme.headlineMedium),
          const SizedBox(height: 32),
          
          // GRAFİK BÖLÜMÜ
          SizedBox(
            height: 200,
            child: PieChart(
              PieChartData(
                sectionsSpace: 4,
                centerSpaceRadius: 50,
                sections: [
                  PieChartSectionData(
                    color: Colors.greenAccent.shade700,
                    value: score.toDouble(),
                    title: '%$percentage',
                    radius: 60,
                    titleStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                  PieChartSectionData(
                    color: Colors.redAccent.shade200,
                    value: incorrect.toDouble(),
                    title: '',
                    radius: 50,
                  ),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 32),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildStatCard('Doğru', score.toString(), Colors.green),
              _buildStatCard('Yanlış', incorrect.toString(), Colors.red),
              _buildStatCard('Süre', '${( (DateTime.now().millisecondsSinceEpoch - _startTimeMillis) / 1000 / 60).toStringAsFixed(1)} dk', Colors.blue),
            ],
          ),
          
          const SizedBox(height: 40),
          _buildActionButton(Icons.picture_as_pdf_rounded, 'PDF Olarak Paylaş', () => _exportService.exportToPdf(quiz)),
          const SizedBox(height: 12),
          _buildActionButton(Icons.html_rounded, 'İnteraktif HTML Paylaş', () => _exportService.exportToHtml(quiz)),
          
          const SizedBox(height: 40),
          SizedBox(
            width: double.infinity,
            child: FilledButton(onPressed: _restart, child: const Text('Tekrar Çöz')),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(onPressed: () => Navigator.pop(context), child: const Text('Ana Sayfaya Dön')),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String label, String value, Color color) {
    return Column(
      children: [
        Text(value, style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: color)),
        Text(label, style: const TextStyle(fontSize: 14, color: Colors.grey)),
      ],
    );
  }

  Widget _buildActionButton(IconData icon, String label, VoidCallback onTap) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: onTap,
        icon: Icon(icon),
        label: Text(label),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.white,
          foregroundColor: Colors.black87,
          elevation: 0,
          side: BorderSide(color: Colors.grey.withValues(alpha: 0.2)),
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
      ),
    );
  }
}
