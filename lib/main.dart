import 'package:flutter/material.dart';
import 'dashboard_screen.dart';
import 'volume_bubble_overlay.dart';

// 1. ENTRY POINT CHÍNH CỦA ỨNG DỤNG (CHẠY TRANG CÀI ĐẶT)
void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}

// 2. ENTRY POINT DÀNH RIÊNG CHO BONG BÓNG TRÔI NỔI CHẠY NỀN ĐỘC LẬP
@pragma("vm:entry-point")
void overlayMain() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(
    const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: VolumeBubbleOverlay(), // Gọi giao diện bong bóng từ file riêng
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Volume Bubble',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF0F172A), // Màu nền mượt
        useMaterial3: true,
      ),
      home: const DashboardScreen(), // Gọi trang cài đặt chính từ file riêng
    );
  }
}
