import 'package:flutter/material.dart';
import 'pages/drawing_page.dart';

// 应用程序入口点
void main() {
  runApp(const MyApp());
}

// 应用程序根组件
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Drawing Board',      // 应用标题
      theme: ThemeData(           // 应用主题设置
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,       // 启用 Material 3
      ),
      home: const DrawingPage(),  // 设置首页为绘图页面
    );
  }
}
