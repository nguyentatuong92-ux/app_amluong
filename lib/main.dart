import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_overlay_window/flutter_overlay_window.dart';
import 'package:app_links/app_links.dart';
import 'dart:developer';
import 'package:flutter/services.dart';

// Import các màn hình của bạn
import 'volume_bubble_overlay.dart';
import 'dashboard_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Thiết lập MethodChannel để lắng nghe từ Quick Settings Tile
  const platform = MethodChannel('com.example.am_luong/tile');
  platform.setMethodCallHandler((call) async {
    if (call.method == "toggleBubble") {
      final isActive = await FlutterOverlayWindow.isActive();
      if (isActive) {
        await FlutterOverlayWindow.closeOverlay();
      } else {
        if (await FlutterOverlayWindow.isPermissionGranted()) {
          await FlutterOverlayWindow.showOverlay(
            enableDrag: true,
            flag: OverlayFlag.defaultFlag,
            alignment: OverlayAlignment.centerRight,
            height: 480,
            width: 200,
          );
        }
      }
      // Sau khi toggle, yêu cầu native cập nhật lại UI nút gạt cho chuẩn
      platform.invokeMethod("updateTileUI");
      return true;
    } else if (call.method == "checkStatus") {
      return await FlutterOverlayWindow.isActive();
    }
    return null;
  });

  // Xử lý deep link lúc mở app lần đầu
  try {
    final appLinks = AppLinks();
    // [ĐÃ SỬA LỖI TẠI ĐÂY] Đổi thành getInitialLink() cho phiên bản mới
    final uri = await appLinks.getInitialLink();
    if (uri != null) {
      log('App được mở từ deep link (lần đầu): $uri');
    }
  } catch (e) {
    log('Lỗi đọc deep link: $e');
  }

  runApp(const MyApp());
}

// BẮT BUỘC PHẢI CÓ ĐỂ CHẠY BONG BÓNG
@pragma("vm:entry-point")
void overlayMain() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(
    const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: VolumeBubbleOverlay(),
    ),
  );
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  StreamSubscription<Uri>? _linkSubscription;

  @override
  void initState() {
    super.initState();
    _initDeepLinkListener();
  }

  void _initDeepLinkListener() {
    final appLinks = AppLinks();
    _linkSubscription = appLinks.uriLinkStream.listen(
      (uri) {
        log('Nhận được deep link mới lúc app đang chạy: $uri');
        // Khi nhận link, Dashboard là màn hình chính nên nó sẽ tự hiện lên
      },
      onError: (err) {
        log('Lỗi deep link: $err');
      },
    );
  }

  @override
  void dispose() {
    _linkSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Volume Bubble',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.blue,
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xFF0F172A),
      ),
      home: const DashboardScreen(), // Màn hình chính
    );
  }
}
