import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:image_picker/image_picker.dart';
import '../controllers/schedule_controller.dart';
import '../models/schedule_model.dart';
import 'widgets/dialogs.dart';
import 'widgets/finance_card.dart';
import 'widgets/monthly_stats_bar.dart';
import 'widgets/expense_list_view.dart';

class CalendarPage extends StatefulWidget {
  final ScheduleController controller; // 💡 接收外面傳進來的 Controller
  const CalendarPage({super.key, required this.controller});

  @override
  State<CalendarPage> createState() => _CalendarPageState();
}

class _CalendarPageState extends State<CalendarPage> {
  late final ScheduleController _controller; // 💡 用 late 宣告，底下都不用改名！
  DateTime _selectedDay = DateTime.now();
  DateTime _focusedDay = DateTime.now();
  late Future<void> _loadDataFuture;
  CalendarFormat _calendarFormat = CalendarFormat.week;

  @override
  void initState() {
    super.initState();
    _controller = widget.controller; // 💡 將外部傳來的接進來
    String todayStr = _formatDate(_selectedDay);
    _loadDataFuture = Future.wait([
      _controller.initSettingsAndStats(todayStr.substring(0, 7)),
      _controller.loadScheduleByDate(todayStr), 
    ]);
  }

  String _formatDate(DateTime date) {
    return "${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";
  }

