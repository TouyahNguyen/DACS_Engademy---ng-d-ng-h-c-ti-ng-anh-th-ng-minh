import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:engademy/presentation/screens/admin/manage_questions_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class ManageLessonsScreen extends StatelessWidget {
  final DocumentSnapshot topic;

  const ManageLessonsScreen({super.key, required this.topic});

  void _showAddOrEditLessonDialog(BuildContext context, {DocumentSnapshot? lessonDoc}) {
    final isEditing = lessonDoc != null;
    final lessonData = isEditing ? lessonDoc.data() as Map<String, dynamic> : null;

    final titleController = TextEditingController(text: isEditing ? lessonData!['title'] : '');
    final contentController = TextEditingController(text: isEditing ? lessonData!['content'] : '');
    final durationController = TextEditingController(text: isEditing ? lessonData!['duration']?.toString() : '');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(isEditing ? 'Edit Lesson' : 'Add New Lesson'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: titleController, decoration: const InputDecoration(labelText: 'Lesson Title', border: OutlineInputBorder())),
              const SizedBox(height: 16),
              TextField(controller: durationController, keyboardType: TextInputType.number, inputFormatters: [FilteringTextInputFormatter.digitsOnly], decoration: const InputDecoration(labelText: 'Duration (minutes)', border: OutlineInputBorder())),
              const SizedBox(height: 16),
              TextField(controller: contentController, decoration: const InputDecoration(labelText: 'Lesson Content', border: OutlineInputBorder()), maxLines: 6),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              if (titleController.text.trim().isEmpty) return;
              final data = {
                'title': titleController.text.trim(),
                'content': contentController.text.trim(),
                'duration': int.tryParse(durationController.text.trim()) ?? 0,
                'createdAt': isEditing ? lessonData!['createdAt'] : FieldValue.serverTimestamp(),
              };

              try {
                if (isEditing) {
                  await lessonDoc.reference.update(data);
                } else {
                  await topic.reference.collection('lessons').add(data);
                }
                if (context.mounted) Navigator.of(context).pop();
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to save lesson: ${e.toString()}')));
              }
            },
            child: Text(isEditing ? 'Save' : 'Add'),
          ),
        ],
      ),
    );
  }

  void _showDeleteConfirmDialog(BuildContext context, DocumentSnapshot lessonDoc) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Deletion'),
        content: Text('Are you sure you want to delete the lesson "${lessonDoc['title']}"?'),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Theme.of(context).colorScheme.error),
            onPressed: () async {
              try {
                await lessonDoc.reference.delete();
                if (context.mounted) Navigator.of(context).pop();
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to delete lesson: ${e.toString()}')));
              }
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Lessons for "${topic['title']}"')),
      body: StreamBuilder<QuerySnapshot>(
        stream: topic.reference.collection('lessons').orderBy('createdAt').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator(color: Theme.of(context).colorScheme.primary));
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text('No lessons in this topic yet. Add one to get started!'));
          }
          final lessons = snapshot.data!.docs;
          return ListView.builder(
            padding: const EdgeInsets.all(8.0),
            itemCount: lessons.length,
            itemBuilder: (context, index) => _buildLessonTile(context, lessons[index]),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddOrEditLessonDialog(context),
        tooltip: 'Add Lesson',
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildLessonTile(BuildContext context, DocumentSnapshot lessonDoc) {
    final lessonData = lessonDoc.data() as Map<String, dynamic>;
    final title = lessonData['title'] ?? 'No Title';
    final duration = lessonData['duration']?.toString() ?? '0';

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: ListTile(
        onTap: () => Navigator.of(context).push(MaterialPageRoute(
          builder: (context) => ManageQuestionsScreen(lesson: lessonDoc),
        )),
        leading: const Icon(Icons.article_outlined, color: Colors.blueGrey),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text('$duration min'),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(icon: const Icon(Icons.edit_outlined, size: 22), tooltip: 'Edit lesson', onPressed: () => _showAddOrEditLessonDialog(context, lessonDoc: lessonDoc)),
            IconButton(icon: Icon(Icons.delete_outline, color: Theme.of(context).colorScheme.error, size: 22), tooltip: 'Delete lesson', onPressed: () => _showDeleteConfirmDialog(context, lessonDoc)),
          ],
        ),
      ),
    );
  }
}
