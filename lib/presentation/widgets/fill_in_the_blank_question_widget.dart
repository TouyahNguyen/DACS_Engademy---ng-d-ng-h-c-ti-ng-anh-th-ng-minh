import 'package:flutter/material.dart';

class FillInTheBlankQuestionWidget extends StatelessWidget {
  final Map<String, dynamic> questionData;
  final TextEditingController controller;

  const FillInTheBlankQuestionWidget({
    super.key,
    required this.questionData,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          questionData['prompt'] ?? 'No question prompt.',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 32),
        TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: 'Your Answer',
            border: OutlineInputBorder(),
          ),
        ),
      ],
    );
  }
}
