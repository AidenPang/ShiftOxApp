import 'package:flutter/material.dart';
import '../../controllers/schedule_controller.dart';
import 'expense_list_view.dart';

/// 今日額外進帳摘要卡片
class IncomeSummaryCard extends StatelessWidget {
  final String dateString;
  final int incomeAmount;
  final List<Map<String, dynamic>> incomeList;
  final ScheduleController controller;

  const IncomeSummaryCard({
    super.key,
    required this.dateString,
    required this.incomeAmount,
    required this.incomeList,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    if (incomeList.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(top: 16.0),
      child: GestureDetector(
        onTap: () {
          showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            backgroundColor: Colors.transparent,
            builder: (context) => ExpenseListBottomSheet(
              date: dateString,
              expenses: incomeList,
              isIncome: true,
              onDelete: (index) async => await controller.deleteTransaction(date: dateString, index: index, isIncome: true),
              onEdit: (index, newTitle, newAmount) async => await controller.editTransaction(
                date: dateString, 
                index: index, 
                newTitle: newTitle, 
                newAmount: newAmount, 
                isIncome: true,
              ),
            ),
          );
        },
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.green.withAlpha(25),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.green.withAlpha(70)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text("🤑 今日額外進帳", style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 14)),
                  Text("+\$ $incomeAmount", style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 16)),
                ],
              ),
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 8.0),
                child: Divider(color: Colors.green, height: 1, thickness: 0.3),
              ),
              ...incomeList.map((item) => Padding(
                padding: const EdgeInsets.only(bottom: 4.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text("• ${item['title']}", style: const TextStyle(fontSize: 14, color: Colors.white70)),
                    Text("+\$ ${item['amount']}", style: const TextStyle(fontSize: 14, color: Colors.white70)),
                  ],
                ),
              )),
              const SizedBox(height: 4),
              const Align(
                alignment: Alignment.centerRight,
                child: Text("點擊修改 ❯", style: TextStyle(color: Colors.grey, fontSize: 12)),
              )
            ],
          ),
        ),
      ),
    );
  }
}

