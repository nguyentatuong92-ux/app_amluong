import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_overlay_window/flutter_overlay_window.dart';
import 'package:flutter_volume_controller/flutter_volume_controller.dart';

// ==========================================
// MÀN HÌNH ĐIỀU KHIỂN CHÍNH (DASHBOARD)
// ==========================================
class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  bool _isOverlayGranted = false;
  bool _isBubbleActive = false;
  double _currentVolume = 0.0;

  @override
  void initState() {
    super.initState();
    _checkPermissions();
    _initVolume();

    // Đồng bộ định kỳ trạng thái bật/tắt của bóng nổi
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
              const SizedBox(height: 20),
              Center(
                child: Row(
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
              ),
              const SizedBox(height: 30),

              // CARD TRẠNG THÁI HIỂN THỊ
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
                    const Text(
                      "TRẠNG THÁI BÓNG ÂM LƯỢNG",
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: Colors.white60,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 10,
                          height: 10,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: _isBubbleActive
                                ? const Color(0xFF10B981)
                                : const Color(0xFFEF4444),
                          ),
                        ),
                        const SizedBox(width: 8),
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
                      ],
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton.icon(
                      onPressed: () async {
                        bool isGranted =
                            await FlutterOverlayWindow.isPermissionGranted();

                        if (!isGranted) {
                          bool? requestResult =
                              await FlutterOverlayWindow.requestPermission();
                          if (requestResult == true) {
                            setState(() {
                              _isOverlayGranted = true;
                            });
                          }
                          return;
                        }

                        if (_isBubbleActive) {
                          await FlutterOverlayWindow.closeOverlay();
                        } else {
                          // Thay đổi không gian vẽ phù hợp với giao diện dọc (+/-)
                          await FlutterOverlayWindow.showOverlay(
                            enableDrag: true,
                            overlayTitle: "Volume Floating Ball",
                            overlayContent: "Bóng âm lượng đang hoạt động",
                            flag: OverlayFlag.defaultFlag,
                            alignment: OverlayAlignment.centerRight,
                            height: 480,
                            // Chiều cao tối đa khi bung thanh dọc
                            width:
                                200, // Chiều rộng đủ cho bong bóng tròn và dọc
                          );
                        }
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
                        _isBubbleActive
                            ? "Tắt Bong Bóng Trôi Nổi"
                            : "Bật Bong Bóng Trôi Nổi",
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
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

              // THANH TEST ÂM LƯỢNG ĐỒNG BỘ TRỰC TIẾP
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E293B),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          "Âm lượng Đa phương tiện",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                        Text(
                          "${(_currentVolume * 100).toInt()}%",
                          style: const TextStyle(
                            color: Color(0xFF38BDF8),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    Slider(
                      value: _currentVolume,
                      onChanged: (val) {
                        setState(() {
                          _currentVolume = val;
                        });
                        FlutterVolumeController.setVolume(
                          val,
                          stream: AudioStream.music,
                        );
                      },
                      activeColor: const Color(0xFF38BDF8),
                      inactiveColor: Colors.white10,
                    ),
                    const Text(
                      "Kéo thanh gạt này để kiểm tra tính năng đồng bộ thời gian thực.",
                      style: TextStyle(fontSize: 10, color: Colors.white30),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // CHI TIẾT TỐI ƯU HÓA HOẠT ĐỘNG TRÊN SAMSUNG GALAXY S25 PLUS
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E293B),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.stars, color: Color(0xFFF39C12), size: 20),
                        SizedBox(width: 8),
                        Text(
                          "Mẹo tránh bị tắt ngầm (One UI 7.x/6.x)",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 10),
                    Text(
                      "Điện thoại Samsung S25 Plus của bạn có khả năng quản lý RAM cực gắt. Để tránh bị hệ thống tắt bong bóng khi tắt màn hình, hãy thiết lập:",
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.white70,
                        height: 1.5,
                      ),
                    ),
                    SizedBox(height: 10),
                    BulletItem(
                      text: "1. Vào Cài đặt -> Pin -> Giới hạn chạy ngầm.",
                    ),
                    BulletItem(
                      text:
                          "2. Chọn mục 'Ứng dụng không bao giờ ngủ' (Never sleeping).",
                    ),
                    BulletItem(
                      text:
                          "3. Thêm ứng dụng 'Volume Bubble' của bạn vào danh sách để nó chạy vô hạn.",
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

// Widget định dạng dòng ghi chú
class BulletItem extends StatelessWidget {
  final String text;

  const BulletItem({super.key, required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            margin: const EdgeInsets.only(top: 6),
            width: 5,
            height: 5,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: Color(0xFF38BDF8),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                fontSize: 12,
                color: Colors.white70,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
