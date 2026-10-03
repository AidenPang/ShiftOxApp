import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart'; // 💡 引入相機套件
import 'package:shared_preferences/shared_preferences.dart';
import '../models/database_helper.dart';
import '../models/schedule_model.dart';
import '../services/ai_service.dart';

class ScheduleController extends ChangeNotifier {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;
  final ImagePicker _picker = ImagePicker(); // 💡 相機與相簿實例
  final AIService _aiService = AIService(); // 💡 宣告獨立的 AI 服務

  // 1. 儲存目前在畫面上被選中日期的排班/記帳資料
  ScheduleModel? currentSchedule;
  bool isLoading = false;

  // 💰 當前設定的時薪
  int hourlyWage = 196;
  // 📊 當月累計預算統計數據
  int monthlyTotalSalary = 0; // 本月預估薪資加總 
  int monthlyTotalExpense = 0; // 本月消費記帳加總

  // 🔄 初始化載入時薪與當月統計
  Future<void> initSettingsAndStats(String yearMonth) async {
    hourlyWage = await _dbHelper.getHourlyWage();
    await calculateMonthlyStats(yearMonth);
  }

  // 🔍 核心邏輯：去本地資料庫抓特定日期的資料
  Future<void> loadScheduleByDate(String date) async {
    // 讀取時薪與當日資料
    hourlyWage = await _dbHelper.getHourlyWage();
    currentSchedule = await _dbHelper.getScheduleByDate(date);
    // 重新計算當月累計薪水與記帳
    final String yearMonth = date.substring(0, 7); // 提取 "YYYY-MM"
    await calculateMonthlyStats(yearMonth);
    isLoading = false;
    notifyListeners(); // 告訴畫面：資料撈回來了，請重新渲染更新畫面！
  }

  // 💰 更新時薪設定
  Future<void> updateHourlyWage(int newWage, String currentDate) async {
    await _dbHelper.setHourlyWage(newWage);
    hourlyWage = newWage;
    // 重新加總薪資並更新畫面 
    await loadScheduleByDate(currentDate); 
  }

  // ⏰ 輔助工具：計算單日工時 (輸入 HH:mm, HH:mm ➔ 回傳 double 小時數) 
  double calculateHours(String start, String end) {
    if (start.isEmpty || end.isEmpty || start == "--:--" || end == "--:--") return 0.0;
    try {
      final startParts = start.split(':');
      final endParts = end.split(':');
      final startMin = int.parse(startParts[0]) * 60 + int.parse(startParts[1]);
      var endMin = int.parse(endParts[0]) * 60 + int.parse(endParts[1]);

      // 防呆：如果下班時間小於上班時間，代表跨夜（例如 23:00 上班到 04:00 下班）
      if (endMin < startMin) {
        endMin += 24 * 60; // 補足 24 小時
      }

      return (endMin - startMin) / 60.0;
    } catch (e) {
      return 0.0;
    }
  }

  // 📊 核心運算：計算整個月的薪資與記帳加總 
  Future<void> calculateMonthlyStats(String yearMonth) async {
    final List<ScheduleModel> monthlySchedules = await _dbHelper.getSchedulesByMonth(yearMonth);
    double totalHours = 0.0;
    int totalExpense = 0;

    for (var schedule in monthlySchedules) {
      // 1. 累加工時 
      double hours = getDailyTotalHours(schedule);
      totalHours += hours;
      // 2. 累加記帳
      totalExpense += schedule.expenseAmount;
    }
    // 3. 預估薪資 = 總工時 * 時薪 
    monthlyTotalSalary = (totalHours * hourlyWage).round();
    monthlyTotalExpense = totalExpense;
  }

  //  1. 取得單日「所有排班」的總工時
  double getDailyTotalHours(ScheduleModel? schedule) {
    if (schedule == null) return 0.0;
    List<Map<String, dynamic>> shifts = schedule.getShiftsList();
    double totalHours = 0.0;
    for (var shift in shifts) {
      totalHours += calculateHours(shift['start_time'] ?? '', shift['end_time'] ?? '');
    }
    return totalHours;
  }

