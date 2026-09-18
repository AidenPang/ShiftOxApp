import 'package:flutter/material.dart';

class FinanceCard extends StatelessWidget {
  final String title;
  final String content;
  final Color color;
  final String subText;

  const FinanceCard({
    super.key,
    required this.title,
    required this.content,
    required this.color,
    this.subText = "",
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: 165,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface, // 💡 使用主題的表面顏色
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: theme.colorScheme.outlineVariant.withAlpha(128)), // 💡 使用 withAlpha 替換 withOpacity
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: TextStyle(fontSize: 11, color: theme.colorScheme.onSurfaceVariant)), // 💡 使用主題的次要文字顏色
          const SizedBox(height: 2),
          Text(content, style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: color)),
          if (subText.isNotEmpty) ...[
            const SizedBox(height: 2),
            Text(subText, style: TextStyle(fontSize: 10, color: theme.colorScheme.onSurfaceVariant, fontStyle: FontStyle.italic)),
          ]
        ],
      ),
    );
  }
}