import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_overlay_window/flutter_overlay_window.dart';
import 'package:flutter_volume_controller/flutter_volume_controller.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'update_helper.dart';
import 'display_settings_widget.dart';
import 'package:flutter/services.dart';
import 'dart:io';

import 'dart:developer';

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

  // [MỚI THÊM] Biến lưu trạng thái xem có bản cập nhật mới không
  bool _hasNewUpdate = false;

  // [MỚI THÊM] Biến lưu trạng thái nút gạt đã được thêm hay chưa
  bool _isTileAdded = false;

  double _inactiveOpacity = 0.5;
  double _bubbleSize = 68.0;

  // [MỚI THÊM] Cài đặt thời gian
  double _displayDuration = 3.0; // Thời gian hiển thị (giây)
  double _animDuration = 300.0; // Thời gian hiệu ứng (mili giây)

  StreamSubscription? _overlayListener;

  @override
  void initState() {
    super.initState();
    _checkPermissions();
    _initVolume();
    _loadSettings();
    _loadAppVersion();
    _autoCheckForUpdate();
    _listenToOverlayEvents();

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

  void _autoCheckForUpdate() {
    // [ĐÃ SỬA] Hàm chờ kết quả trả về từ UpdateHelper
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      bool updateAvailable = await UpdateHelper.checkForUpdates(
        context,
        showMessage: false,
      );
      if (mounted && updateAvailable) {
        setState(() {
          _hasNewUpdate = true; // Bật chấm đỏ lên
        });
      }
    });
  }

  void _listenToOverlayEvents() {
    _overlayListener = FlutterOverlayWindow.overlayListener.listen((event) {
      log("Nhận được tín hiệu từ Overlay: $event");
      if (event == "open_settings") {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Đã mở ứng dụng từ bong bóng!"),
              backgroundColor: Color(0xFF10B981),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
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

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _inactiveOpacity = prefs.getDouble('inactiveOpacity') ?? 0.5;
      _bubbleSize = prefs.getDouble('bubbleSize') ?? 68.0;
      _isTileAdded = prefs.getBool('isTileAdded') ?? false;
      _displayDuration = prefs.getDouble('displayDuration') ?? 3.0;
      _animDuration = prefs.getDouble('animDuration') ?? 300.0;
    });
  }

  Future<void> _saveSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('inactiveOpacity', _inactiveOpacity);
    await prefs.setDouble('bubbleSize', _bubbleSize);
    await prefs.setDouble('displayDuration', _displayDuration);
    await prefs.setDouble('animDuration', _animDuration);
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
    _overlayListener?.cancel();
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
                        "Nhà phát triển: Ng.Tá Tưởng",
                        style: TextStyle(fontSize: 14, color: Colors.white60),
                      ),
                    ],
                  ),
                ],
              ),

              const SizedBox(height: 24),

              ElevatedButton.icon(
                // [ĐÃ SỬA] Đợi hàm chạy xong để cập nhật lại trạng thái
                onPressed: () async {
                  bool updateAvailable = await UpdateHelper.checkForUpdates(
                    context,
                    showMessage: true,
                  );
                  if (mounted) {
                    setState(() {
                      _hasNewUpdate =
                          updateAvailable; // Nếu vẫn còn cập nhật thì giữ chấm đỏ, ngược lại thì tắt
                    });
                  }
                },
                // [MỚI THÊM] Bọc Icon bằng Badge để hiển thị chấm đỏ
                icon: Badge(
                  isLabelVisible: _hasNewUpdate, // Hiển thị khi có bản mới
                  backgroundColor: Colors.redAccent, // Màu chấm đỏ
                  child: const Icon(
                    Icons.system_update,
                    color: Colors.white,
                    size: 22,
                  ),
                ),
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
                      _isBubbleActive ? "ĐANG HOẠT ĐỘNG" : "ĐANG TẮT !",
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
                    const SizedBox(height: 16),
                    const Text(
                      "Thêm nút gạt vào thanh trạng thái",
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.white70,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        // Nút THÊM
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: _isTileAdded
                                ? null
                                : () async {
                                    const platform = MethodChannel(
                                      'com.example.am_luong/tile',
                                    );
                                    try {
                                      await platform.invokeMethod(
                                        'requestAddTile',
                                      );
                                      Future.delayed(
                                        const Duration(seconds: 2),
                                        () async {
                                          await _loadSettings();
                                          if (_isTileAdded && mounted) {
                                            ScaffoldMessenger.of(
                                              context,
                                            ).showSnackBar(
                                              SnackBar(
                                                backgroundColor: const Color(
                                                  0xFF64B5F6,
                                                ),
                                                behavior:
                                                    SnackBarBehavior.floating,
                                                shape: RoundedRectangleBorder(
                                                  borderRadius:
                                                      BorderRadius.circular(
                                                        15.0,
                                                      ),
                                                ),
                                                content: const Text(
                                                  "Bạn đã thêm nút gạt thành công !",
                                                  style: TextStyle(
                                                    fontSize: 20,
                                                  ),
                                                ),
                                              ),
                                            );
                                          }
                                        },
                                      );
                                    } on PlatformException catch (e) {
                                      log("Lỗi thêm Tile: ${e.message}");
                                    }
                                  },
                            icon: const Icon(Icons.add, size: 18),
                            label: const Text(
                              "Thêm nút",
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: const Color(0xFF38BDF8),
                              disabledForegroundColor: Colors.white10,
                              side: BorderSide(
                                color: _isTileAdded
                                    ? Colors.white10
                                    : const Color(0xFF38BDF8),
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        // Nút HỦY
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: !_isTileAdded
                                ? null
                                : () async {
                                    const platform = MethodChannel(
                                      'com.example.am_luong/tile',
                                    );
                                    try {
                                      await platform.invokeMethod('removeTile');
                                      if (mounted) {
                                        setState(() {
                                          _isTileAdded = false;
                                        });
                                        ScaffoldMessenger.of(
                                          context,
                                        ).showSnackBar(
                                          SnackBar(
                                            content: const Text(
                                              "Bạn đã hủy thêm nút gạt vào cài đặt nhanh !",
                                              style: TextStyle(fontSize: 20),
                                            ),
                                            backgroundColor: const Color(
                                              0xFF64B5F6,
                                            ),
                                            behavior: SnackBarBehavior.floating,
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(15.0),
                                            ),
                                          ),
                                        );
                                      }
                                    } on PlatformException catch (e) {
                                      log("Lỗi khi gỡ Tile: ${e.message}");
                                    }
                                  },
                            icon: const Icon(Icons.close, size: 18),
                            label: const Text(
                              "Hủy thêm",
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: const Color(0xFFF87171),
                              disabledForegroundColor: Colors.white10,
                              side: BorderSide(
                                color: !_isTileAdded
                                    ? Colors.white10
                                    : const Color(0xFFF87171),
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      _isTileAdded
                          ? "✅ Đã thêm nút gạt vào cài đặt nhanh !"
                          : "ℹ️ Vui lòng nhấn thêm nút gạt !",
                      style: TextStyle(
                        fontSize: 13,
                        color: _isTileAdded
                            ? const Color(0xFF34D399)
                            : Colors.white54,
                        fontStyle: _isTileAdded
                            ? FontStyle.normal
                            : FontStyle.italic,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // KHU VỰC CÀI ĐẶT
              DisplaySettingsWidget(
                bubbleSize: _bubbleSize,
                inactiveOpacity: _inactiveOpacity,
                displayDuration: _displayDuration,
                animDuration: _animDuration,
                onBubbleSizeChanged: (val) => setState(() => _bubbleSize = val),
                onInactiveOpacityChanged: (val) =>
                    setState(() => _inactiveOpacity = val),
                onDisplayDurationChanged: (val) =>
                    setState(() => _displayDuration = val),
                onAnimDurationChanged: (val) =>
                    setState(() => _animDuration = val),
                onResetToDefault: () {
                  setState(() {
                    _bubbleSize = 50.0;
                    _inactiveOpacity = 0.5;
                    _displayDuration = 5.0;
                    _animDuration = 500.0;
                  });
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: const Text(
                        "Đã đặt về thông số mặc định!",
                        style: TextStyle(fontSize: 20),
                      ),
                      backgroundColor: const Color(0xFF64B5F6),
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15.0),
                      ),
                    ),
                  );
                },
                onApply: () async {
                  await _saveSettings();
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: const Text(
                          "Đã lưu! Vui lòng TẮT và BẬT lại bong bóng để áp dụng.",
                          style: TextStyle(fontSize: 20),
                        ),
                        backgroundColor: const Color(0xFF64B5F6),
                        behavior: SnackBarBehavior.floating,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15.0),
                        ),
                      ),
                    );
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