  // 💡 2. 新增單筆排班 (存入 JSON 陣列)
  Future<void> addWorkShift({
    required String date,
    required String position,
    required String startTime,
    required String endTime,
  }) async {
    await loadScheduleByDate(date);
    ScheduleModel schedule = currentSchedule ?? ScheduleModel(date: date, position: "", startTime: "", endTime: "");

    List<Map<String, dynamic>> shifts = schedule.getShiftsList();
    shifts.add({
      'position': position,
      'start_time': startTime,
      'end_time': endTime,
    });

    await DatabaseHelper.instance.insertOrUpdateSchedule(
      ScheduleModel(
        date: date,
        position: "", 
        startTime: "",
        endTime: "",
        expenseAmount: schedule.expenseAmount,
        expenseNote: schedule.expenseNote,
        incomeAmount: schedule.incomeAmount,
        incomeNote: schedule.incomeNote,
        shiftsNote: jsonEncode(shifts), // 🚀 寫入新的陣列
      )
    );
    await loadScheduleByDate(date);
    await calculateMonthlyStats(date.substring(0, 7));
  }

  // 💡 3. 修改單筆排班
  Future<void> editWorkShift({
    required String date,
    required int index,
    required String newPosition,
    required String newStart,
    required String newEnd,
  }) async {
    await loadScheduleByDate(date);
    if (currentSchedule == null) return;

    List<Map<String, dynamic>> shifts = currentSchedule!.getShiftsList();
    if (index >= 0 && index < shifts.length) {
      shifts[index] = {'position': newPosition, 'start_time': newStart, 'end_time': newEnd};

      await DatabaseHelper.instance.insertOrUpdateSchedule(
        ScheduleModel(
          date: date,
          position: "",
          startTime: "",
          endTime: "",
          expenseAmount: currentSchedule!.expenseAmount,
          expenseNote: currentSchedule!.expenseNote,
          incomeAmount: currentSchedule!.incomeAmount,
          incomeNote: currentSchedule!.incomeNote,
          shiftsNote: jsonEncode(shifts),
        )
      );
      await loadScheduleByDate(date);
      await calculateMonthlyStats(date.substring(0, 7));
    }
  }

  // 💡 4. 刪除單筆排班
  Future<void> deleteWorkShift({required String date, required int index}) async {
    await loadScheduleByDate(date);
    if (currentSchedule == null) return;

    List<Map<String, dynamic>> shifts = currentSchedule!.getShiftsList();
    if (index >= 0 && index < shifts.length) {
      shifts.removeAt(index);

      await DatabaseHelper.instance.insertOrUpdateSchedule(
        ScheduleModel(
          date: date,
          position: "",
          startTime: "",
          endTime: "",
          expenseAmount: currentSchedule!.expenseAmount,
          expenseNote: currentSchedule!.expenseNote,
          incomeAmount: currentSchedule!.incomeAmount,
          incomeNote: currentSchedule!.incomeNote,
          shiftsNote: jsonEncode(shifts),
        )
      );
      await loadScheduleByDate(date);
      await calculateMonthlyStats(date.substring(0, 7));
    }
  }


  // ==========================================
  // 💸 記帳功能 (支出與收入共用，徹底瘦身！)
  // 💡 只要傳入 isIncome: true 就是記收入，false 就是記支出
  // ==========================================

