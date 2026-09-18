import 'dart:convert';

class ScheduleModel {
  final String date;           // 日期 (格式：YYYY-MM-DD) 
  final String position;       // 當日打工職位 
  final String startTime;      // 上班時間 (格式：HH:mm) 
  final String endTime;        // 下班時間 (格式：HH:mm) 
  final int expenseAmount;     // 當日消費記帳總額（自動加總後的結果）
  final String expenseNote;    // 儲存多筆明細的 JSON 字串 (例如: [{"title":"午餐","amount":100}])

  ScheduleModel({
    required this.date,
    required this.position,
    required this.startTime,
    required this.endTime,
    required this.expenseAmount,
    required this.expenseNote,
  });

  // 📥 將資料庫查出來的 Map 轉換成 Dart 物件
  factory ScheduleModel.fromMap(Map<String, dynamic> map) {
    return ScheduleModel(
      date: map['date'] ?? '',
      position: map['position'] ?? '',
      startTime: map['start_time'] ?? '',
      endTime: map['end_time'] ?? '',
      expenseAmount: map['expense_amount'] ?? 0,
      expenseNote: map['expense_note'] ?? '',
    );
  }

  // 📤 將 Dart 物件轉換成可以寫入 SQLite 的 Map 格式
  Map<String, dynamic> toMap() {
    return {
      'date': date,
      'position': position,
      'start_time': startTime,
      'end_time': endTime,
      'expense_amount': expenseAmount,
      'expense_note': expenseNote,
    };
  }

  // 💡 貼心小工具：將 JSON 字串還原成 Dart 的 List 明細，方便畫面渲染
  List<Map<String, dynamic>> getExpenseList() {
    if (expenseNote.isEmpty) return [];
    // 如果偵測到舊資料庫存的是純文字（開頭不是 JSON 的 [ 符號），直接打包轉換
    if (!expenseNote.startsWith('[')) {
      return [{
        'title': expenseNote, // 舊的備忘錄當作項目名稱
        'amount': expenseAmount, // 舊的總額當作該項目金額
      }];
    }
    try {
      List<dynamic> decoded = jsonDecode(expenseNote);
      return decoded.map((e) => Map<String, dynamic>.from(e)).toList();
    } catch (e) {
      return [];
    }
  }
}