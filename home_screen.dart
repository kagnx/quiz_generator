import 'package:flutter/material.dart';
import '../models/quiz.dart';
import '../models/question.dart';
import '../models/document_type.dart';
import '../services/quiz_repository.dart';
import '../services/ai_provider_manager.dart';
import '../services/ai_question_generator.dart';
import '../services/question_extractor.dart';
import '../services/document_picker_service.dart';
import '../parsers/document_parser.dart';
import '../parsers/word_parser.dart';
import '../parsers/excel_parser.dart';
import '../parsers/powerpoint_parser.dart';
import 'quiz_screen.dart';
import 'ai_settings_screen.dart';
import 'about_screen.dart';
import '../widgets/quiz_list_item.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _repository = QuizRepository();
  final _providerManager = AIProviderManager();
  final _extractor = QuestionExtractor();
  final _picker = DocumentPickerService();

  List<Quiz> _quizzes = [];
  bool _isLoading = false;
  String _loadingMessage = '';
  String _currentProviderName = '';

  final List<int> _questionCounts = [10, 20, 30, 40, 50, 100, 200, 500];
  int _selectedCountIndex = 0;
  Difficulty _difficulty = Difficulty.medium;

  @override
  void initState() {
    super.initState();
    _loadQuizzes();
    _loadCurrentProvider();
  }

  Future<void> _loadQuizzes() async {
    final quizzes = await _repository.getAllQuizzes();
    if (!mounted) return;
    setState(() => _quizzes = quizzes);
  }

  Future<void> _loadCurrentProvider() async {
    final config = await _providerManager.getCurrentConfig();
    if (!mounted) return;
    setState(() => _currentProviderName = config.info.displayName);
  }

  Future<void> _pickAndProcessDocument() async {
    try {
      final picked = await _picker.pickDocument();
      if (picked == null) return;

      final config = await _providerManager.getCurrentConfig();
      if (!config.isConfigured) {
        _showApiKeyNeededDialog(config.info.displayName);
        return;
      }

      setState(() {
        _isLoading = true;
        _loadingMessage = 'Belge okunuyor...';
      });

      final parser = _parserFor(picked.documentType);
      final document = await parser.parse(picked.filePath, picked.fileName);

      setState(() {
        _loadingMessage = '${config.info.displayName} ile sorular üretiliyor...';
      });

      final chunks = _extractor.extractKeyContent(document);
      if (chunks.isEmpty) {
        throw Exception('Belge boş veya okunamıyor');
      }

      final generator = AIQuestionGenerator(config);
      final questions = await generator.generateQuestions(
        chunks,
        _questionCounts[_selectedCountIndex],
        difficulty: _difficulty,
      );

      final quiz = Quiz(
        title: document.title,
        questions: questions,
        sourceFileName: picked.fileName,
        documentType: picked.documentType,
      );

      await _repository.saveQuiz(quiz);
      await _loadQuizzes();

      if (!mounted) return;
      setState(() => _isLoading = false);

      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => QuizScreen(quizId: quiz.id)),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString()),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    }
  }

  DocumentParser _parserFor(DocumentType type) {
    switch (type) {
      case DocumentType.word: return WordParser();
      case DocumentType.excel: return ExcelParser();
      case DocumentType.powerpoint: return PowerPointParser();
      case DocumentType.unknown: throw Exception('Desteklenmeyen dosya türü');
    }
  }

  void _showApiKeyNeededDialog(String providerName) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        title: const Text('API Key Gerekli'),
        content: Text('$providerName için API key girilmemiş. Ayarlara gidip eklemek ister misiniz?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('İptal')),
          FilledButton(
            onPressed: () async {
              Navigator.pop(context);
              await Navigator.push(context, MaterialPageRoute(builder: (_) => const AISettingsScreen()));
              _loadCurrentProvider();
            },
            child: const Text('Ayarlara Git'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverAppBar(
            expandedHeight: 120,
            floating: true,
            pinned: true,
            centerTitle: false,
            title: const Text('Quiz Generator AI'),
            actions: [
              IconButton(
                icon: const Icon(Icons.info_outline_rounded),
                onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AboutScreen())),
              ),
              IconButton(
                icon: const Icon(Icons.settings_outlined),
                onPressed: () async {
                  await Navigator.push(context, MaterialPageRoute(builder: (_) => const AISettingsScreen()));
                  _loadCurrentProvider();
                },
              ),
              const SizedBox(width: 8),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [theme.colorScheme.primary.withValues(alpha: 0.05), Colors.white],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildAIBadge(theme),
                  const SizedBox(height: 16),
                  _buildMainCard(theme),
                  const SizedBox(height: 32),
                  Text('Son Quizlerim', style: theme.textTheme.headlineSmall),
                  const SizedBox(height: 12),
                ],
              ),
            ),
          ),
          _quizzes.isEmpty 
            ? SliverFillRemaining(hasScrollBody: false, child: _buildEmptyState(theme))
            : SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: QuizListItem(
                        quiz: _quizzes[index],
                        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => QuizScreen(quizId: _quizzes[index].id))),
                        onDelete: () => _deleteQuiz(_quizzes[index]),
                      ),
                    ),
                    childCount: _quizzes.length,
                  ),
                ),
              ),
          const SliverToBoxAdapter(child: SizedBox(height: 100)),
        ],
      ),
    );
  }

  Widget _buildAIBadge(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: theme.colorScheme.primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.auto_awesome, size: 16, color: theme.colorScheme.primary),
          const SizedBox(width: 8),
          Text('AI Aktif: $_currentProviderName', 
            style: TextStyle(color: theme.colorScheme.primary, fontWeight: FontWeight.bold, fontSize: 12)),
        ],
      ),
    );
  }

  Widget _buildMainCard(ThemeData theme) {
    return Card(
      elevation: 8,
      shadowColor: theme.colorScheme.primary.withValues(alpha: 0.1),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Yeni Sınav Oluştur', style: theme.textTheme.titleLarge),
            const SizedBox(height: 20),
            Text('Soru Sayısı: ${_questionCounts[_selectedCountIndex]}', style: theme.textTheme.bodyMedium),
            Slider(
              value: _selectedCountIndex.toDouble(),
              min: 0, max: (_questionCounts.length - 1).toDouble(),
              divisions: _questionCounts.length - 1,
              onChanged: (v) => setState(() => _selectedCountIndex = v.toInt()),
            ),
            const SizedBox(height: 16),
            Text('Zorluk Seviyesi', style: theme.textTheme.bodyMedium),
            const SizedBox(height: 12),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Wrap(
                spacing: 8,
                children: Difficulty.values.map((d) => ChoiceChip(
                  label: Text(d.label),
                  selected: _difficulty == d,
                  onSelected: (s) => setState(() => _difficulty = d),
                )).toList(),
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: _isLoading ? null : _pickAndProcessDocument,
                icon: _isLoading ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) : const Icon(Icons.add_task_rounded),
                label: Text(_isLoading ? _loadingMessage : 'Belge Yükle ve Üret'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(ThemeData theme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.history_edu_rounded, size: 80, color: Colors.grey.withOpacity(0.3)),
          const SizedBox(height: 16),
          Text('Henüz bir quiz üretmedin.', style: theme.textTheme.bodyMedium),
        ],
      ),
    );
  }

  Future<void> _deleteQuiz(Quiz quiz) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sınavı Sil?'),
        content: Text('"${quiz.title}" kalıcı olarak silinecek.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Vazgeç')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Sil')),
        ],
      ),
    );
    if (confirmed == true) {
      await _repository.deleteQuiz(quiz.id);
      await _loadQuizzes();
    }
  }
}
