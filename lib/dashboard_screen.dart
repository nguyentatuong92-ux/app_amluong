import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_overlay_window/flutter_overlay_window.dart';
import 'package:flutter_volume_controller/flutter_volume_controller.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'update_helper.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  bool _isOverlayGranted = false;
  bool _isBubbleActive = false;
  double _currentVolume = 0.0;
  String _currentAppVersion = "Đang tải...";

  // BIẾN CÀI ĐẶT
  double _inactiveOpacity = 0.5;
  double _bubbleSize = 68.0; // Mặc định kích thước là 68

  @override
  void initState() {
    super.initState();
    _checkPermissions();
    _initVolume();
    _loadSettings();
    _loadAppVersion();

    Timer.periodic(const Duration(seconds: 1), (timer) async {
      final active = await FlutterOverlayWindow.isActive();
      final granted = await FlutterOverlayWindow.isPermissionGranted();
      if (mounted) {
        setState(() {
          _isBubbleActive = active;
          _isOverlayGranted = granted;
        });
      }
    });
  }

  Future<void> _loadAppVersion() async {
    PackageInfo packageInfo = await PackageInfo.fromPlatform();
    if (mounted) {
      setState(() {
        _currentAppVersion = packageInfo.version;
      });
    }
  }

  // Tải cài đặt từ bộ nhớ
  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _inactiveOpacity = prefs.getDouble('inactiveOpacity') ?? 0.5;
      _bubbleSize = prefs.getDouble('bubbleSize') ?? 68.0;
    });
  }

  // Lưu cài đặt vào bộ nhớ
  Future<void> _saveSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('inactiveOpacity', _inactiveOpacity);
    await prefs.setDouble('bubbleSize', _bubbleSize);
  }

  Future<void> _checkPermissions() async {
    final granted = await FlutterOverlayWindow.isPermissionGranted();
    setState(() {
      _isOverlayGranted = granted;
    });
  }

  Future<void> _initVolume() async {
    FlutterVolumeController.addListener((volume) {
      if (mounted) {
        setState(() {
          _currentVolume = volume;
        });
      }
    });
    final vol = await FlutterVolumeController.getVolume(
      stream: AudioStream.music,
    );
    if (mounted) {
      setState(() {
        _currentVolume = vol ?? 0.0;
      });
    }
  }

  @override
  void dispose() {
    FlutterVolumeController.removeListener();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 10),

              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        colors: [Color(0xFF38BDF8), Color(0xFF0284C7)],
                      ),
                    ),
                    child: const Icon(
                      Icons.volume_up,
                      size: 28,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Volume Bubble",
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      Text(
                        "Đồng bộ Samsung S25 Plus Auto-snap",
                        style: TextStyle(fontSize: 12, color: Colors.white60),
                      ),
                    ],
                  ),
                ],
              ),

              const SizedBox(height: 24),

              ElevatedButton.icon(
                onPressed: () =>
                    UpdateHelper.checkForUpdates(context, showMessage: true),
                icon: const Icon(Icons.system_update, color: Colors.white),
                label: const Text(
                  "Kiểm tra bản cập nhật mới",
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1E293B),
                  foregroundColor: const Color(0xFF38BDF8),
                  minimumSize: const Size(double.infinity, 50),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    side: const BorderSide(color: Colors.white10),
                  ),
                ),
              ),

              const SizedBox(height: 8),
              Text(
                "Phiên bản hiện tại: v$_currentAppVersion",
                style: const TextStyle(
                  fontSize: 12,
                  color: Colors.white54,
                  fontStyle: FontStyle.italic,
                ),
              ),

              const SizedBox(height: 24),

              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: _isBubbleActive
                      ? const Color(0x1F10B981)
                      : const Color(0x1F475569),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: _isBubbleActive
                        ? const Color(0xFF10B981)
                        : const Color(0xFF475569),
                    width: 1,
                  ),
                ),
                child: Column(
                  children: [
                    Text(
                      _isBubbleActive ? "ĐANG HOẠT ĐỘNG" : "ĐANG TẮT",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: _isBubbleActive
                            ? const Color(0xFF34D399)
                            : const Color(0xFFF87171),
                      ),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: () async {
                        if (!await FlutterOverlayWindow.isPermissionGranted()) {
                          if (await FlutterOverlayWindow.requestPermission() ==
                              true) {
                            setState(() {
                              _isOverlayGranted = true;
                            });
                          }
                          return;
                        }
                        if (_isBubbleActive) {
                          await FlutterOverlayWindow.closeOverlay();
                        } else {
                          await FlutterOverlayWindow.showOverlay(
                            enableDrag: true,
                            flag: OverlayFlag.defaultFlag,
                            alignment: OverlayAlignment.centerRight,
                            height: 480,
                            width: 200,
                          );
                        }

                        // Đã sửa lỗi await ở đây
                        final active = await FlutterOverlayWindow.isActive();
                        setState(() {
                          _isBubbleActive = active;
                        });
                      },
                      icon: Icon(
                        _isBubbleActive ? Icons.stop : Icons.play_arrow,
                        color: Colors.white,
                      ),
                      label: Text(
                        _isBubbleActive ? "Tắt Bong Bóng" : "Bật Bong Bóng",
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _isBubbleActive
                            ? const Color(0xFFEF4444)
                            : const Color(0xFF38BDF8),
                        foregroundColor: Colors.white,
                        minimumSize: const Size(double.infinity, 50),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // KHU VỰC CÀI ĐẶT
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E293B),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Cài đặt hiển thị",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // THANH KÉO KÍCH THƯỚC
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          "Kích thước bong bóng:",
                          style: TextStyle(fontSize: 13, color: Colors.white70),
                        ),
                        Text(
                          "${_bubbleSize.toInt()} px",
                          style: const TextStyle(
                            color: Color(0xFF38BDF8),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    Slider(
                      value: _bubbleSize,
                      min: 50.0,
                      max: 80.0,
                      onChanged: (val) => setState(() => _bubbleSize = val),
                      activeColor: const Color(0xFF38BDF8),
                      inactiveColor: Colors.white10,
                    ),

                    const Divider(color: Colors.white10, height: 10),

                    // THANH KÉO ĐỘ MỜ
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          "Độ mờ khi không chạm:",
                          style: TextStyle(fontSize: 13, color: Colors.white70),
                        ),
                        Text(
                          "${(_inactiveOpacity * 100).toInt()}%",
                          style: const TextStyle(
                            color: Color(0xFF38BDF8),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    Slider(
                      value: _inactiveOpacity,
                      min: 0.1,
                      max: 1.0,
                      onChanged: (val) =>
                          setState(() => _inactiveOpacity = val),
                      activeColor: const Color(0xFF38BDF8),
                      inactiveColor: Colors.white10,
                    ),

                    const SizedBox(height: 12),

                    // NÚT ÁP DỤNG
                    Align(
                      alignment: Alignment.centerRight,
                      child: ElevatedButton.icon(
                        onPressed: () async {
                          await _saveSettings();
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  "Đã lưu! Vui lòng TẮT và BẬT LẠI bong bóng để áp dụng.",
                                ),
                                backgroundColor: Color(0xFF10B981),
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
                          }
                        },
                        icon: const Icon(Icons.check_circle_outline, size: 18),
                        label: const Text("Áp dụng"),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(
                            0xFF38BDF8,
                          ).withOpacity(0.15),
                          foregroundColor: const Color(0xFF38BDF8),
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                            side: const BorderSide(
                              color: Color(0xFF38BDF8),
                              width: 1,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
