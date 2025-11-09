import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:engademy/presentation/screens/student/lesson_detail_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final displayName = user?.displayName ?? user?.email?.split('@')[0] ?? 'Learner';
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            pinned: true,
            expandedHeight: 120,
            backgroundColor: colorScheme.background,
            flexibleSpace: FlexibleSpaceBar(
              titlePadding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
              title: Text(
                'Hi, $displayName ✨',
                style: textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700, color: colorScheme.onBackground),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildDailyGoalCard(context),
                  const SizedBox(height: 32),
                  _buildSectionHeader(context, title: 'For You', icon: Icons.star_rounded),
                  const SizedBox(height: 16),
                  _buildRecommendations(context), // Widget đã được tối ưu hóa hoàn toàn
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Widget được viết lại hoàn toàn để không cần CollectionGroup Query
  Widget _buildRecommendations(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return const Center(child: Text("Please log in."));

    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance.collection('user_recommendations').doc(user.uid).snapshots(),
      builder: (context, recommendationSnapshot) {
        if (recommendationSnapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (!recommendationSnapshot.hasData || !recommendationSnapshot.data!.exists) {
          return const Center(child: Text("No recommendations available yet."));
        }

        final data = recommendationSnapshot.data!.data() as Map<String, dynamic>;
        // Danh sách bây giờ là List<Map<String, dynamic>> với { topicId, lessonId }
        final List<dynamic>? recommendations = data['recommendations'];

        if (recommendations == null || recommendations.isEmpty) {
          return const Center(child: Text("Start learning to get recommendations!"));
        }

        // Xây dựng danh sách các bài học từ "tọa độ" đã có
        return ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: recommendations.length,
          itemBuilder: (context, index) {
            final rec = recommendations[index];
            final String topicId = rec['topicId'];
            final String lessonId = rec['lessonId'];

            // Đi thẳng đến "địa chỉ" bài học, không cần càn quét database
            return FutureBuilder<DocumentSnapshot>(
              future: FirebaseFirestore.instance.collection('topics').doc(topicId).collection('lessons').doc(lessonId).get(),
              builder: (context, lessonSnapshot) {
                if (!lessonSnapshot.hasData || !lessonSnapshot.data!.exists) {
                  return const SizedBox.shrink(); // Bỏ qua nếu không tìm thấy bài học
                }
                final lessonData = lessonSnapshot.data!.data() as Map<String, dynamic>;
                return _buildRecommendedLessonTile(
                  context,
                  lessonDoc: lessonSnapshot.data!,
                  title: lessonData['title'] ?? 'Untitled Lesson',
                  duration: lessonData['duration'] as int?,
                );
              },
            );
          },
        );
      },
    );
  }

  // --- Other widgets (unchanged) ---
  Widget _buildSectionHeader(BuildContext context, {required String title, required IconData icon}) {
    return Row(
      children: [
        Icon(icon, color: Theme.of(context).colorScheme.secondary, size: 24),
        const SizedBox(width: 8),
        Text(title, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600)),
      ],
    );
  }

  Widget _buildDailyGoalCard(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    const double progress = 0.6;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        color: colorScheme.primary,
        boxShadow: [BoxShadow(color: colorScheme.primary.withOpacity(0.3), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Your Daily Progress', style: textTheme.titleLarge?.copyWith(color: colorScheme.onPrimary, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text('Keep up the great work!', style: textTheme.bodyMedium?.copyWith(color: colorScheme.onPrimary.withOpacity(0.8))),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: LinearProgressIndicator(
                    value: progress,
                    minHeight: 12,
                    backgroundColor: colorScheme.onPrimary.withOpacity(0.2),
                    valueColor: AlwaysStoppedAnimation<Color>(colorScheme.secondary),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Text('${(progress * 100).toInt()}%', style: textTheme.titleMedium?.copyWith(color: colorScheme.onPrimary, fontWeight: FontWeight.bold)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRecommendedLessonTile(BuildContext context, {required DocumentSnapshot lessonDoc, required String title, int? duration}) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (context) => LessonDetailScreen(lesson: lessonDoc))),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              Icon(Icons.play_circle_fill_rounded, color: colorScheme.primary, size: 44),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600), maxLines: 2, overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(Icons.timer_outlined, size: 16, color: colorScheme.onSurface.withOpacity(0.7)),
                        const SizedBox(width: 4),
                        Text('${duration ?? '--'} min', style: textTheme.bodyMedium?.copyWith(color: colorScheme.onSurface.withOpacity(0.7))),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Icon(Icons.arrow_forward_ios_rounded, color: colorScheme.onSurface.withOpacity(0.5), size: 18),
            ],
          ),
        ),
      ),
    );
  }
}
