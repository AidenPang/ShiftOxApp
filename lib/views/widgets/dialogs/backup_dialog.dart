import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../../../controllers/schedule_controller.dart';
import '../../../services/backup_service.dart';
import '../../../services/google_drive_service.dart';
import 'google_drive_backup_card.dart';
import 'local_backup_card.dart';

/// 彈窗：資料備份與還原 (支援 Google 雲端硬碟與本機檔案)
class BackupDialog extends StatefulWidget {
  final ScheduleController controller;

  const BackupDialog({super.key, required this.controller});

  @override
  State<BackupDialog> createState() => _BackupDialogState();
}

class _BackupDialogState extends State<BackupDialog> {
  final GoogleDriveService _driveService = GoogleDriveService.instance;

  bool _isLoading = false;
  String? _statusMessage;
  GoogleSignInAccount? _googleUser;
  String? _cloudBackupTime;

  @override
  void initState() {
    super.initState();
    _checkGoogleSignIn();
  }

  Future<void> _checkGoogleSignIn() async {
    final user = await _driveService.signInSilently();
    if (mounted && user != null) {
      setState(() => _googleUser = user);
      _fetchCloudInfo();
    }
  }

  Future<void> _fetchCloudInfo() async {
    final info = await _driveService.getCloudBackupFileInfo();
    if (mounted && info != null) {
      final timeStr = info.modifiedTime?.toLocal().toString().split('.').first;
      setState(() => _cloudBackupTime = timeStr);
    }
  }

  Future<void> _handleGoogleSignIn() async {
    setState(() {
      _isLoading = true;
      _statusMessage = "正在連結 Google 帳號...";
    });
    try {
      final user = await _driveService.signIn();
      if (mounted) {
        setState(() {
          _googleUser = user;
          _statusMessage = user != null ? "已成功連結 ${user.email}" : "已取消登入";
        });
        if (user != null) _fetchCloudInfo();
      }
    } catch (e) {
      if (mounted) {
        setState(() => _statusMessage = "Google 登入失敗: $e");
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _handleGoogleSignOut() async {
    await _driveService.signOut();
    if (mounted) {
      setState(() {
        _googleUser = null;
        _cloudBackupTime = null;
        _statusMessage = "已登出 Google 帳號";
      });
    }
  }

  Future<void> _handleUploadToDrive() async {
    setState(() {
      _isLoading = true;
      _statusMessage = "正在同步至 Google 雲端硬碟...";
    });
    try {
      final timeStr = await _driveService.uploadBackupToDrive();
      if (mounted) {
        setState(() {
          _cloudBackupTime = timeStr;
          _statusMessage = "🎉 雲端備份成功！($timeStr)";
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("✅ 已成功備份至 Google Drive 專屬空間！")),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _statusMessage = "雲端備份失敗: $e");
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("雲端備份失敗: $e"), backgroundColor: Colors.redAccent),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _handleRestoreFromDrive() async {
    final confirm = await _showConfirmDialog(
      title: "⚠️ 確認從 Google 雲端還原？",
      content: "雲端資料將覆蓋本機相同日期的班表與記帳。確定要執行還原嗎？",
    );
    if (confirm != true) return;

    setState(() {
      _isLoading = true;
      _statusMessage = "正在從 Google 雲端下載並還原...";
    });
    try {
      final count = await _driveService.restoreBackupFromDrive(widget.controller);
      if (mounted) {
        setState(() => _statusMessage = "✅ 成功還原 $count 筆資料！");
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("🎉 成功從 Google Drive 還原 $count 筆資料！")),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _statusMessage = "雲端還原失敗: $e");
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("還原失敗: $e"), backgroundColor: Colors.redAccent),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _handleLocalExport() async {
    setState(() {
      _isLoading = true;
      _statusMessage = "正在打包本機檔案...";
    });
    try {
      final fileName = await BackupService.instance.exportBackup(context);
      if (mounted) {
        setState(() => _statusMessage = "✅ 本機匯出完成 ($fileName)");
      }
    } catch (e) {
      if (mounted) setState(() => _statusMessage = "匯出失敗: $e");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _handleLocalImport() async {
    final confirm = await _showConfirmDialog(
      title: "⚠️ 確認匯入本機備份？",
      content: "匯入檔案將覆蓋現有資料與設定。建議操作前先執行一次匯出備份以策安全！",
    );
    if (confirm != true) return;

    setState(() {
      _isLoading = true;
      _statusMessage = "正在解析本機檔案...";
    });
    try {
      final count = await BackupService.instance.pickAndRestoreBackup(widget.controller);
      if (mounted && count > 0) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("🎉 成功還原 $count 筆資料！")),
        );
      }
    } catch (e) {
      if (mounted) setState(() => _statusMessage = "還原失敗: $e");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<bool?> _showConfirmDialog({required String title, required String content}) {
    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF2C2C2C),
        title: Text(title, style: const TextStyle(color: Colors.white)),
        content: Text(content, style: const TextStyle(color: Colors.grey)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text("取消")),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.orangeAccent),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text("確定執行", style: TextStyle(color: Colors.black)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      scrollable: true,
      backgroundColor: const Color(0xFF222222),
      title: const Row(
        children: [
          Icon(Icons.cloud_sync, color: Colors.orangeAccent),
          SizedBox(width: 8),
          Text(
            "資料備份與還原",
            style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
          ),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Google 雲端硬碟區塊 ──
          GoogleDriveBackupCard(
            googleUser: _googleUser,
            cloudBackupTime: _cloudBackupTime,
            isLoading: _isLoading,
            onSignIn: _handleGoogleSignIn,
            onSignOut: _handleGoogleSignOut,
            onUpload: _handleUploadToDrive,
            onRestore: _handleRestoreFromDrive,
          ),

          const SizedBox(height: 16),

          // ── 本機檔案匯出/入區塊 ──
          LocalBackupCard(
            isLoading: _isLoading,
            onExport: _handleLocalExport,
            onImport: _handleLocalImport,
          ),

          if (_statusMessage != null) ...[
            const SizedBox(height: 14),
            Center(
              child: Text(
                _statusMessage!,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.amberAccent, fontSize: 11),
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
