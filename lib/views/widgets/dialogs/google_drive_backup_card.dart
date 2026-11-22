import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';

/// Google 雲端硬碟備份與還原卡片元件
class GoogleDriveBackupCard extends StatelessWidget {
  final GoogleSignInAccount? googleUser;
  final String? cloudBackupTime;
  final bool isLoading;
  final VoidCallback onSignIn;
  final VoidCallback onSignOut;
  final VoidCallback onUpload;
  final VoidCallback onRestore;

  const GoogleDriveBackupCard({
    super.key,
    required this.googleUser,
    required this.cloudBackupTime,
    required this.isLoading,
    required this.onSignIn,
    required this.onSignOut,
    required this.onUpload,
    required this.onRestore,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF2C2C2C),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blueAccent.withAlpha(80)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                "☁️ Google Drive 雲端同步",
                style: TextStyle(
                  color: Colors.lightBlueAccent,
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
              if (googleUser != null)
                GestureDetector(
                  onTap: isLoading ? null : onSignOut,
                  child: const Text("登出", style: TextStyle(color: Colors.grey, fontSize: 12)),
                ),
            ],
          ),
          const SizedBox(height: 6),
          if (googleUser == null) ...[
            const Text(
              "登入 Google 帳號後，可一鍵無感備份到專屬隱藏空間，換手機時輕鬆復原！",
              style: TextStyle(color: Colors.white70, fontSize: 11),
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: Colors.black87,
                  padding: const EdgeInsets.symmetric(vertical: 10),
                ),
                onPressed: isLoading ? null : onSignIn,
                icon: const Icon(Icons.account_circle, color: Colors.redAccent),
                label: const Text("連結 Google 帳號", style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
          ] else ...[
            Text(
              "👤 帳號：${googleUser!.email}",
              style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w500),
            ),
            if (cloudBackupTime != null)
              Text(
                "🕒 最近備份：$cloudBackupTime",
                style: const TextStyle(color: Colors.greenAccent, fontSize: 11),
              ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blueAccent,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 8),
                    ),
                    onPressed: isLoading ? null : onUpload,
                    icon: const Icon(Icons.cloud_upload, size: 16),
                    label: const Text("雲端備份", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.lightBlueAccent,
                      side: const BorderSide(color: Colors.lightBlueAccent),
                      padding: const EdgeInsets.symmetric(vertical: 8),
                    ),
                    onPressed: isLoading ? null : onRestore,
                    icon: const Icon(Icons.cloud_download, size: 16),
                    label: const Text("雲端還原", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
