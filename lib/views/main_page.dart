import 'package:flutter/material.dart';
import 'calendar_page.dart';
import 'finance_page.dart';
import '../controllers/schedule_controller.dart'; // 💡 引入 Controller

class MainPage extends StatefulWidget {
  const MainPage({super.key});

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  int _currentIndex = 0;
  // 💡 關鍵：建立全域共用的 Controller！
  final ScheduleController _controller = ScheduleController();

  @override
  void initState() {
    super.initState();
    _controller.loadTargetSavings(); // 啟動時讀取存錢目標
  }

  @override
  Widget build(BuildContext context) {
    // 💡 將共用的 controller 傳入兩個頁面
    final List<Widget> pages = [
      CalendarPage(controller: _controller), 
      FinancePage(controller: _controller),  
    ];

    return Scaffold(
      // 使用 IndexedStack 確保切換頁面時，原本的狀態（如選中的日期）不會被重置
      body: IndexedStack(
        index: _currentIndex,
        children: pages,
      ),
      // 這是全域的底部導覽列
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        backgroundColor: const Color(0xFF1E1E1E),
        selectedItemColor: Colors.orangeAccent,
        unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.calendar_month), 
            label: '排班日誌'
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.account_balance_wallet), 
            label: '生存雷達'
          ),
        ],
      ),
    );
  }
}