  Future<void> addTransaction({
    required String date,
    required String itemTitle,
    required int itemAmount,
    required bool isIncome, 
  }) async {
    final dbSchedule = await _dbHelper.getScheduleByDate(date);
    String migratedShifts = jsonEncode(dbSchedule?.getShiftsList() ?? currentSchedule?.getShiftsList() ?? []);
    // 💡 根據 isIncome 決定要撈哪個清單
    List<Map<String, dynamic>> currentList = isIncome 
        ? (dbSchedule?.getIncomeList() ?? currentSchedule?.getIncomeList() ?? [])
        : (dbSchedule?.getExpenseList() ?? currentSchedule?.getExpenseList() ?? []);

    currentList.add({
      'title': itemTitle.isEmpty ? '未命名' : itemTitle,
      'amount': itemAmount,
    });

    int totalAmount = currentList.fold(0, (sum, item) => sum + (item['amount'] as int));
    String jsonNoteString = jsonEncode(currentList);

    // 💡 根據 isIncome 決定要更新哪個欄位，另一個欄位保留舊值
    final updatedSchedule = ScheduleModel(
      date: date,
      position: "",
      startTime: "",
      endTime: "",
      expenseAmount: isIncome ? (dbSchedule?.expenseAmount ?? 0) : totalAmount,
      expenseNote: isIncome ? (dbSchedule?.expenseNote ?? "[]") : jsonNoteString,
      incomeAmount: isIncome ? totalAmount : (dbSchedule?.incomeAmount ?? 0),
      incomeNote: isIncome ? jsonNoteString : (dbSchedule?.incomeNote ?? "[]"),
      shiftsNote: migratedShifts,
    );

    await _dbHelper.insertOrUpdateSchedule(updatedSchedule);
    await loadScheduleByDate(date);

    // 💡 連動錢包：收入加錢，支出扣錢
    await adjustCurrentCash(isIncome ? itemAmount : -itemAmount);
  }

  // ✏️ 修改單筆明細 (共用)
  Future<void> editTransaction({
    required String date,
    required int index,
    required String newTitle,
    required int newAmount,
    required bool isIncome,
  }) async {
    final schedule = await _dbHelper.getScheduleByDate(date);
    if (schedule == null) return;

    List<Map<String, dynamic>> currentList = isIncome ? schedule.getIncomeList() : schedule.getExpenseList();
    if (index < 0 || index >= currentList.length) return;

    int oldAmount = currentList[index]['amount'] as int;
    currentList[index] = {'title': newTitle, 'amount': newAmount};

    int totalAmount = currentList.fold(0, (sum, item) => sum + (item['amount'] as int));
    String jsonNoteString = jsonEncode(currentList);

    final updatedSchedule = ScheduleModel(
      date: date,
      position: "",
      startTime: "",
      endTime: "",
      expenseAmount: isIncome ? schedule.expenseAmount : totalAmount,
      expenseNote: isIncome ? schedule.expenseNote : jsonNoteString,
      incomeAmount: isIncome ? totalAmount : schedule.incomeAmount,
      incomeNote: isIncome ? jsonNoteString : schedule.incomeNote,
    );

    await _dbHelper.insertOrUpdateSchedule(updatedSchedule);
    await loadScheduleByDate(date);

    // 💡 計算差額補退：收入(新-舊)，支出(舊-新)
    int difference = isIncome ? (newAmount - oldAmount) : (oldAmount - newAmount); 
    await adjustCurrentCash(difference);
  }

  // 🗑️ 刪除單筆明細 (共用)
  Future<void> deleteTransaction({
    required String date, 
    required int index,
    required bool isIncome,
  }) async {
    final schedule = await _dbHelper.getScheduleByDate(date);
    if (schedule == null) return;

    List<Map<String, dynamic>> currentList = isIncome ? schedule.getIncomeList() : schedule.getExpenseList();
    if (index < 0 || index >= currentList.length) return;

    int deletedAmount = currentList[index]['amount'] as int;
    currentList.removeAt(index);

    int totalAmount = currentList.fold(0, (sum, item) => sum + (item['amount'] as int));
    String jsonNoteString = jsonEncode(currentList);
    String migratedShifts = jsonEncode(schedule.getShiftsList());

    final updatedSchedule = ScheduleModel(
      date: date,
      position: "",
      startTime: "",
      endTime: "",
      expenseAmount: isIncome ? schedule.expenseAmount : totalAmount,
      expenseNote: isIncome ? schedule.expenseNote : jsonNoteString,
      incomeAmount: isIncome ? totalAmount : schedule.incomeAmount,
      incomeNote: isIncome ? jsonNoteString : schedule.incomeNote,
      shiftsNote: migratedShifts,
    );

    await _dbHelper.insertOrUpdateSchedule(updatedSchedule);
    await loadScheduleByDate(date);
    
    // 💡 刪除時：收入扣除，支出退回
    await adjustCurrentCash(isIncome ? -deletedAmount : deletedAmount);
  }
  

