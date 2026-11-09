import 'package:flutter/material.dart';
import '../../../controllers/schedule_controller.dart';

/// 彈窗：新增與修改工時排班
class WorkShiftDialog extends StatefulWidget {
  final ScheduleController controller;
  final String dateStr;
  final Map<String, dynamic>? existingShift; // 💡 接收單一班表的 Map
  final int? shiftIndex;                     // 💡 接收班表在陣列中的索引

  const WorkShiftDialog({
    super.key, 
    required this.controller, 
    required this.dateStr, 
    this.existingShift,
    this.shiftIndex,
  });

  @override
  State<WorkShiftDialog> createState() => _WorkShiftDialogState();
}

class _WorkShiftDialogState extends State<WorkShiftDialog> {
  final TextEditingController posController = TextEditingController();
  final TextEditingController startController = TextEditingController();
  final TextEditingController endController = TextEditingController();

  final FocusNode startFocusNode = FocusNode();
  final FocusNode endFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    if (widget.existingShift != null) {
      posController.text = widget.existingShift!['position']?.toString() ?? "";
      startController.text = widget.existingShift!['start_time']?.toString() ?? "";
      endController.text = widget.existingShift!['end_time']?.toString() ?? "";
    }
  }

  @override
  void dispose() {
    posController.dispose();
    startController.dispose();
    endController.dispose();
    startFocusNode.dispose();
    endFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    bool isEditing = widget.existingShift != null;
    return AlertDialog(
      scrollable: true,
      title: Text("⏰ ${isEditing ? '修改' : '新增'}工時排班 - ${widget.dateStr}"),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: posController, 
            textInputAction: TextInputAction.next,
            onSubmitted: (_) => FocusScope.of(context).requestFocus(startFocusNode),
            decoration: const InputDecoration(labelText: "打工職位 (如：盛飯、夾菜)"),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: startController, 
            focusNode: startFocusNode,
            textInputAction: TextInputAction.next,
            onSubmitted: (_) => FocusScope.of(context).requestFocus(endFocusNode),
            decoration: const InputDecoration(labelText: "上班時間 (HH:mm)"),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: endController, 
            focusNode: endFocusNode,
            decoration: const InputDecoration(labelText: "下班時間 (HH:mm)"),
          ),
        ],
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text("取消")),
        ElevatedButton(
          onPressed: () async {
            if (isEditing) {
              await widget.controller.editWorkShift(
                date: widget.dateStr,
                index: widget.shiftIndex!,
                newPosition: posController.text.trim(),
                newStart: startController.text.trim(),
                newEnd: endController.text.trim(),
              );
            } else {
              await widget.controller.addWorkShift(
                date: widget.dateStr,
                position: posController.text.trim(),
                startTime: startController.text.trim(),
                endTime: endController.text.trim(),
              );
            }
            if (context.mounted) Navigator.pop(context);
          },
          child: Text(isEditing ? "儲存修改" : "確認新增"),
        ),
      ],
    );
  }
}

