import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:engademy/presentation/screens/admin/manage_lessons_screen.dart';
import 'package:flutter/material.dart';

class ManageTopicsScreen extends StatelessWidget {
  const ManageTopicsScreen({super.key});

  void _showAddOrEditTopicDialog(BuildContext context, {DocumentSnapshot? topicDoc}) {
    final isEditing = topicDoc != null;
    final titleController = TextEditingController(text: isEditing ? topicDoc['title'] : '');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(isEditing ? 'Edit Topic' : 'Add New Topic'),
        content: TextField(
          controller: titleController,
          autofocus: true,
          decoration: const InputDecoration(labelText: 'Topic Title', hintText: 'e.g., Everyday Conversations'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              if (titleController.text.trim().isEmpty) return;
              try {
                if (isEditing) {
                  await topicDoc.reference.update({'title': titleController.text.trim()});
                } else {
                  await FirebaseFirestore.instance.collection('topics').add({
                    'title': titleController.text.trim(),
                    'createdAt': FieldValue.serverTimestamp(),
                  });
                }
                if (context.mounted) Navigator.of(context).pop();
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to save topic: ${e.toString()}')));
              }
            },
            child: Text(isEditing ? 'Save' : 'Add'),
          ),
        ],
      ),
    );
  }

  void _showDeleteConfirmDialog(BuildContext context, DocumentSnapshot topicDoc) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Deletion'),
        content: Text('Are you sure you want to delete the topic "${topicDoc['title']}"? This will also delete all lessons and questions inside it.'),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Theme.of(context).colorScheme.error),
            onPressed: () async {
              try {
                await topicDoc.reference.delete();
                if (context.mounted) Navigator.of(context).pop();
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to delete topic: ${e.toString()}')));
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
      appBar: AppBar(title: const Text('Manage Topics')),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('topics').orderBy('createdAt', descending: true).snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator(color: Theme.of(context).colorScheme.primary));
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text('No topics yet. Add one to get started!'));
          }

          final topics = snapshot.data!.docs;

          return ListView.builder(
            padding: const EdgeInsets.all(8.0),
            itemCount: topics.length,
            itemBuilder: (context, index) {
              final topicDoc = topics[index];
              return _buildTopicTile(context, topicDoc);
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddOrEditTopicDialog(context),
        tooltip: 'Add Topic',
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildTopicTile(BuildContext context, DocumentSnapshot topicDoc) {
    final title = (topicDoc.data() as Map<String, dynamic>)['title'] ?? 'No Title';

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: ListTile(
        onTap: () => Navigator.of(context).push(MaterialPageRoute(
          builder: (context) => ManageLessonsScreen(topic: topicDoc),
        )),
        leading: const Icon(Icons.folder_copy_outlined, color: Colors.purple),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.edit_outlined, size: 22), 
              tooltip: 'Edit title',
              onPressed: () => _showAddOrEditTopicDialog(context, topicDoc: topicDoc),
            ),
            IconButton(
              icon: Icon(Icons.delete_outline, color: Theme.of(context).colorScheme.error, size: 22),
              tooltip: 'Delete topic',
              onPressed: () => _showDeleteConfirmDialog(context, topicDoc),
            ),
          ],
        ),
      ),
    );
  }
}