  // ==========================================
  // 🔥🔥🔥 階段二核心：AI 拍照/選相簿 ＆ 班表識別 
  // ==========================================

  Future<List<Map<String, dynamic>>> scanAndImportSchedule(BuildContext context, ImageSource source, String currentDate) async {
    List<Map<String, dynamic>> importedSchedules = []; //  紀錄這次寫入了什麼
    try {
      // 1. 叫起相機或相簿選取班表圖片 
      final XFile? image = await _picker.pickImage(
        source: source,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );
      if (image == null) return importedSchedules; 

      isLoading = true;
      notifyListeners();

      // 2. 讀取圖片 Byte 數據以準備傳給 Gemini 
      final imageBytes = await image.readAsBytes();
      final String targetYear = currentDate.substring(0, 4);

      //  呼叫剛剛抽離出去的 AI Service，Controller 只專心負責資料庫寫入
      final List<Map<String, dynamic>> parsedList = await _aiService.scanScheduleImage(imageBytes, targetYear);

      for (var item in parsedList) {
        final String date = item['date'] ?? '';
        if (date.isEmpty) continue;

        //  1. 抓取資料庫那一天原本的資料
        final existing = await _dbHelper.getScheduleByDate(date);
        
        //  2. 嚴格保留所有的「記帳、收入」資料，才不會被洗掉
        final int expenseAmount = existing?.expenseAmount ?? 0;
        final String expenseNote = existing?.expenseNote ?? "[]";
        final int incomeAmount = existing?.incomeAmount ?? 0;
        final String incomeNote = existing?.incomeNote ?? "[]";

        //  3. 取出那一天「已經存在的排班陣列」
        List<Map<String, dynamic>> currentShifts = existing?.getShiftsList() ?? [];

        //  4. 把 AI 辨識到的新班表，加入到陣列中！
        currentShifts.add({
          'position': item['position'] ?? '打工班',
          'start_time': item['start_time'] ?? '17:00',
          'end_time': item['end_time'] ?? '22:00',
        });

        //  5. 重新打包存入資料庫
        final schedule = ScheduleModel(
          date: date,
          position: "", 
          startTime: "",
          endTime: "",
          expenseAmount: expenseAmount,
          expenseNote: expenseNote,
          incomeAmount: incomeAmount,
          incomeNote: incomeNote,
          shiftsNote: jsonEncode(currentShifts), // 🚀 關鍵：把更新後的陣列寫入
        );

        // 寫入本地資料庫 
        await _dbHelper.insertOrUpdateSchedule(schedule);
        importedSchedules.add(item);
      }

      await loadScheduleByDate(currentDate);
      return importedSchedules; // 💡 回傳清單
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("❌ 班表導入失敗: $e")),
        );
      }
    } finally {
      isLoading = false;
      notifyListeners();
    }
    return importedSchedules;
  }

  // ==========================================
  // 💰 理財戰情室：學費與生存配速邏輯
  // ==========================================
  
  int _monthlyTargetSavings = 10000; // 預設每月預留學費/存錢額度
  int get monthlyTargetSavings => _monthlyTargetSavings;

  // 現有資金水位 (手上有多少錢)
  int _currentCash = 0; 
  int get currentCash => _currentCash;

  // 記錄哪些月份已經領過薪水 (例如: ["2026-08", "2026-09"])
  List<String> _claimedMonths = [];

  // 📖 讀取存錢目標
  Future<void> loadTargetSavings() async {
    final prefs = await SharedPreferences.getInstance();
    _monthlyTargetSavings = prefs.getInt('monthlyTarget') ?? 10000;
    _currentCash = prefs.getInt('currentCash') ?? 0;
    _claimedMonths = prefs.getStringList('claimedMonths') ?? [];
    notifyListeners(); // 刷新畫面
  }

  // ✏️ 寫入並更新存錢目標
  Future<void> updateTargetSavings(int target) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('monthlyTarget', target);
    _monthlyTargetSavings = target;
    notifyListeners();
  }

  // ✏️ 手動校正現有資金 
  Future<void> updateCurrentCash(int cash) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('currentCash', cash);
    _currentCash = cash;
    notifyListeners();
  }

  // 💵 領取上個月薪水功能
  Future<String> claimPreviousMonthSalary() async {
    final now = DateTime.now();
    // 計算上個月的年月份字串 (例如: 現在 2026-09，上個月就是 2026-08)
    DateTime lastMonthDate = DateTime(now.year, now.month - 1, 1);
    String lastMonthStr = "${lastMonthDate.year}-${lastMonthDate.month.toString().padLeft(2, '0')}";

    if (_claimedMonths.contains(lastMonthStr)) {
      return "⚠️ 您已經領取過 $lastMonthStr 的薪水囉！";
    }

    // 讀取上個月的總薪水
    await calculateMonthlyStats(lastMonthStr); 
    int lastMonthSalary = monthlyTotalSalary; // 取得上個月薪水

    if (lastMonthSalary == 0) {
       // 算完後，把這個月的統計數字切回「當前月份」，以免畫面顯示錯亂
       String currentMonthStr = "${now.year}-${now.month.toString().padLeft(2, '0')}";
       await calculateMonthlyStats(currentMonthStr);
       return "上個月 ($lastMonthStr) 沒有打工紀錄，無薪水可領！";
    }

    // 💡 發薪水啦！加進現有資金，並記錄該月已領取
    final prefs = await SharedPreferences.getInstance();
    _currentCash += lastMonthSalary;
    _claimedMonths.add(lastMonthStr);
    
    await prefs.setInt('currentCash', _currentCash);
    await prefs.setStringList('claimedMonths', _claimedMonths);
    
    // 將統計數字切回「當前月份」
    String currentMonthStr = "${now.year}-${now.month.toString().padLeft(2, '0')}";
    await calculateMonthlyStats(currentMonthStr);
    
    notifyListeners();
    return "🎉 成功領取 $lastMonthStr 薪水：\$ $lastMonthSalary 元！";
  }

  // 🧮 計算「今日伙食安全額度」
  int get dailySafeBudget {
    int remainingBudget = _currentCash - _monthlyTargetSavings;
    
    // 如果餘額已經被扣光，代表透支，今天只能吃土（0元）
    if (remainingBudget <= 0) return 0; 

    // 2. 計算本月還剩下幾天 (包含今天)
    final now = DateTime.now();
    final lastDay = DateTime(now.year, now.month + 1, 0).day; // 取得這個月最後一天
    int remainingDays = lastDay - now.day + 1;

    // 3. 安全額度 = 餘額 / 剩餘天數 (無條件捨去)
    return (remainingBudget / remainingDays).floor();
  }

  // 錢包自動連動：扣款與退款機制
  Future<void> adjustCurrentCash(int amountDifference) async {
    final prefs = await SharedPreferences.getInstance();
    _currentCash += amountDifference; // 傳入負數就是扣錢，正數就是退錢
    await prefs.setInt('currentCash', _currentCash);
    notifyListeners();
  }
}