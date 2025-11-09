import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:engademy/presentation/widgets/fill_in_the_blank_question_widget.dart';
import 'package:engademy/presentation/widgets/multiple_choice_question_widget.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class LessonDetailScreen extends StatefulWidget {
  final DocumentSnapshot lesson;

  const LessonDetailScreen({super.key, required this.lesson});

  @override
  State<LessonDetailScreen> createState() => _LessonDetailScreenState();
}

class _LessonDetailScreenState extends State<LessonDetailScreen> {
  final Map<String, dynamic> _userAnswers = {};
  bool _isResultDialogShown = false;
  final db = FirebaseFirestore.instance;

  // ĐÃ HOÀN LẠI: Hàm này chỉ cập nhật điểm tổng cho Bảng xếp hạng.
  Future<void> _updateUserOverallStats(int correctAnswers, int totalQuestions) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    final userRef = db.collection('users').doc(user.uid);
    await userRef.update({
      'quizStats.totalCorrect': FieldValue.increment(correctAnswers),
      'quizStats.totalAttempted': FieldValue.increment(totalQuestions),
    });
  }

  @override
  Widget build(BuildContext context) {
    final lessonData = widget.lesson.data() as Map<String, dynamic>;
    final colorScheme = Theme.of(context).colorScheme;

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: Text(lessonData['title'] ?? 'Lesson'),
          bottom: TabBar(
            indicatorColor: colorScheme.primary,
            labelColor: colorScheme.primary,
            unselectedLabelColor: colorScheme.onSurface.withOpacity(0.6),
            tabs: const [
              Tab(text: 'Lesson', icon: Icon(Icons.menu_book_rounded)),
              Tab(text: 'Practice', icon: Icon(Icons.border_color_rounded)),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _buildLessonContentTab(lessonData),
            _buildPracticeTab(),
          ],
        ),
      ),
    );
  }

  Widget _buildLessonContentTab(Map<String, dynamic> lessonData) {
    final textTheme = Theme.of(context).textTheme;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            lessonData['title'] ?? 'No Title',
            style: textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 24),
          Text(
            lessonData['content'] ?? 'No content available for this lesson.',
            style: textTheme.bodyLarge?.copyWith(fontSize: 18, height: 1.6),
          ),
        ],
      ),
    );
  }

  Widget _buildPracticeTab() {
    return StreamBuilder<QuerySnapshot>(
      stream: widget.lesson.reference.collection('questions').orderBy('createdAt').snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator(color: Theme.of(context).colorScheme.primary));
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(
            child: Text(
              'No practice questions yet.\nCheck back later!',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 18),
            ),
          );
        }

        final questions = snapshot.data!.docs;

        return ListView.builder(
          padding: const EdgeInsets.all(24.0),
          itemCount: questions.length + 1,
          itemBuilder: (context, index) {
            if (index == questions.length) {
              return Padding(
                padding: const EdgeInsets.only(top: 24.0),
                child: ElevatedButton(
                  onPressed: () => _checkAnswers(questions),
                  child: const Text('Check Answers'),
                ),
              );
            }

            final questionDoc = questions[index];
            final questionData = questionDoc.data() as Map<String, dynamic>;
            final questionId = questionDoc.id;

            Widget questionWidget;
            if (questionData['type'] == 'multiple_choice') {
              questionWidget = MultipleChoiceQuestionWidget(
                questionData: questionData,
                onOptionSelected: (answer) => _userAnswers[questionId] = answer,
              );
            } else if (questionData['type'] == 'fill_in_the_blank') {
              if (_userAnswers[questionId] == null || _userAnswers[questionId] is! TextEditingController) {
                _userAnswers[questionId] = TextEditingController();
              }
              questionWidget = FillInTheBlankQuestionWidget(
                questionData: questionData,
                controller: _userAnswers[questionId],
              );
            } else {
              questionWidget = const Text('Unsupported question type.');
            }
            
            return Card(
              margin: const EdgeInsets.only(bottom: 24.0),
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: questionWidget,
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _markLessonAsCompleted() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final progressRef = db.collection('user_progress').doc(user.uid).collection('completed_lessons').doc(widget.lesson.id);

    await progressRef.set({
      'completedAt': FieldValue.serverTimestamp(),
      'lessonTitle': (widget.lesson.data() as Map<String, dynamic>)['title'] ?? 'No Title',
    });
  }

  void _checkAnswers(List<QueryDocumentSnapshot> questions) {
    if (_isResultDialogShown) return;
    _isResultDialogShown = true;

    int score = 0;
    List<Map<String, String>> results = [];

    for (var questionDoc in questions) {
      final questionData = questionDoc.data() as Map<String, dynamic>;
      final questionId = questionDoc.id;
      final correctAnswer = questionData['correctAnswer'] as String;
      dynamic userAnswerRaw = _userAnswers[questionId];

      String userAnswer = (userAnswerRaw is TextEditingController) ? userAnswerRaw.text.trim() : (userAnswerRaw?.toString() ?? "");

      bool isCorrect = userAnswer.toLowerCase() == correctAnswer.toLowerCase();
      if (isCorrect) score++;

      results.add({
        'prompt': questionData['prompt'],
        'userAnswer': userAnswer.isEmpty ? "(No answer)" : userAnswer,
        'correctAnswer': correctAnswer,
        'isCorrect': isCorrect.toString(),
      });
    }
    
    // ĐÃ THÊM LẠI: Cập nhật chỉ số tổng của người dùng cho bảng xếp hạng
    _updateUserOverallStats(score, questions.length);

    double percentage = questions.isNotEmpty ? (score / questions.length) : 0;
    bool passed = percentage >= 0.7;

    if (passed) {
      _markLessonAsCompleted();
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => _buildResultDialog(context, score, questions.length, passed, results),
    ).then((_) => _isResultDialogShown = false);
  }

  Widget _buildResultDialog(BuildContext context, int score, int total, bool passed, List<Map<String, String>> results) {
    final textTheme = Theme.of(context).textTheme;

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Column(
        children: [
          Icon(passed ? Icons.check_circle_outline_rounded : Icons.highlight_off_rounded, color: passed ? Colors.green : Colors.red, size: 60),
          const SizedBox(height: 16),
          Text(passed ? 'Congratulations!' : 'Keep Trying!', style: textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('You scored $score out of $total', style: textTheme.titleLarge),
            if(passed) const Text('Lesson marked as completed. Great job!', style: TextStyle(color: Colors.green)),
            const SizedBox(height: 24),
            const Text('Review your answers:', style: TextStyle(fontWeight: FontWeight.bold)),
            const Divider(),
            ...results.map((result) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Q: ${result['prompt']}', style: textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold)),
                  Text(
                    'Your answer: ${result['userAnswer']}',
                    style: TextStyle(color: result['isCorrect'] == 'true' ? Colors.green : Colors.red),
                  ),
                  if (result['isCorrect'] == 'false')
                    Text('Correct answer: ${result['correctAnswer']}', style: const TextStyle(color: Colors.green)),
                ],
              ),
            )).toList(),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('OK'),
        ),
      ],
    );
  }
}
