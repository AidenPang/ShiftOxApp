import 'package:flutter/material.dart';

/// 底部抽屜：顯示與管理當日所有收支明細（支援確認刪除與修改，自動適配支出與收入情境）
class ExpenseListBottomSheet extends StatelessWidget {
  final String date;
  final List<Map<String, dynamic>> expenses;
  final bool isIncome;
  final Function(int index)? onDelete;
  final Function(int index, String newTitle, int newAmount)? onEdit;

  const ExpenseListBottomSheet({
    super.key,
    required this.date,
    required this.expenses,
    this.isIncome = false,
    this.onDelete,
    this.onEdit,
  });

  // 🗑️ 彈出確認刪除視窗
  void _showDeleteConfirmDialog(BuildContext context, int index, String title) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        scrollable: true,
        backgroundColor: const Color(0xFF2C2C2C),
        title: const Text("⚠️ 確認刪除", style: TextStyle(color: Colors.white)),
        content: Text("確定要刪除「$title」這筆${isIncome ? "收入" : "消費"}嗎？", style: const TextStyle(color: Colors.grey)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("取消", style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            onPressed: () {
              Navigator.pop(ctx);
              Navigator.pop(context);
              if (onDelete != null) onDelete!(index);
            },
            child: const Text("確定刪除", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  // ✏️ 彈出修改視窗
  void _showEditDialog(BuildContext context, int index, String currentTitle, int currentAmount) {
    final titleController = TextEditingController(text: currentTitle);
    final amountController = TextEditingController(text: currentAmount.toString());

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        scrollable: true,
        backgroundColor: const Color(0xFF2C2C2C),
        title: Text(isIncome ? "✏️ 修改收入明細" : "✏️ 修改消費明細", style: const TextStyle(color: Colors.white)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: titleController,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                labelText: isIncome ? "收入來源" : "消費項目", 
                labelStyle: const TextStyle(color: Colors.grey),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: amountController,
              keyboardType: TextInputType.number,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                labelText: "金額 (\$)",
                labelStyle: TextStyle(color: Colors.grey),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("取消", style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: isIncome ? Colors.green : Colors.orangeAccent,
            ),
            onPressed: () {
              final newTitle = titleController.text.trim();
              final newAmount = int.tryParse(amountController.text.trim()) ?? currentAmount;
              if (newTitle.isNotEmpty) {
                Navigator.pop(ctx);
                Navigator.pop(context);
                if (onEdit != null) onEdit!(index, newTitle, newAmount);
              }
            },
            child: const Text("儲存修改", style: TextStyle(color: Colors.black)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    int totalAmount = expenses.fold(0, (sum, item) => sum + ((item['amount'] as num?)?.toInt() ?? 0));
    final themeColor = isIncome ? Colors.greenAccent : Colors.orangeAccent;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: const BoxDecoration(
        color: Color(0xFF1E1E1E),
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: Colors.grey[600],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                isIncome ? "📅 $date 額外進帳" : "📅 $date 消費明細",
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
              ),
              Text(
                "${isIncome ? "+ " : ""}共 \$ $totalAmount",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: themeColor),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Divider(color: Colors.white24),
          ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.45,
            ),
            child: expenses.isEmpty
                ? Padding(
                    padding: const EdgeInsets.all(32.0),
                    child: Center(
                      child: Text(
                        isIncome ? "今日尚無額外進帳 🍃" : "今日尚無消費紀錄 🍃",
                        style: const TextStyle(color: Colors.grey),
                      ),
                    ),
                  )
                : ListView.separated(
                    shrinkWrap: true,
                    itemCount: expenses.length,
                    separatorBuilder: (context, index) => const Divider(color: Colors.white10, height: 1),
                    itemBuilder: (context, index) {
                      final item = expenses[index];
                      final title = item['title'] ?? (isIncome ? '未命名進帳' : '未命名消費');
                      final amount = (item['amount'] as num?)?.toInt() ?? 0;

                      return ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: CircleAvatar(
                          backgroundColor: const Color(0xFF2C2C2C),
                          child: Icon(
                            isIncome ? Icons.savings_outlined : Icons.shopping_bag_outlined,
                            color: themeColor,
                            size: 20,
                          ),
                        ),
                        title: Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w500)),
                        subtitle: Text(
                          "${isIncome ? "+ " : ""}\$ $amount",
                          style: TextStyle(
                            color: isIncome ? Colors.greenAccent : Colors.redAccent,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        onTap: () => _showEditDialog(context, index, title, amount),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete_outline, color: Colors.grey, size: 20),
                          onPressed: () => _showDeleteConfirmDialog(context, index, title),
                        ),
                      );
                    },
                  ),
          ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }
}
