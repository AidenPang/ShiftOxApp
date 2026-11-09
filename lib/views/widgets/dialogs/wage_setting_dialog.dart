import 'package:flutter/material.dart';
import '../../../controllers/schedule_controller.dart';

/// 彈窗：手動修改時薪設定
class WageSettingDialog extends StatefulWidget {
  final ScheduleController controller;
  final String currentDateStr;

  const WageSettingDialog({
    super.key, 
    required this.controller, 
    required this.currentDateStr,
  });

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
      scrollable: true,
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
            int newWage = int.tryParse(wageController.text.trim()) ?? widget.controller.hourlyWage;
            await widget.controller.updateHourlyWage(newWage, widget.currentDateStr);
            if (context.mounted) Navigator.pop(context);
          },
          child: const Text("儲存時薪"),
        ),
      ],
    );
  }
}

