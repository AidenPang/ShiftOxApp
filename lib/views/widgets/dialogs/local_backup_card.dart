import 'package:flutter/material.dart';

/// 本機檔案匯出與匯入卡片元件
class LocalBackupCard extends StatelessWidget {
  final bool isLoading;
  final VoidCallback onExport;
  final VoidCallback onImport;

  const LocalBackupCard({
    super.key,
    required this.isLoading,
    required this.onExport,
    required this.onImport,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "📁 本機備份 (離線分享)",
          style: TextStyle(
            color: Colors.white70,
            fontSize: 13,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2E7D32),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 10),
                ),
                onPressed: isLoading ? null : onExport,
                icon: const Icon(Icons.share, size: 16),
                label: const Text(
                  "匯出 JSON",
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.orangeAccent,
                  side: const BorderSide(color: Colors.orangeAccent),
                  padding: const EdgeInsets.symmetric(vertical: 10),
                ),
                onPressed: isLoading ? null : onImport,
                icon: const Icon(Icons.file_open, size: 16),
                label: const Text(
                  "匯入還原",
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
