import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

// ĐÃ HOÀN LẠI HOÀN TOÀN: Màn hình Quiz đơn giản, chỉ lấy 10 câu hỏi ngẫu nhiên.
// Không còn logic phức tạp, không cần script, không cần rules đặc biệt.

enum QuizState { loading, error, empty, inProgress, finished }

class QuizScreen extends StatefulWidget {
  const QuizScreen({super.key});

  @override
  State<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends State<QuizScreen> {
  QuizState _state = QuizState.loading;
  List<DocumentSnapshot> _questions = [];
  int _currentQuestionIndex = 0;
  int _score = 0;
  String? _selectedAnswer;
  final TextEditingController _blankController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchAndStartQuiz();
  }

  // Logic đơn giản: Lấy toàn bộ câu hỏi, xáo trộn và chọn 10 câu.
  Future<void> _fetchAndStartQuiz() async {
    if (!mounted) return;
    setState(() {
      _state = QuizState.loading;
      _currentQuestionIndex = 0;
      _score = 0;
      _selectedAnswer = null;
      _blankController.clear();
    });

    try {
      final allQuestionsQuery = await FirebaseFirestore.instance.collectionGroup('questions').get();
      if (allQuestionsQuery.docs.isEmpty) {
        if (mounted) setState(() => _state = QuizState.empty);
        return;
      }
      final allQuestions = allQuestionsQuery.docs;
      allQuestions.shuffle(); // Xáo trộn danh sách
      if (mounted) {
        setState(() {
          _questions = allQuestions.take(10).toList(); // Lấy 10 câu
          _state = QuizState.inProgress;
        });
      }
    } catch (e) {
      print("Lỗi khi lấy quiz ngẫu nhiên: $e");
      if (mounted) setState(() => _state = QuizState.error);
    }
  }

  // Hàm submit đơn giản, không cập nhật bất kỳ stats nào.
  void _submitAnswer() {
    if (!mounted) return;
    final questionData = _questions[_currentQuestionIndex].data() as Map<String, dynamic>;
    final correctAnswer = questionData['correctAnswer'];
    String userAnswer;

    if (questionData['type'] == 'multiple_choice') {
      if (_selectedAnswer == null) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please select an answer.')));
        return;
      }
      userAnswer = _selectedAnswer!;
    } else {
      userAnswer = _blankController.text.trim();
    }

    if (userAnswer.toLowerCase() == correctAnswer.toLowerCase()) {
      _score++;
    }

    if (_currentQuestionIndex < _questions.length - 1) {
      setState(() {
        _currentQuestionIndex++;
        _selectedAnswer = null;
        _blankController.clear();
      });
    } else {
      setState(() => _state = QuizState.finished);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Random Quiz'),
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    final colorScheme = Theme.of(context).colorScheme;
    switch (_state) {
      case QuizState.loading:
        return Center(child: CircularProgressIndicator(color: colorScheme.primary));
      case QuizState.error:
        return Center(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('Failed to load quiz. Please try again.', style: TextStyle(color: colorScheme.error), textAlign: TextAlign.center),
                const SizedBox(height: 20),
                ElevatedButton(onPressed: _fetchAndStartQuiz, child: const Text('Retry'))
              ],
            ),
          ),
        );
      case QuizState.empty:
        return const Center(child: Text('No questions available in the database.', style: TextStyle(fontSize: 18, color: Colors.grey), textAlign: TextAlign.center,));
      case QuizState.finished:
        return _buildResultsScreen();
      case QuizState.inProgress:
        return _buildQuestionScreen();
    }
  }

  Widget _buildQuestionScreen() {
    if (_questions.isEmpty || _currentQuestionIndex >= _questions.length) {
      return const Center(child: Text('No more questions.'));
    }
    final questionDoc = _questions[_currentQuestionIndex];
    final questionData = questionDoc.data() as Map<String, dynamic>;
    final type = questionData['type'];
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;
    final progress = (_currentQuestionIndex + 1) / _questions.length;

    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Question ${_currentQuestionIndex + 1} of ${_questions.length}', style: textTheme.bodyMedium?.copyWith(color: colorScheme.onSurface.withOpacity(0.7))),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 8,
              backgroundColor: colorScheme.primary.withOpacity(0.1),
              valueColor: AlwaysStoppedAnimation<Color>(colorScheme.primary),
            ),
          ),
          const SizedBox(height: 32),
          Text(questionData['prompt'] ?? '', style: textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w600)),
          const SizedBox(height: 32),
          if (type == 'multiple_choice') Expanded(child: _buildMultipleChoiceOptions(questionData)),
          if (type == 'fill_in_the_blank') _buildFillInTheBlank(),
          const Spacer(),
          ElevatedButton(
            onPressed: _submitAnswer,
            child: const Text('Submit'),
          ),
        ],
      ),
    );
  }

  Widget _buildMultipleChoiceOptions(Map<String, dynamic> questionData) {
    final options = List<String>.from(questionData['options'] ?? []);
    final colorScheme = Theme.of(context).colorScheme;

    return ListView.separated(
      itemCount: options.length,
      separatorBuilder: (context, index) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final option = options[index];
        final isSelected = _selectedAnswer == option;

        return InkWell(
          onTap: () => setState(() => _selectedAnswer = option),
          borderRadius: BorderRadius.circular(12),
          child: Ink(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            decoration: BoxDecoration(
              color: isSelected ? colorScheme.primary.withOpacity(0.1) : colorScheme.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isSelected ? colorScheme.primary : colorScheme.onSurface.withOpacity(0.1),
                width: isSelected ? 2 : 1,
              ),
            ),
            child: Row(
              children: [
                Text(option, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: isSelected ? FontWeight.bold : FontWeight.normal)),
                const Spacer(),
                if (isSelected)
                  Icon(Icons.check_circle_rounded, color: colorScheme.primary)
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildFillInTheBlank() {
    return TextField(
      controller: _blankController,
      decoration: const InputDecoration(
        labelText: 'Your Answer',
        border: OutlineInputBorder(),
      ),
    );
  }

  Widget _buildResultsScreen() {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;
    final double percentage = _questions.isNotEmpty ? (_score / _questions.length) : 0;
    final String message = percentage >= 0.8 ? 'Excellent Work! 🚀' : (percentage >= 0.5 ? 'Good Job! 👍' : 'Keep Practicing! 💪');

    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(message, style: textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold), textAlign: TextAlign.center),
          const SizedBox(height: 24),
          SizedBox(
            width: 150,
            height: 150,
            child: Stack(
              fit: StackFit.expand,
              children: [
                CircularProgressIndicator(
                  value: percentage,
                  strokeWidth: 10,
                  backgroundColor: colorScheme.secondary.withOpacity(0.2),
                  valueColor: AlwaysStoppedAnimation<Color>(colorScheme.secondary),
                ),
                Center(
                  child: Text('$_score / ${_questions.length}', style: textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w600)),
                ),
              ],
            ),
          ),
          const SizedBox(height: 40),
          ElevatedButton.icon(
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('Take Another Quiz'),
            onPressed: _fetchAndStartQuiz,
          ),
        ],
      ),
    );
  }
}
