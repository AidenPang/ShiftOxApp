import 'dart:convert';

class ScheduleModel {
  final String date;           // 日期 (格式：YYYY-MM-DD) 
  final String position;       // 當日打工職位 
  final String startTime;      // 上班時間 (格式：HH:mm) 
  final String endTime;        // 下班時間 (格式：HH:mm) 
  final int expenseAmount;     // 當日消費記帳總額（自動加總後的結果）
  final String expenseNote;    // 儲存多筆明細的 JSON 字串 (例如: [{"title":"午餐","amount":100}])
  final int incomeAmount;      // 當日進帳總額（自動加總後的結果）
  final String incomeNote;     // 儲存多筆收入明細的 JSON 字串 (例如: [{"title":"二手書","amount":200}])
  final String shiftsNote;     // 儲存多筆排班的 JSON 字串 (例如: [{"position":"晚班","start_time":"17:00","end_time":"22:00"}])

  ScheduleModel({
    required this.date,
    required this.position,
    required this.startTime,
    required this.endTime,
    this.expenseAmount = 0,
    this.expenseNote = "[]",
    this.incomeAmount = 0,    
    this.incomeNote = "[]", 
    this.shiftsNote = "[]", 
  });

  // 📥 將資料庫查出來的 Map 轉換成 Dart 物件
  factory ScheduleModel.fromMap(Map<String, dynamic> map) {
    return ScheduleModel(
      date: map['date'] as String,
      position: map['position'] as String,
      startTime: map['start_time'] as String,
      endTime: map['end_time'] as String,
      expenseAmount: map['expense_amount'] as int? ?? 0,
      expenseNote: map['expense_note'] as String? ?? "[]",
      incomeAmount: map['income_amount'] as int? ?? 0, 
      incomeNote: map['income_note'] as String? ?? "[]",
      shiftsNote: map['shifts_note'] as String? ?? "[]",
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
      'income_amount': incomeAmount, 
      'income_note': incomeNote,
      'shifts_note': shiftsNote,
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

  // 解析收入 JSON
  List<Map<String, dynamic>> getIncomeList() {
    try {
      return List<Map<String, dynamic>>.from(jsonDecode(incomeNote));
    } catch (e) {
      return [];
    }
  }

  // 解析排班 JSON，並自動相容舊版單一排班資料
  List<Map<String, dynamic>> getShiftsList() {
    try {
      List<Map<String, dynamic>> list = List<Map<String, dynamic>>.from(jsonDecode(shiftsNote));
      // 如果新版 JSON 是空的，但舊版欄位有資料，就自動幫它包裝成第一筆班表！
      if (list.isEmpty && position.isNotEmpty && startTime.isNotEmpty) {
        return [{
          'position': position,
          'start_time': startTime,
          'end_time': endTime,
        }];
      }
      return list;
    } catch (e) {
      return [];
    }
  }
}