import 'package:flutter/material.dart';

/// 底部抽屜：顯示與管理當日所有消費明細（支援確認刪除與修改）
class ExpenseListBottomSheet extends StatelessWidget {
  final String date;
  final List<Map<String, dynamic>> expenses;
  final Function(int index)? onDelete;
  final Function(int index, String newTitle, int newAmount)? onEdit; // 💡 預留修改回調

  const ExpenseListBottomSheet({
    super.key,
    required this.date,
    required this.expenses,
    this.onDelete,
    this.onEdit,
  });

  // 🗑️ 彈出確認刪除視窗
  void _showDeleteConfirmDialog(BuildContext context, int index, String title) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF2C2C2C),
        title: const Text("⚠️ 確認刪除", style: TextStyle(color: Colors.white)),
        content: Text("確定要刪除「$title」這筆消費嗎？", style: const TextStyle(color: Colors.grey)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx), // 取消
            child: const Text("取消", style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            onPressed: () {
              Navigator.pop(ctx); // 關閉確認窗
              Navigator.pop(context); // 關閉底部抽屜
              if (onDelete != null) onDelete!(index); // 執行刪除
            },
            child: const Text("確定刪除", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  // ✏️ 彈出修改消費視窗
  void _showEditDialog(BuildContext context, int index, String currentTitle, int currentAmount) {
    final titleController = TextEditingController(text: currentTitle);
    final amountController = TextEditingController(text: currentAmount.toString());

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF2C2C2C),
        title: const Text("✏️ 修改消費明細", style: TextStyle(color: Colors.white)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: titleController,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(labelText: "消費項目", labelStyle: TextStyle(color: Colors.grey)),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: amountController,
              keyboardType: TextInputType.number,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                labelText: "金額 (\$)",
                labelStyle: TextStyle(color: Colors.grey)
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
            style: ElevatedButton.styleFrom(backgroundColor: Colors.orangeAccent),
            onPressed: () {
              final newTitle = titleController.text.trim();
              final newAmount = int.tryParse(amountController.text.trim()) ?? currentAmount;
              if (newTitle.isNotEmpty) {
                Navigator.pop(ctx); // 關閉修改窗
                Navigator.pop(context); // 關閉底部抽屜
                if (onEdit != null) onEdit!(index, newTitle, newAmount); // 執行修改
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
              Text("📅 $date 消費明細", style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
              Text("共 \$ $totalAmount", style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.orangeAccent)),
            ],
          ),
          const SizedBox(height: 12),
          const Divider(color: Colors.white24),
          ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.45,
            ),
            child: expenses.isEmpty
                ? const Padding(
                    padding: EdgeInsets.all(32.0),
                    child: Center(child: Text("今日尚無消費紀錄 🍃", style: TextStyle(color: Colors.grey))),
                  )
                : ListView.separated(
                    shrinkWrap: true,
                    itemCount: expenses.length,
                    separatorBuilder: (context, index) => const Divider(color: Colors.white10, height: 1),
                    itemBuilder: (context, index) {
                      final item = expenses[index];
                      final title = item['title'] ?? '未命名消費';
                      final amount = (item['amount'] as num?)?.toInt() ?? 0;

                      return ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: const CircleAvatar(
                          backgroundColor: Color(0xFF2C2C2C),
                          child: Icon(Icons.shopping_bag_outlined, color: Colors.orangeAccent, size: 20),
                        ),
                        title: Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w500)),
                        subtitle: Text("\$ $amount", style: const TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
                        // 💡 點擊整列可以進行「修改」
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