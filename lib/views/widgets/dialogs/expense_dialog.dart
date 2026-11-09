import 'package:flutter/material.dart';
import '../../../controllers/schedule_controller.dart';

/// 彈窗：新增與修改收支記帳明細
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
  late bool _isIncome;
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
    _amountFocusNode.dispose();
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
              labelText: _isIncome ? "收入來源 (如：賣二手書、零用錢)" : "消費項目 (如：午餐、買飲料)",
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: amountController,
            focusNode: _amountFocusNode,
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
              await widget.controller.editTransaction(
                date: widget.dateStr,
                index: widget.expenseIndex!,
                newTitle: title,
                newAmount: amount,
                isIncome: _isIncome,
              );
            } else {
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

