import 'package:flutter/material.dart';

class MonthlyStatsBar extends StatelessWidget {
  final int month;
  final int totalSalary;
  final int totalExpense;

  const MonthlyStatsBar({
    super.key,
    required this.month,
    required this.totalSalary,
    required this.totalExpense,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 20),
      color: Theme.of(context).colorScheme.primary.withAlpha(25), // 💡 使用 withAlpha 替代 withOpacity
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            "📈 $month月預估總薪水：\$ $totalSalary 元",
            style: TextStyle(fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.primary, fontSize: 13),
          ),
          Text(
            "📉 本月總花費：\$ $totalExpense 元",
            style: TextStyle(fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.error, fontSize: 13),
          ),
        ],
      ),
    );
  }
}