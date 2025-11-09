import 'package:flutter/material.dart';

class MultipleChoiceQuestionWidget extends StatefulWidget {
  final Map<String, dynamic> questionData;
  final Function(String) onOptionSelected;

  const MultipleChoiceQuestionWidget({
    super.key,
    required this.questionData,
    required this.onOptionSelected,
  });

  @override
  State<MultipleChoiceQuestionWidget> createState() => _MultipleChoiceQuestionWidgetState();
}

class _MultipleChoiceQuestionWidgetState extends State<MultipleChoiceQuestionWidget> {
  String? _selectedAnswer;

  @override
  Widget build(BuildContext context) {
    final options = List<String>.from(widget.questionData['options'] ?? []);
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.questionData['prompt'] ?? 'No question prompt.',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 32),
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: options.length,
          separatorBuilder: (context, index) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            final option = options[index];
            final isSelected = _selectedAnswer == option;

            return InkWell(
              onTap: () {
                setState(() {
                  _selectedAnswer = option;
                });
                widget.onOptionSelected(option);
              },
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
                    if (isSelected) Icon(Icons.check_circle_rounded, color: colorScheme.primary),
                  ],
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}
