import 'package:flutter/material.dart';
import '../../controllers/schedule_controller.dart';
import '../../models/schedule_model.dart';

/// 彈窗一：修改工時排班
class WorkShiftDialog extends StatefulWidget {
  final ScheduleController controller;
  final String dateStr;
  final ScheduleModel? existingSchedule;

  const WorkShiftDialog({super.key, required this.controller, required this.dateStr, this.existingSchedule});

  @override
  State<WorkShiftDialog> createState() => _WorkShiftDialogState();
}

class _WorkShiftDialogState extends State<WorkShiftDialog> {
  late final TextEditingController posController;
  late final TextEditingController startController;
  late final TextEditingController endController;

  @override
  void initState() {
    super.initState();
    posController = TextEditingController(text: widget.existingSchedule?.position ?? "");
    startController = TextEditingController(text: widget.existingSchedule?.startTime ?? "");
    endController = TextEditingController(text: widget.existingSchedule?.endTime ?? "");
  }

  @override
  void dispose() {
    posController.dispose();
    startController.dispose();
    endController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text("⏰ 修改工時排班 - ${widget.dateStr}"),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(controller: posController, decoration: const InputDecoration(labelText: "打工職位 (如：盛飯、夾菜)")),
          TextField(controller: startController, decoration: const InputDecoration(labelText: "上班時間 (HH:mm)")),
          TextField(controller: endController, decoration: const InputDecoration(labelText: "下班時間 (HH:mm)")),
        ],
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text("取消")),
        ElevatedButton(
          onPressed: () async {
            await widget.controller.updateWorkShift(
              date: widget.dateStr,
              position: posController.text.trim(),
              startTime: startController.text.trim(),
              endTime: endController.text.trim(),
            );
            if (context.mounted) Navigator.pop(context);
          },
          child: const Text("儲存工時"),
        ),
      ],
    );
  }
}

/// 彈窗二：新增消費明細
class ExpenseDialog extends StatefulWidget {
  final ScheduleController controller;
  final String dateStr;
  final Map<String, dynamic>? existingExpense;
  final int? expenseIndex;
  final bool isEditingIncome;

  const ExpenseDialog({
    super.key, 
    required this.controller, 
    required this.dateStr, 
    this.existingExpense, 
    this.expenseIndex,
    this.isEditingIncome = false,
  });

  @override
  State<ExpenseDialog> createState() => _ExpenseDialogState();
}

class _ExpenseDialogState extends State<ExpenseDialog> {
  late final TextEditingController itemController;
  late final TextEditingController amountController;
  late bool _isIncome; // 用來記錄現在使用者選的是收入還是支出
  final FocusNode _amountFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    itemController = TextEditingController(text: widget.existingExpense?['title'] as String? ?? '');
    amountController = TextEditingController(text: widget.existingExpense?['amount']?.toString() ?? '');
    _isIncome = widget.isEditingIncome;
  }

  @override
  void dispose() {
    itemController.dispose();
    amountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    bool isEditing = widget.existingExpense != null;
    return AlertDialog(
      scrollable: true,
      title: Text(
        isEditing 
          ? (_isIncome ? "✏️ 修改收入明細" : "✏️ 修改支出明細")
          : "📝 新增帳務明細 - ${widget.dateStr}",
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (!isEditing)
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ChoiceChip(
                  label: const Text("支出 💸"),
                  selected: !_isIncome,
                  onSelected: (selected) {
                    setState(() => _isIncome = false);
                  },
                  selectedColor: Colors.redAccent.withValues(alpha: 0.2),
                ),
                const SizedBox(width: 16),
                ChoiceChip(
                  label: const Text("收入 🤑"),
                  selected: _isIncome,
                  onSelected: (selected) {
                    setState(() => _isIncome = true);
                  },
                  selectedColor: Colors.greenAccent.withValues(alpha: 0.2),
                ),
              ],
            ),
          if (!isEditing) const SizedBox(height: 16),

          TextField(
            controller: itemController, 
            textInputAction: TextInputAction.next,
            onSubmitted: (_){
              FocusScope.of(context).requestFocus(_amountFocusNode);
            },
            decoration: InputDecoration(
              // 💡 提示文字會跟著切換
              labelText: _isIncome ? "收入來源 (如：賣二手書、零用錢)" : "消費項目 (如：午餐、買飲料)"
            )
          ),
          TextField(
            controller: amountController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(labelText: "金額", prefixText: "\$ "),
          ),
        ],
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text("取消")),
        ElevatedButton(
          onPressed: () async {
              final amount = int.tryParse(amountController.text.trim()) ?? 0;
              final title = itemController.text.trim();

              if (widget.expenseIndex != null) {
                // 修改模式
                await widget.controller.editTransaction(
                  date: widget.dateStr,
                  index: widget.expenseIndex!,
                  newTitle: title,
                  newAmount: amount,
                  isIncome: _isIncome,
                );
              } else {
                // 新增模式
                await widget.controller.addTransaction(
                  date: widget.dateStr,
                  itemTitle: title,
                  itemAmount: amount,
                  isIncome: _isIncome,
                );
              }
            if (context.mounted) Navigator.pop(context);
          },
            child: Text(widget.existingExpense == null ? "確認新增" : "儲存變更"),
        ),
      ],
    );
  }
}

/// 彈窗三：手動修改時薪
class WageSettingDialog extends StatefulWidget {
  final ScheduleController controller;
  final String currentDateStr;

  const WageSettingDialog({super.key, required this.controller, required this.currentDateStr});

  @override
  State<WageSettingDialog> createState() => _WageSettingDialogState();
}

class _WageSettingDialogState extends State<WageSettingDialog> {
  late final TextEditingController wageController;

  @override
  void initState() {
    super.initState();
    wageController = TextEditingController(text: widget.controller.hourlyWage.toString());
  }

  @override
  void dispose() {
    wageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text("💰 設定打工時薪"),
      content: TextField(
        controller: wageController,
        keyboardType: TextInputType.number,
        decoration: const InputDecoration(labelText: "時薪金額 (元/小時)", prefixText: "\$ "),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text("取消")),
        ElevatedButton(
          onPressed: () async {
            int newWage = int.tryParse(wageController.text.trim()) ?? 180;
            await widget.controller.updateHourlyWage(newWage, widget.currentDateStr);
            if (context.mounted) Navigator.pop(context);
          },
          child: const Text("儲存時薪"),
        ),
      ],
    );
  }
}

/// 彈窗四：顯示 AI 班表導入成功的明細結果
class ImportResultDialog extends StatelessWidget {
  final List<Map<String, dynamic>> results;

  const ImportResultDialog({super.key, required this.results});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text("🎉 成功寫入"),
      content: SizedBox(
        width: double.maxFinite,
        child: ListView.builder(
          shrinkWrap: true,
          itemCount: results.length,
          itemBuilder: (context, index) {
            final item = results[index];
            return ListTile(
              leading: Icon(Icons.check_circle, color: Theme.of(context).colorScheme.primary),
              title: Text("📅 ${item['date']} (${item['position']})"),
              subtitle: Text("⏰ 工時: ${item['start_time']} ~ ${item['end_time']}"),
            );
          },
        ),
      ),
      actions: [
        ElevatedButton(
          onPressed: () => Navigator.pop(context),
          child: const Text("好的"),
        ),
      ],
    );
  }
}
