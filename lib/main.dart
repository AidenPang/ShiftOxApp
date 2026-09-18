import 'package:flutter/material.dart';
import 'views/main_page.dart'; // 💡 引入剛剛寫好的 View 畫面

void main() {
  // 確保 Flutter 積木引擎與原生元件（如 SQLite 底層）初始化完畢
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const ShiftOxApp());
}

class ShiftOxApp extends StatelessWidget {
  const ShiftOxApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '牛馬日誌',
      debugShowCheckedModeBanner: false,
      // 🎨 全新設計的深色主題，提升質感與夜間使用體驗
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        primaryColor: Colors.brown[300],
        scaffoldBackgroundColor: const Color(0xFF1A1A1A), // 深炭色背景
        appBarTheme: AppBarTheme(
          backgroundColor: const Color(0xFF2C2C2C), // 層次分明的 AppBar 顏色
          elevation: 0,
          titleTextStyle: TextStyle(
            color: Colors.cyan[100], // 標題改為柔和的青色
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        colorScheme: ColorScheme.fromSeed(
            seedColor: Colors.deepPurple, brightness: Brightness.dark),
      ),
      // 🛠️ 免去一切登錄地獄，開門見山直接進入日曆首頁！
      home: const MainPage(), 
    );
  }
}