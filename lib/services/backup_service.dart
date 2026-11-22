import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/database_helper.dart';
import '../models/schedule_model.dart';
import '../controllers/schedule_controller.dart';

/// 備份與還原服務 (封裝資料庫打包與解析，共用於本地與 Google Drive 雲端)
class BackupService {
  static final BackupService instance = BackupService._();
  BackupService._();

  /// 📦 核心方法：將當前資料庫、時薪與理財設定打包為 JSON 字串
  Future<String> generateBackupJson() async {
    final schedules = await DatabaseHelper.instance.getAllSchedules();
    final hourlyWage = await DatabaseHelper.instance.getHourlyWage();

    final prefs = await SharedPreferences.getInstance();
    final monthlyTarget = prefs.getInt('monthlyTarget') ?? 10000;
    final currentCash = prefs.getInt('currentCash') ?? 0;
    final claimedMonths = prefs.getStringList('claimedMonths') ?? [];

    final now = DateTime.now();
    final Map<String, dynamic> backupPayload = {
      'app': 'ShiftOx',
      'version': 1,
      'exported_at': now.toIso8601String(),
      'metadata': {
        'total_days_count': schedules.length,
        'hourly_wage': hourlyWage,
      },
      'settings': {
        'hourly_wage': hourlyWage,
      },
      'preferences': {
        'monthlyTarget': monthlyTarget,
        'currentCash': currentCash,
        'claimedMonths': claimedMonths,
      },
      'schedules': schedules.map((s) => s.toMap()).toList(),
    };

    return const JsonEncoder.withIndent('  ').convert(backupPayload);
  }

  /// 🔄 核心方法：將 JSON 字串解析並完整還原至 SQLite 與 SharedPreferences
  Future<int> restoreBackupFromJson(String rawContent, ScheduleController controller) async {
    final dynamic decoded = jsonDecode(rawContent);

    if (decoded is! Map || decoded['app'] != 'ShiftOx') {
      throw Exception("格式不符：這不是合法的「牛馬日誌」備份檔案！");
    }

    // 1. 還原 schedules 表格
    int restoredSchedulesCount = 0;
    if (decoded['schedules'] is List) {
      final list = decoded['schedules'] as List;
      for (var item in list) {
        if (item is Map) {
          final model = ScheduleModel.fromMap(Map<String, dynamic>.from(item));
          await DatabaseHelper.instance.insertOrUpdateSchedule(model);
          restoredSchedulesCount++;
        }
      }
    }

    // 2. 還原 settings 表格 (時薪)
    if (decoded['settings'] is Map) {
      final settings = decoded['settings'] as Map;
      if (settings['hourly_wage'] != null) {
        final wage = int.tryParse(settings['hourly_wage'].toString()) ?? 196;
        await DatabaseHelper.instance.setHourlyWage(wage);
      }
    }

    // 3. 還原 preferences (理財生存雷達數據)
    if (decoded['preferences'] is Map) {
      final prefsMap = decoded['preferences'] as Map;
      final prefs = await SharedPreferences.getInstance();

      if (prefsMap['monthlyTarget'] != null) {
        await prefs.setInt('monthlyTarget', int.tryParse(prefsMap['monthlyTarget'].toString()) ?? 10000);
      }
      if (prefsMap['currentCash'] != null) {
        await prefs.setInt('currentCash', int.tryParse(prefsMap['currentCash'].toString()) ?? 0);
      }
      if (prefsMap['claimedMonths'] is List) {
        await prefs.setStringList('claimedMonths', List<String>.from(prefsMap['claimedMonths']));
      }
    }

    // 4. 通知 Controller 重新加載所有狀態以即時更新畫面
    await controller.loadTargetSavings();
    final now = DateTime.now();
    final todayStr = "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}";
    await controller.loadScheduleByDate(todayStr);

    return restoredSchedulesCount;
  }

  /// 📤 匯出本機備份：打包所有資料並喚起系統分享面板
  Future<String?> exportBackup(BuildContext context) async {
    try {
      final jsonString = await generateBackupJson();

      final now = DateTime.now();
      final dateTag = "${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}_${now.hour.toString().padLeft(2, '0')}${now.minute.toString().padLeft(2, '0')}";

      final tempDir = await getTemporaryDirectory();
      final fileName = 'shiftox_backup_$dateTag.json';
      final file = File('${tempDir.path}/$fileName');
      await file.writeAsString(jsonString, flush: true);

      final box = context.findRenderObject() as RenderBox?;
      final originRect = box != null ? box.localToGlobal(Offset.zero) & box.size : null;

      await Share.shareXFiles(
        [XFile(file.path)],
        subject: '牛馬日誌資料備份 ($dateTag)',
        sharePositionOrigin: originRect,
      );

      return fileName;
    } catch (e) {
      debugPrint('匯出備份失敗: $e');
      rethrow;
    }
  }

  /// 📥 匯入本機備份：選取檔案並還原
  Future<int> pickAndRestoreBackup(ScheduleController controller) async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json'],
      );

      if (result == null || result.files.isEmpty) {
        return 0;
      }

      final filePath = result.files.single.path;
      if (filePath == null) {
        throw Exception("無法取得檔案路徑");
      }

      final file = File(filePath);
      final rawContent = await file.readAsString();
      return await restoreBackupFromJson(rawContent, controller);
    } catch (e) {
      debugPrint('還原備份失敗: $e');
      rethrow;
    }
  }
}
