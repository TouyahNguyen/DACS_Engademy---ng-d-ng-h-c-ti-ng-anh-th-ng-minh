import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:engademy/presentation/screens/student/lesson_detail_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

enum LessonStatus { locked, unlocked, completed }

class LessonsScreen extends StatelessWidget {
  final DocumentSnapshot topic;

  const LessonsScreen({super.key, required this.topic});

  Stream<QuerySnapshot> _getCompletedLessonsStream() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return const Stream.empty();
    return FirebaseFirestore.instance
        .collection('user_progress')
        .doc(user.uid)
        .collection('completed_lessons')
        .snapshots();
  }

  @override
  Widget build(BuildContext context) {
    final topicData = topic.data() as Map<String, dynamic>;

    return Scaffold(
      appBar: AppBar(
        title: Text(topicData['title'] ?? 'Lessons'),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: topic.reference.collection('lessons').orderBy('createdAt').snapshots(),
        builder: (context, lessonsSnapshot) {
          if (lessonsSnapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator(color: Theme.of(context).colorScheme.primary));
          }
          if (!lessonsSnapshot.hasData || lessonsSnapshot.data!.docs.isEmpty) {
            return const Center(child: Text('No lessons in this topic yet.'));
          }

          final lessons = lessonsSnapshot.data!.docs;

          // The logic is now simpler: We only care if a lesson is completed or not.
          // All non-completed lessons are considered unlocked.
          return StreamBuilder<QuerySnapshot>(
            stream: _getCompletedLessonsStream(),
            builder: (context, progressSnapshot) {
              final completedLessonIds = progressSnapshot.hasData
                  ? progressSnapshot.data!.docs.map((doc) => doc.id).toSet()
                  : <String>{};

              return ListView.builder(
                padding: const EdgeInsets.symmetric(vertical: 16.0),
                itemCount: lessons.length,
                itemBuilder: (context, index) {
                  final lessonDoc = lessons[index];
                  
                  // SIMPLIFIED LOGIC: If completed, show checkmark. Otherwise, it's always unlocked.
                  final status = completedLessonIds.contains(lessonDoc.id)
                      ? LessonStatus.completed
                      : LessonStatus.unlocked;

                  return _buildLessonTile(context, lessonDoc, index + 1, status);
                },
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildLessonTile(BuildContext context, DocumentSnapshot lessonDoc, int lessonNumber, LessonStatus status) {
    final lessonData = lessonDoc.data() as Map<String, dynamic>;
    // isLocked is now always false, because we removed the locked status.
    const isLocked = false;
    
    final duration = lessonData.containsKey('duration') ? '${lessonData['duration']} min' : '0 min';
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    IconData statusIcon;
    Color iconColor;
    switch (status) {
      case LessonStatus.completed:
        statusIcon = Icons.check_circle_rounded;
        iconColor = Colors.green;
        break;
      case LessonStatus.unlocked:
      case LessonStatus.locked: // Treat locked as unlocked for the icon
        statusIcon = Icons.play_circle_fill_rounded;
        iconColor = colorScheme.primary;
        break;
    }

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 6.0),
      clipBehavior: Clip.antiAlias,
      child: ListTile(
        onTap: () { // Always tappable
          Navigator.of(context).push(MaterialPageRoute(
            builder: (context) => LessonDetailScreen(lesson: lessonDoc),
          ));
        },
        leading: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              lessonNumber.toString().padLeft(2, '0'),
              style: textTheme.titleMedium?.copyWith(
                color: colorScheme.onBackground,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        title: Text(
          lessonData['title'] ?? 'No Title',
          style: textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
            color: colorScheme.onBackground,
          ),
        ),
        subtitle: Text(
          duration,
          style: textTheme.bodyMedium?.copyWith(color: colorScheme.onSurface.withOpacity(0.6)),
        ),
        trailing: Icon(statusIcon, color: iconColor, size: 30),
      ),
    );
  }
}
