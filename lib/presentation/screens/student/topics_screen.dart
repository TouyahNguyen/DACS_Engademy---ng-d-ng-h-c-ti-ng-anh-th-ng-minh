import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:engademy/presentation/screens/student/lessons_screen.dart';
import 'package:flutter/material.dart';

// Helper to get a relevant icon based on keywords in the topic title.
IconData _getIconForTopic(String title) {
  final lowerTitle = title.toLowerCase();
  if (lowerTitle.contains('grammar')) return Icons.spellcheck_rounded;
  if (lowerTitle.contains('vocab')) return Icons.menu_book_rounded;
  if (lowerTitle.contains('talk') || lowerTitle.contains('speak') || lowerTitle.contains('chat')) return Icons.record_voice_over_rounded;
  if (lowerTitle.contains('ielts') || lowerTitle.contains('test')) return Icons.school_rounded;
  if (lowerTitle.contains('business')) return Icons.business_center;
  return Icons.category_rounded; // Default icon
}

class TopicsScreen extends StatelessWidget {
  const TopicsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // AppBar is now styled by the global theme in app_theme.dart
      appBar: AppBar(
        title: const Text('All Topics'),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('topics').orderBy('title').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            // Use a themed circular progress indicator
            return Center(child: CircularProgressIndicator(color: Theme.of(context).colorScheme.primary));
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(
              child: Text('No topics available yet.', style: TextStyle(fontSize: 18, color: Colors.grey)),
            );
          }

          final topics = snapshot.data!.docs;

          return GridView.builder(
            padding: const EdgeInsets.all(20.0),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 20,
              mainAxisSpacing: 20,
              childAspectRatio: 0.9, // Adjust card shape for more content
            ),
            itemCount: topics.length,
            itemBuilder: (context, index) {
              final topicDoc = topics[index];
              return _buildTopicCard(context, topicDoc);
            },
          );
        },
      ),
    );
  }

  Widget _buildTopicCard(BuildContext context, DocumentSnapshot topicDoc) {
    final topicData = topicDoc.data() as Map<String, dynamic>;
    final title = topicData['title'] ?? 'No Title';
    final icon = _getIconForTopic(title);
    final fakeLessonCount = (title.hashCode % 5) + 8; // Fake lesson count: 8-12

    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Card(
      // Using the global CardTheme for consistent styling
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () {
          Navigator.of(context).push(MaterialPageRoute(
            builder: (context) => LessonsScreen(topic: topicDoc),
          ));
        },
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Icon with a soft background
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: colorScheme.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: colorScheme.primary, size: 32),
              ),
              const SizedBox(height: 12),
              // Title and lesson count
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '$fakeLessonCount Lessons',
                    style: textTheme.bodySmall?.copyWith(color: colorScheme.onSurface.withOpacity(0.7)),
                  ),
                ],
              )
            ],
          ),
        ),
      ),
    );
  }
}
