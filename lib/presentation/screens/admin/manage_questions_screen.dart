import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

enum QuestionType { none, multipleChoice, fillInTheBlank }

class ManageQuestionsScreen extends StatelessWidget {
  final DocumentSnapshot lesson;

  const ManageQuestionsScreen({super.key, required this.lesson});

  void _showAddOrEditQuestionDialog(BuildContext context, {DocumentSnapshot? questionDoc}) {
    final isEditing = questionDoc != null;
    final questionData = isEditing ? questionDoc.data() as Map<String, dynamic> : null;
    
    QuestionType selectedType = isEditing ? (questionData!['type'] == 'multiple_choice' ? QuestionType.multipleChoice : QuestionType.fillInTheBlank) : QuestionType.none;
    final promptController = TextEditingController(text: isEditing ? questionData!['prompt'] : '');
    final answerController = TextEditingController(text: isEditing ? questionData!['correctAnswer'] : '');
    List<TextEditingController> optionControllers = isEditing && questionData!['type'] == 'multiple_choice'
        ? (questionData['options'] as List).map((opt) => TextEditingController(text: opt.toString())).toList()
        : [TextEditingController(), TextEditingController()];

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            void addOption() => setState(() => optionControllers.add(TextEditingController()));
            void removeOption(int index) => setState(() => optionControllers.removeAt(index));

            Widget content;
            if (selectedType == QuestionType.none) {
              content = Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ListTile(title: const Text('Multiple Choice'), leading: const Icon(Icons.check_circle_outline), onTap: () => setState(() => selectedType = QuestionType.multipleChoice)),
                  ListTile(title: const Text('Fill in the Blank'), leading: const Icon(Icons.edit_note_rounded), onTap: () => setState(() => selectedType = QuestionType.fillInTheBlank)),
                ],
              );
            } else if (selectedType == QuestionType.multipleChoice) {
              content = SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(controller: promptController, decoration: const InputDecoration(labelText: 'Question Prompt', border: OutlineInputBorder())),
                    const SizedBox(height: 16),
                    ...List.generate(optionControllers.length, (index) => Padding(
                      padding: const EdgeInsets.only(bottom: 8.0),
                      child: Row(children: [
                        Expanded(child: TextField(controller: optionControllers[index], decoration: InputDecoration(labelText: 'Option ${index + 1}', border: OutlineInputBorder()))),
                        if (optionControllers.length > 2) IconButton(icon: const Icon(Icons.remove_circle_outline), onPressed: () => removeOption(index)),
                      ]),
                    )),
                    TextButton.icon(icon: const Icon(Icons.add), label: const Text('Add Option'), onPressed: addOption),
                    const SizedBox(height: 16),
                    TextField(controller: answerController, decoration: const InputDecoration(labelText: 'Correct Answer (must match an option)', border: OutlineInputBorder())),
                  ],
                ),
              );
            } else { // Fill in the Blank
              content = SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(controller: promptController, decoration: const InputDecoration(labelText: 'Question Prompt (use ___ for blank)', border: OutlineInputBorder())),
                    const SizedBox(height: 16),
                    TextField(controller: answerController, decoration: const InputDecoration(labelText: 'Correct Answer', border: OutlineInputBorder())),
                  ],
                ),
              );
            }

            return AlertDialog(
              title: Text(isEditing ? 'Edit Question' : 'Add New Question'),
              content: content,
              actions: [
                TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancel')),
                if (selectedType != QuestionType.none) ElevatedButton(
                  onPressed: () async {
                    final data = {
                      'type': selectedType == QuestionType.multipleChoice ? 'multiple_choice' : 'fill_in_the_blank',
                      'prompt': promptController.text.trim(),
                      'correctAnswer': answerController.text.trim(),
                      'options': selectedType == QuestionType.multipleChoice ? optionControllers.map((c) => c.text.trim()).toList() : [],
                      'createdAt': isEditing ? questionData!['createdAt'] : FieldValue.serverTimestamp(),
                    };
                    
                    try {
                      if (isEditing) {
                        await questionDoc.reference.update(data);
                      } else {
                        await lesson.reference.collection('questions').add(data);
                      }
                      if (context.mounted) Navigator.of(context).pop();
                    } catch(e) {
                       ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to save question: ${e.toString()}')));
                    }
                  },
                  child: const Text('Save'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final lessonData = lesson.data() as Map<String, dynamic>;
    return Scaffold(
      appBar: AppBar(title: Text('Questions for "${lessonData['title']}"')),
      body: StreamBuilder<QuerySnapshot>(
        stream: lesson.reference.collection('questions').orderBy('createdAt').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator(color: Theme.of(context).colorScheme.primary));
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text('No questions in this lesson yet.'));
          }
          final questions = snapshot.data!.docs;
          return ListView.builder(
            padding: const EdgeInsets.all(8.0),
            itemCount: questions.length,
            itemBuilder: (context, index) => _buildQuestionTile(context, questions[index]),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddOrEditQuestionDialog(context),
        tooltip: 'Add Question',
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildQuestionTile(BuildContext context, DocumentSnapshot questionDoc) {
    final qData = questionDoc.data() as Map<String, dynamic>;
    final isMC = qData['type'] == 'multiple_choice';
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: ListTile(
        onTap: () => _showAddOrEditQuestionDialog(context, questionDoc: questionDoc),
        leading: Icon(isMC ? Icons.check_circle_outline : Icons.edit_note_rounded, color: isMC ? Colors.blue : Colors.orange),
        title: Text(qData['prompt'] ?? 'No Prompt', maxLines: 1, overflow: TextOverflow.ellipsis),
        subtitle: Text('Answer: ${qData['correctAnswer']}'),
        trailing: IconButton(
          icon: Icon(Icons.delete_outline, color: Theme.of(context).colorScheme.error, size: 22),
          tooltip: 'Delete question',
          onPressed: () => questionDoc.reference.delete(), // Consider adding a confirmation dialog here too
        ),
      ),
    );
  }
}
