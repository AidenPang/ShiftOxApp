import 'package:flutter/material.dart';

/// 彈窗：顯示 AI 班表導入成功的明細結果
class ImportResultDialog extends StatelessWidget {
  final List<Map<String, dynamic>> results;

  const ImportResultDialog({super.key, required this.results});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text("🎉 成功寫入"),
      content: SizedBox(
        width: double.maxFinite,
        child: ListView.builder(
          shrinkWrap: true,
          itemCount: results.length,
          itemBuilder: (context, index) {
            final item = results[index];
            return ListTile(
              leading: Icon(Icons.check_circle, color: Theme.of(context).colorScheme.primary),
              title: Text("📅 ${item['date']} (${item['position']})"),
              subtitle: Text("⏰ 工時: ${item['start_time']} ~ ${item['end_time']}"),
            );
          },
        ),
      ),
      actions: [
        ElevatedButton(
          onPressed: () => Navigator.pop(context),
          child: const Text("好的"),
        ),
      ],
    );
  }
}