  Future<void> _loadCurrentDayData() async {
    String dateStr = _formatDate(_selectedDay);
    await _controller.loadScheduleByDate(dateStr);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: _loadDataFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        return ListenableBuilder(
          listenable: _controller,
          builder: (context, child) {
            String dateString = _formatDate(_selectedDay);
            ScheduleModel? schedule = _controller.currentSchedule;

            String position = schedule?.position.isNotEmpty == true ? schedule!.position : "今天放假！休息吧牛馬";
            String startTime = schedule?.startTime.isNotEmpty == true ? schedule!.startTime : "--:--";
            String endTime = schedule?.endTime.isNotEmpty == true ? schedule!.endTime : "--:--";
            int expenseAmount = schedule?.expenseAmount ?? 0;
            List<Map<String, dynamic>> expenseList = schedule?.getExpenseList() ?? [];

            double todayHours = _controller.calculateHours(startTime, endTime);
            int todaySalary = (todayHours * _controller.hourlyWage).round();

            return Scaffold(
              appBar: AppBar(
                title: const Text('🌾 牛馬日誌 (ShiftOx)', style: TextStyle(fontWeight: FontWeight.bold)),
                centerTitle: true,
                actions: [
                  IconButton(
                    icon: const Icon(Icons.monetization_on_outlined),
                    tooltip: "設定時薪",
                    onPressed: () => showDialog(
                      context: context,
                      builder: (context) => WageSettingDialog(controller: _controller, currentDateStr: dateString),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.add_photo_alternate_rounded),
                    tooltip: "從相簿導入班表",
                    onPressed: () async {
                      final results = await _controller.scanAndImportSchedule(context, ImageSource.gallery, dateString);
                      if (results.isNotEmpty && context.mounted) {
                        showDialog(
                          context: context,
                          builder: (context) => ImportResultDialog(results: results),
                        );
                      }
                    },
                  ),
                  IconButton(
                    icon: const Icon(Icons.camera_alt_rounded),
                    tooltip: "拍照識別班表",
                    onPressed: () async {
                      final results = await _controller.scanAndImportSchedule(context, ImageSource.gallery, dateString);
                      if (results.isNotEmpty && context.mounted) {
                        showDialog(
                          context: context,
                          builder: (context) => ImportResultDialog(results: results),
                        );
                      }
                    },
                  ),
                ],
              ),
              body: Stack(
                children: [
                  Column(
                    children: [
                      TableCalendar(
                        firstDay: DateTime.utc(2026, 1, 1),
                        lastDay: DateTime.utc(2030, 12, 31),
                        focusedDay: _focusedDay,
                        selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
                        // 💡 1. 綁定日曆顯示格式
                        calendarFormat: _calendarFormat,                     
                        // 💡 2. 客製化切換按鈕的文字 (右上角的按鈕)
                        availableCalendarFormats: const {
                          CalendarFormat.month: '收起單週', // 處於月份狀態時，按鈕顯示「收起單週」
                          CalendarFormat.week: '展開全部',  // 處於單週狀態時，按鈕顯示「展開全部」
                        },
                        // 💡 3. 當使用者點擊右上角切換按鈕時，觸發狀態更新
                        onFormatChanged: (format) {
                          if (_calendarFormat != format) {
                            setState(() {
                              _calendarFormat = format;
                            });
                          }
                        },
                        onPageChanged: (focusedDay) {
                          _focusedDay = focusedDay;
                          String yearMonth = "${focusedDay.year}-${focusedDay.month.toString().padLeft(2, '0')}";
                          _controller.calculateMonthlyStats(yearMonth);
                        },
                        onDaySelected: (selectedDay, focusedDay) {
                          setState(() {
                            _selectedDay = selectedDay;
                            _focusedDay = focusedDay;
                          });
                          _loadCurrentDayData(); 
                        },
                        calendarStyle: CalendarStyle(
                          todayDecoration: BoxDecoration(color: Theme.of(context).primaryColorLight, shape: BoxShape.circle),
                          selectedDecoration: BoxDecoration(color: Theme.of(context).primaryColor, shape: BoxShape.circle),
                        ),
                      ),
                      const Divider(height: 1),
                      MonthlyStatsBar(
                        month: _selectedDay.month,
                        totalSalary: _controller.monthlyTotalSalary,
                        totalExpense: _controller.monthlyTotalExpense,
                      ),
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.fromLTRB(20.0, 16.0, 20.0, 12.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text("📅 日期：$dateString", style: TextStyle(fontSize: 14, color: Theme.of(context).colorScheme.onSurfaceVariant)),
                              const SizedBox(height: 4),
                              Text("🏃‍♂️ 今日崗位：$position", style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                              const SizedBox(height: 4),
                              Text("⏰ 工時時段：$startTime ~ $endTime", style: TextStyle(fontSize: 14, color: Theme.of(context).colorScheme.onSurfaceVariant)),
                              const SizedBox(height: 12),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  FinanceCard(
                                    title: "💰 今日草料 (預估薪資)",
                                    content: "$todaySalary 元",
                                    color: Theme.of(context).colorScheme.primary,
                                    subText: "時薪 \$ ${_controller.hourlyWage} 元",
                                  ),
                                  GestureDetector(
                                    onTap: () {
                                      final expenses = _controller.currentSchedule?.getExpenseList() ?? [];
                                      showModalBottomSheet(
                                        context: context,
                                        isScrollControlled: true,
                                        backgroundColor: Colors.transparent,
                                        builder: (context) => ExpenseListBottomSheet(
                                          date: dateString,
                                          expenses: expenses,
                                          onDelete: (index) async {
                                            await _controller.deleteSingleExpense(date: dateString, index: index);
                                          },
                                          onEdit: (index, newTitle, newAmount) async {
                                            await _controller.editSingleExpense(
                                              date: dateString,
                                              index: index,
                                              newTitle: newTitle,
                                              newAmount: newAmount,
                                            );
                                          },
                                        ),
                                      );
                                    },
                                    child: FinanceCard(
                                      title: "💸 今日銀兩 (消費加總)",
                                      content: "$expenseAmount 元",
                                      color: Theme.of(context).colorScheme.error,
                                      subText: "共 ${expenseList.length} 筆明細 ❯",
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (_controller.isLoading)
                    Container(
                      color: Colors.black.withAlpha(77),
                      child: Center(
                        child: Card(
                          child: Padding(
                            padding: const EdgeInsets.all(20),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: const [
                                CircularProgressIndicator(),
                                SizedBox(height: 15),
                                Text("AI 總管正在分析班表...", style: TextStyle(fontWeight: FontWeight.bold)),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              bottomNavigationBar: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                  child: Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFD0BCFF),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          onPressed: () => showDialog(
                            context: context,
                            builder: (context) => WorkShiftDialog(controller: _controller, dateStr: dateString, existingSchedule: schedule),
                          ),
                          icon: const Icon(Icons.access_time, color: Colors.black),
                          label: const Text("修改工時", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFFFB4A9),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          onPressed: () => showDialog(
                            context: context,
                            builder: (context) => ExpenseDialog(controller: _controller, dateStr: dateString),
                          ),
                          icon: const Icon(Icons.add_shopping_cart, color: Colors.black),
                          label: const Text("新增記帳", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}