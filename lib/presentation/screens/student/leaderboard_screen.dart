import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

// PHIÊN BẢN MỚI: Không yêu cầu Index, sắp xếp dữ liệu trên client.

class LeaderboardScreen extends StatelessWidget {
  const LeaderboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Bảng xếp hạng'),
      ),
      body: StreamBuilder<QuerySnapshot>(
        // Bỏ orderBy, chỉ lấy những user có quizStats
        stream: FirebaseFirestore.instance
            .collection('users')
            .where('quizStats.totalAttempted', isGreaterThan: 0)
            .limit(1000) // Lấy tối đa 1000 user có điểm
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Đã có lỗi xảy ra: ${snapshot.error}'));
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text('Chưa có ai trên bảng xếp hạng. Hãy là người đầu tiên!'));
          }

          // Sắp xếp dữ liệu trên client
          final users = snapshot.data!.docs;
          users.sort((a, b) {
            final statsA = (a.data() as Map<String, dynamic>)['quizStats']?['totalCorrect'] ?? 0;
            final statsB = (b.data() as Map<String, dynamic>)['quizStats']?['totalCorrect'] ?? 0;
            return statsB.compareTo(statsA); // Sắp xếp giảm dần
          });

          return ListView.builder(
            itemCount: users.length,
            itemBuilder: (context, index) {
              final user = users[index];
              final userData = user.data() as Map<String, dynamic>;
              final stats = userData['quizStats'] as Map<String, dynamic>? ?? {};

              final String name = userData['displayName'] ?? 'Anonymous';
              final int correct = stats['totalCorrect'] ?? 0;
              final int total = stats['totalAttempted'] ?? 0;
              final double accuracy = total > 0 ? (correct / total) * 100 : 0;

              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                child: ListTile(
                  leading: _buildRankIcon(index),
                  title: Text(name, style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text('Đúng: $correct / $total (${accuracy.toStringAsFixed(1)}%)'),
                  trailing: Text(
                    '#${index + 1}',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildRankIcon(int index) {
    if (index == 0) {
      return const Icon(Icons.emoji_events, color: Colors.amber, size: 40);
    } else if (index == 1) {
      return const Icon(Icons.emoji_events, color: Colors.grey, size: 35);
    } else if (index == 2) {
      return const Icon(Icons.emoji_events, color: Color(0xFFCD7F32), size: 30); // Bronze
    }
    return CircleAvatar(
      backgroundColor: Colors.blueGrey.withOpacity(0.2),
      child: Text('${index + 1}', style: const TextStyle(fontWeight: FontWeight.bold)),
    );
  }
}
