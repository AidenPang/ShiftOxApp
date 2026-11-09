import 'package:flutter/material.dart';
import '../controllers/schedule_controller.dart';

class FinancePage extends StatelessWidget {
  final ScheduleController controller; // 💡 接收共用大腦

  const FinancePage({super.key, required this.controller});

  // ✏️ 修改存錢目標的彈窗
  void _showEditTargetDialog(BuildContext context,{required bool isTarget}) {
    final textController = TextEditingController(
      text: isTarget ? controller.monthlyTargetSavings.toString() : controller.currentCash.toString()
    );
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        scrollable: true,
        backgroundColor: const Color(0xFF2C2C2C),
        title: Text(isTarget ? "🎯 設定學費預留目標" : "💼 校正現有資金", style: const TextStyle(color: Colors.white)),
        content: TextField(
          controller: textController,
          keyboardType: TextInputType.number,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            labelText: isTarget ? "每月預留金額 (\$)" : "手上現金總額 (\$)", 
            labelStyle: const TextStyle(color: Colors.grey)
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("取消", style: TextStyle(color: Colors.grey))),
          ElevatedButton(
            onPressed: () {
              final newValue = int.tryParse(textController.text.trim()) ?? 0;
              if (isTarget) {
                controller.updateTargetSavings(newValue == 0 ? 15000 : newValue);
              } else {
                controller.updateCurrentCash(newValue);
              }
              Navigator.pop(ctx);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.orangeAccent),
            child: const Text("儲存", style: TextStyle(color: Colors.black)),
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // 💡 ListenableBuilder 讓這裡跟日曆一樣，只要金額變動就會瞬間刷新！
    return ListenableBuilder(
      listenable: controller,
      builder: (context, child) {
        int safeBudget = controller.dailySafeBudget;
        int projectedTotalMoney = controller.currentCash;
        int remainingBudget = projectedTotalMoney - controller.monthlyTargetSavings;
        bool isOverspent = remainingBudget <= 0; // 是否吃土

        return Scaffold(
          backgroundColor: const Color(0xFF121212),
          appBar: AppBar(
            title: const Text('💰 生存雷達', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            backgroundColor: const Color(0xFF1E1E1E),
            elevation: 0,
            centerTitle: true,
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 現有資金區塊
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient:  const LinearGradient(
                      colors: [Color(0xFF2E7D32), Color(0xFF1B5E20)], // 鈔票綠漸層
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    children:[                                   
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,                   
                        children: [
                          const Text("💵 現有可動用資金", style: TextStyle(color: Colors.white70, fontSize: 16)),
                          IconButton(
                            icon: const Icon(Icons.edit, color: Colors.white70, size: 20),
                            onPressed: () => _showEditTargetDialog(context, isTarget: false),
                            constraints: const BoxConstraints(),
                            padding: EdgeInsets.zero,
                          )
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text("\$ ${controller.currentCash}", style: const TextStyle(color: Colors.white,fontSize: 40, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 16),
                      
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: const Color(0xFF1B5E20),
                          minimumSize: const Size.fromHeight(45),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        onPressed: () async {
                          String message = await controller.claimPreviousMonthSalary();
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
                          }
                        },
                        icon: const Icon(Icons.payments_outlined),
                        label: const Text("發薪日：結算上個月薪資", style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 20),
                
                // 2. 本月可用生活費 & 今日配速
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF2C2C2C),
                  borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.orangeAccent.withAlpha(50)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text("🛡️ 本月學費與存錢預留", style: TextStyle(color: Colors.grey, fontSize: 14)),
                          const SizedBox(height: 8),
                          Text("\$ ${controller.monthlyTargetSavings}", style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
                        ],
                      ),
                      IconButton(
                        icon: const Icon(Icons.edit, color: Colors.orangeAccent),
                        onPressed: () => _showEditTargetDialog(context, isTarget: true),
                      )
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                //  2. 本月可用生活費 & 今日配速
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isOverspent ? const Color(0xFF4A1414) : const Color(0xFF1A3822),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: isOverspent ? Colors.redAccent : Colors.greenAccent),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(isOverspent ? "🚨 警告：本月已透支！" : "🚦 今日伙食安全額度", 
                           style: TextStyle(color: isOverspent ? Colors.redAccent : Colors.greenAccent, fontSize: 14, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 12),
                      Text("\$ $safeBudget", style: TextStyle(color: isOverspent ? Colors.redAccent : Colors.greenAccent, fontSize: 40, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 12),
                      // 💡 說明公式：現有資金 - 目標 - 已花費 = 剩餘可支配
                      Text("手頭現金 (\$ $projectedTotalMoney)扣除目標與開銷後", style: const TextStyle(color: Colors.grey, fontSize: 12)),
                      Text("本月剩餘可支配現金：\$ $remainingBudget", style: TextStyle(color: isOverspent ? Colors.redAccent : Colors.white70, fontSize: 14, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
