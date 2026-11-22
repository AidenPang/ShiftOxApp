import 'package:flutter/material.dart';
import '../../../controllers/schedule_controller.dart';
import '../../../services/backup_service.dart';

/// 彈窗：資料備份與還原
class BackupDialog extends StatefulWidget {
  final ScheduleController controller;

  const BackupDialog({super.key, required this.controller});

  @override
  State<BackupDialog> createState() => _BackupDialogState();
}

class _BackupDialogState extends State<BackupDialog> {
  bool _isLoading = false;
  String? _statusMessage;

  Future<void> _handleExport() async {
    setState(() {
      _isLoading = true;
      _statusMessage = "正在打包備份資料...";
    });

    try {
      final fileName = await BackupService.instance.exportBackup(context);
      if (mounted) {
        setState(() {
          _statusMessage = "✅ 備份完成 ($fileName)";
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("🎉 備份已打包完成，可直接儲存或分享！")),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _statusMessage = "❌ 匯出失敗: $e";
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("匯出失敗: $e"), backgroundColor: Colors.redAccent),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _handleImport() async {
    // 彈出防呆確認視窗
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF2C2C2C),
        title: const Text("⚠️ 確認匯入備份？", style: TextStyle(color: Colors.white)),
        content: const Text(
          "匯入備份將會覆蓋相同日期的班表與記帳紀錄，並更新你的理財設定。建議匯入前先執行一次匯出備份以策安全！",
          style: TextStyle(color: Colors.grey),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text("取消")),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.orangeAccent),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text("確定匯入", style: TextStyle(color: Colors.black)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() {
      _isLoading = true;
      _statusMessage = "正在解析並還原資料...";
    });

    try {
      final count = await BackupService.instance.pickAndRestoreBackup(widget.controller);
      if (mounted) {
        if (count > 0) {
          setState(() {
            _statusMessage = "✅ 成功還原 $count 天的資料紀錄！";
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("🎉 成功還原 $count 筆資料與理財設定！")),
          );
          Navigator.pop(context);
        } else {
          setState(() {
            _statusMessage = "已取消選取檔案";
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _statusMessage = "❌ 還原失敗: $e";
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("還原失敗: $e"), backgroundColor: Colors.redAccent),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      scrollable: true,
      backgroundColor: const Color(0xFF222222),
      title: const Row(
        children: [
          Icon(Icons.shield_outlined, color: Colors.orangeAccent),
          SizedBox(width: 8),
          Text("資料備份與還原", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "安全防丟失！你可以將所有的打工排班、收支明細與理財設定匯出為 JSON 備份檔，隨時分享存至 Google 雲端硬碟、LINE 或電腦中。",
            style: TextStyle(color: Colors.white70, fontSize: 13, height: 1.4),
          ),
          const SizedBox(height: 20),

          // 📤 匯出按鈕
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2E7D32),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: _isLoading ? null : _handleExport,
              icon: const Icon(Icons.upload_file),
              label: const Text("📤 匯出資料備份 (JSON)", style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ),

          const SizedBox(height: 12),

          // 📥 匯入按鈕
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.orangeAccent,
                side: const BorderSide(color: Colors.orangeAccent),
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: _isLoading ? null : _handleImport,
              icon: const Icon(Icons.download),
              label: const Text("📥 選取檔案並還原", style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ),

          if (_statusMessage != null) ...[
            const SizedBox(height: 16),
            Center(
              child: Text(
                _statusMessage!,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white70, fontSize: 12),
              ),
            ),
          ],

          if (_isLoading) ...[
            const SizedBox(height: 12),
            const Center(child: CircularProgressIndicator()),
          ],
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text("關閉", style: TextStyle(color: Colors.grey)),
        ),
      ],
    );
  }
}
