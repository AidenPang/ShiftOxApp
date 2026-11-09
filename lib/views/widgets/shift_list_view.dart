import 'package:flutter/material.dart';
import '../../controllers/schedule_controller.dart';
import 'dialogs.dart';

/// 日曆選定日期的排班列表卡片清單
class ShiftListView extends StatelessWidget {
  final List<Map<String, dynamic>> shiftList;
  final String dateString;
  final ScheduleController controller;

  const ShiftListView({
    super.key,
    required this.shiftList,
    required this.dateString,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    if (shiftList.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 8.0),
        child: Text("🏃‍♂️ 今天放假！休息吧牛馬", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: shiftList.asMap().entries.map((entry) {
        int index = entry.key;
        var shift = entry.value;
        return GestureDetector(
          onTap: () {
            showDialog(
              context: context,
              builder: (context) => WorkShiftDialog(
                controller: controller,
                dateStr: dateString,
                existingShift: shift,
                shiftIndex: index,
              ),
            );
          },
          child: Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("🏃‍♂️ 崗位：${shift['position']}", style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    Text("⏰ ${shift['start_time']} ~ ${shift['end_time']}", style: TextStyle(fontSize: 14, color: Theme.of(context).colorScheme.onSurfaceVariant)),
                  ],
                ),
                Row(
                  children: [
                    const Icon(Icons.edit, size: 18, color: Colors.grey),
                    const SizedBox(width: 12),
                    GestureDetector(
                      onTap: () async {
                        await controller.deleteWorkShift(date: dateString, index: index);
                      },
                      child: const Icon(Icons.delete_outline, size: 20, color: Colors.redAccent),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}

