import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:googleapis/drive/v3.dart' as drive;
import 'package:extension_google_sign_in_as_googleapis_auth/extension_google_sign_in_as_googleapis_auth.dart';
import '../controllers/schedule_controller.dart';
import 'backup_service.dart';

/// Google 雲端硬碟備份與還原服務 (使用 appDataFolder 私人專屬空間)
class GoogleDriveService {
  static final GoogleDriveService instance = GoogleDriveService._();
  GoogleDriveService._();

  static const String _backupFileName = 'shiftox_cloud_backup.json';

  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: [
      drive.DriveApi.driveAppdataScope, // 專屬隱藏應用空間，安全且不會被誤刪
    ],
  );

  GoogleSignInAccount? get currentUser => _googleSignIn.currentUser;

  /// 靜默檢查是否已有登入的 Google 帳號
  Future<GoogleSignInAccount?> signInSilently() async {
    try {
      return await _googleSignIn.signInSilently();
    } catch (e) {
      debugPrint("Google 靜默登入略過: $e");
      return null;
    }
  }

  /// 手動登入 Google 帳號
  Future<GoogleSignInAccount?> signIn() async {
    try {
      return await _googleSignIn.signIn();
    } catch (e) {
      debugPrint("Google 登入失敗: $e");
      rethrow;
    }
  }

  /// 登出 Google 帳號
  Future<void> signOut() async {
    await _googleSignIn.signOut();
  }

  /// 獲取經過認證的 DriveApi 客戶端
  Future<drive.DriveApi> _getDriveApi() async {
    var account = _googleSignIn.currentUser;
    account ??= await signIn();
    if (account == null) {
      throw Exception("未登入 Google 帳號，無法存取雲端硬碟");
    }

    final authClient = await account.authenticatedClient();
    if (authClient == null) {
      throw Exception("無法取得 Google 認證授權，請重試登入");
    }

    return drive.DriveApi(authClient);
  }

  /// 查詢雲端備份檔案資訊 (回傳最後修改時間與檔案大小)
  Future<drive.File?> getCloudBackupFileInfo() async {
    try {
      final driveApi = await _getDriveApi();
      final fileList = await driveApi.files.list(
        spaces: 'appDataFolder',
        q: "name = '$_backupFileName' and trashed = false",
        $fields: 'files(id, name, modifiedTime, size)',
      );

      if (fileList.files != null && fileList.files!.isNotEmpty) {
        return fileList.files!.first;
      }
      return null;
    } catch (e) {
      debugPrint("查詢雲端備份失敗: $e");
      return null;
    }
  }

  /// ☁️ 上傳備份至 Google Drive (appDataFolder 隱藏專屬空間)
  Future<String> uploadBackupToDrive() async {
    final driveApi = await _getDriveApi();

    // 1. 生成最新結構化 JSON
    final jsonString = await BackupService.instance.generateBackupJson();
    final bytes = utf8.encode(jsonString);
    final media = drive.Media(Stream.value(bytes), bytes.length);

    // 2. 檢查雲端是否已有舊備份檔
    final existingFile = await getCloudBackupFileInfo();

    if (existingFile != null && existingFile.id != null) {
      // 覆蓋更新既有檔案
      final updateFile = drive.File();
      final result = await driveApi.files.update(
        updateFile,
        existingFile.id!,
        uploadMedia: media,
      );
      final timeStr = result.modifiedTime?.toLocal().toString().split('.').first ?? "剛剛";
      return timeStr;
    } else {
      // 首次建立檔案
      final newFile = drive.File()
        ..name = _backupFileName
        ..parents = ['appDataFolder']
        ..mimeType = 'application/json';

      final result = await driveApi.files.create(
        newFile,
        uploadMedia: media,
      );
      final timeStr = result.modifiedTime?.toLocal().toString().split('.').first ?? "剛剛";
      return timeStr;
    }
  }

  /// ☁️ 從 Google Drive 下載並還原至本地 SQLite
  Future<int> restoreBackupFromDrive(ScheduleController controller) async {
    final driveApi = await _getDriveApi();

    // 1. 查找備份檔案
    final existingFile = await getCloudBackupFileInfo();
    if (existingFile == null || existingFile.id == null) {
      throw Exception("Google 雲端硬碟中尚無任何 ShiftOx 備份紀錄！");
    }

    // 2. 下載媒體檔案流
    final media = await driveApi.files.get(
      existingFile.id!,
      downloadOptions: drive.DownloadOptions.fullMedia,
    ) as drive.Media;

    final List<int> dataStore = [];
    await for (final data in media.stream) {
      dataStore.addAll(data);
    }

    final rawJson = utf8.decode(dataStore);

    // 3. 解析並還原至本地
    return await BackupService.instance.restoreBackupFromJson(rawJson, controller);
  }
}
