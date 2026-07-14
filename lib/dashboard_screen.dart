import 'dart:async';
import 'package:flutter/material.dart';
import 'dart:ui';
import 'package:flutter_overlay_window/flutter_overlay_window.dart';
import 'package:flutter_volume_controller/flutter_volume_controller.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'update_helper.dart';
import 'settings_screen.dart';
import 'custom_settings_widget.dart';
import 'app_selector_screen.dart';
import 'usage_suggestions_screen.dart';
import 'package:flutter/services.dart';
import 'dart:convert';
import 'package:android_intent_plus/android_intent.dart';
import 'package:android_intent_plus/flag.dart';

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

  // [MỚI THÊM] Trạng thái tối ưu pin
  bool _isBatteryOptimized = false;

  double _inactiveOpacity = 0.5;
  double _bubbleSize = 68.0;

  // [MỚI THÊM] Cài đặt thời gian
  double _displayDuration = 3.0; // Thời gian hiển thị (giây)
  double _animDuration = 300.0; // Thời gian hiệu ứng (mili giây)

  bool _useBouncy = true;
  bool _useScale = true;
  bool _useFade = true;

  String? _selectedAppName;
  String? _selectedAppPackage;

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
    _checkBatteryStatus();

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
      } else if (event == "music_player_not_found") {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                "❌ Không tìm thấy trình phát nhạc nào trên thiết bị này! Vui lòng cài đặt một ứng dụng nhạc (như Spotify, YouTube Music...).",
              ),
              backgroundColor: Color(0xFFEF4444),
              behavior: SnackBarBehavior.floating,
              duration: Duration(seconds: 4),
            ),
          );
        }
      }
    });
  }

  // [MỚI THÊM] Kiểm tra trạng thái tối ưu pin
  Future<void> _checkBatteryStatus() async {
    const platform = MethodChannel('com.example.am_luong/tile');
    try {
      final bool isIgnoring = await platform.invokeMethod(
        'checkBatteryOptimization',
      );
      if (mounted) {
        setState(() {
          _isBatteryOptimized = !isIgnoring;
        });
      }
    } on PlatformException catch (e) {
      log("Lỗi kiểm tra pin: ${e.message}");
    }
  }

  // [MỚI THÊM] Mở cài đặt tối ưu pin
  Future<void> _openBatterySettings() async {
    final intent = AndroidIntent(
      action: 'android.settings.IGNORE_BATTERY_OPTIMIZATION_SETTINGS',
      flags: [Flag.FLAG_ACTIVITY_NEW_TASK],
    );
    try {
      await intent.launch();
    } catch (e) {
      // Nếu không mở được trang cụ thể, mở trang cài đặt pin chung
      final fallbackIntent = AndroidIntent(
        action: 'android.settings.SETTINGS',
        flags: [Flag.FLAG_ACTIVITY_NEW_TASK],
      );
      await fallbackIntent.launch();
    }
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
      _useBouncy = prefs.getBool('useBouncy') ?? true;
      _useScale = prefs.getBool('useScale') ?? true;
      _useFade = prefs.getBool('useFade') ?? true;
      _selectedAppName = prefs.getString('selectedAppName');
      _selectedAppPackage = prefs.getString('selectedAppPackage');
    });
  }

  Future<void> _saveSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('inactiveOpacity', _inactiveOpacity);
    await prefs.setDouble('bubbleSize', _bubbleSize);
    await prefs.setDouble('displayDuration', _displayDuration);
    await prefs.setDouble('animDuration', _animDuration);
    await prefs.setBool('useBouncy', _useBouncy);
    await prefs.setBool('useScale', _useScale);
    await prefs.setBool('useFade', _useFade);
    if (_selectedAppName != null) {
      await prefs.setString('selectedAppName', _selectedAppName!);
    } else {
      await prefs.remove('selectedAppName');
    }
    if (_selectedAppPackage != null) {
      await prefs.setString('selectedAppPackage', _selectedAppPackage!);
    } else {
      await prefs.remove('selectedAppPackage');
    }
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

  // [MỚI THÊM] Cập nhật giao diện bong bóng thời gian thực
  void _updateOverlayPreview() {
    final data = {
      "type": "update_preview",
      "bubbleSize": _bubbleSize,
      "inactiveOpacity": _inactiveOpacity,
      "displayDuration": _displayDuration,
      "animDuration": _animDuration,
      "useBouncy": _useBouncy,
      "useScale": _useScale,
      "useFade": _useFade,
      "selectedAppPackage": _selectedAppPackage,
    };
    FlutterOverlayWindow.shareData(jsonEncode(data));
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
              if (_isBatteryOptimized) ...[
                _buildBatteryWarning(),
                const SizedBox(height: 20),
              ],

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
                        "Phát triển bởi: Ng.Tá Tưởng",
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

              ClipRRect(
                borderRadius: BorderRadius.circular(24),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          _isBubbleActive
                              ? const Color(
                                  0xFF10B981,
                                ).withAlpha((0.15 * 255).toInt())
                              : const Color(
                                  0xFF475569,
                                ).withAlpha((0.15 * 255).toInt()),
                          _isBubbleActive
                              ? const Color(
                                  0xFF059669,
                                ).withAlpha((0.05 * 255).toInt())
                              : const Color(
                                  0xFF1E293B,
                                ).withAlpha((0.05 * 255).toInt()),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                        color: _isBubbleActive
                            ? const Color(
                                0xFF10B981,
                              ).withAlpha((0.4 * 255).toInt())
                            : const Color(
                                0xFF475569,
                              ).withAlpha((0.4 * 255).toInt()),
                        width: 1.2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withAlpha((0.1 * 255).toInt()),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        Text(
                          _isBubbleActive ? "ĐANG HOẠT ĐỘNG" : "ĐANG TẮT !",
                          style: TextStyle(
                            fontSize: 18,
                            letterSpacing: 1.2,
                            fontWeight: FontWeight.bold,
                            color: _isBubbleActive
                                ? const Color(0xFF34D399)
                                : const Color(0xFFF87171),
                            shadows: [
                              Shadow(
                                color:
                                    (_isBubbleActive
                                            ? const Color(0xFF10B981)
                                            : const Color(0xFFEF4444))
                                        .withAlpha((0.5 * 255).toInt()),
                                blurRadius: 12,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),
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

                            final active =
                                await FlutterOverlayWindow.isActive();
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
                        const SizedBox(height: 20),
                        const FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            "Thêm nút gạt vào thanh trạng thái",
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w500,
                            ),
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
                                                    backgroundColor:
                                                        const Color(0xFF64B5F6),
                                                    behavior: SnackBarBehavior
                                                        .floating,
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
                                icon: const Icon(Icons.add, size: 16),
                                label: const FittedBox(
                                  fit: BoxFit.scaleDown,
                                  child: Text("Thêm nút", maxLines: 1),
                                ),
                                style: OutlinedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 4,
                                    vertical: 12,
                                  ),
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
                                          await platform.invokeMethod(
                                            'removeTile',
                                          );
                                          await _loadSettings();
                                        } on PlatformException catch (e) {
                                          log("Lỗi khi gỡ Tile: ${e.message}");
                                        }
                                      },
                                icon: const Icon(Icons.close, size: 16),
                                label: const FittedBox(
                                  fit: BoxFit.scaleDown,
                                  child: Text("Hủy thêm", maxLines: 1),
                                ),
                                style: OutlinedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 4,
                                    vertical: 12,
                                  ),
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
                ),
              ),

              const SizedBox(height: 24),

              CustomSettingsWidget(
                selectedAppName: _selectedAppName,
                selectedAppPackage: _selectedAppPackage,
                onSelectApp: () async {
                  final result = await Navigator.push(
                    context,
                    PageRouteBuilder(
                      pageBuilder: (context, animation, secondaryAnimation) =>
                          const AppSelectorScreen(),
                      transitionsBuilder:
                          (context, animation, secondaryAnimation, child) {
                            return FadeTransition(
                              opacity: animation,
                              child: child,
                            );
                          },
                      transitionDuration: const Duration(milliseconds: 300),
                    ),
                  );
                  if (result != null && result is Map) {
                    setState(() {
                      _selectedAppName = result['name'];
                      _selectedAppPackage = result['packageName'];
                    });
                    await _saveSettings();
                    _updateOverlayPreview();
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: const Text("Đã cập nhật ứng dụng nhấn giữ"),
                          backgroundColor: const Color(0xFF64B5F6),
                          behavior: SnackBarBehavior.floating,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(15.0),
                          ),
                        ),
                      );
                    }
                  }
                },
                onReset: () async {
                  setState(() {
                    _selectedAppName = null;
                    _selectedAppPackage = null;
                  });
                  await _saveSettings();
                  _updateOverlayPreview();
                },
              ),

              const SizedBox(height: 24),

              // NÚT CHUYỂN SANG TRANG CÀI ĐẶT
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white.withAlpha((0.05 * 255).toInt()),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: Colors.white.withAlpha((0.1 * 255).toInt()),
                      ),
                    ),
                    child: ListTile(
                      onTap: () {
                        Navigator.push(
                          context,
                          PageRouteBuilder(
                            pageBuilder:
                                (context, animation, secondaryAnimation) =>
                                    SettingsScreen(
                                      bubbleSize: _bubbleSize,
                                      inactiveOpacity: _inactiveOpacity,
                                      displayDuration: _displayDuration,
                                      animDuration: _animDuration,
                                      useBouncy: _useBouncy,
                                      useScale: _useScale,
                                      useFade: _useFade,
                                      onBubbleSizeChanged: (val) {
                                        setState(() => _bubbleSize = val);
                                        _updateOverlayPreview();
                                      },
                                      onInactiveOpacityChanged: (val) {
                                        setState(() => _inactiveOpacity = val);
                                        _updateOverlayPreview();
                                      },
                                      onDisplayDurationChanged: (val) {
                                        setState(() => _displayDuration = val);
                                        _updateOverlayPreview();
                                      },
                                      onAnimDurationChanged: (val) {
                                        setState(() => _animDuration = val);
                                        _updateOverlayPreview();
                                      },
                                      onBouncyChanged: (val) {
                                        setState(() => _useBouncy = val);
                                        _updateOverlayPreview();
                                      },
                                      onScaleChanged: (val) {
                                        setState(() => _useScale = val);
                                        _updateOverlayPreview();
                                      },
                                      onFadeChanged: (val) {
                                        setState(() => _useFade = val);
                                        _updateOverlayPreview();
                                      },
                                      onResetToDefault: () {
                                        setState(() {
                                          _bubbleSize = 68.0;
                                          _inactiveOpacity = 0.5;
                                          _displayDuration = 3.0;
                                          _animDuration = 300.0;
                                          _useBouncy = false;
                                          _useScale = false;
                                          _useFade = false;
                                        });
                                        _updateOverlayPreview();
                                      },
                                      onApply: _saveSettings,
                                    ),
                            transitionsBuilder:
                                (
                                  context,
                                  animation,
                                  secondaryAnimation,
                                  child,
                                ) {
                                  return FadeTransition(
                                    opacity: animation,
                                    child: child,
                                  );
                                },
                            transitionDuration: const Duration(
                              milliseconds: 300,
                            ),
                          ),
                        );
                      },
                      leading: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(
                            0xFF38BDF8,
                          ).withAlpha((0.2 * 255).toInt()),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.settings_suggest_rounded,
                          color: Color(0xFF38BDF8),
                        ),
                      ),
                      title: const Text(
                        "Cài đặt hiển thị",
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      subtitle: const Text(
                        "Kích thước, độ mờ, thời gian...",
                        style: TextStyle(color: Colors.white54, fontSize: 12),
                      ),
                      trailing: const Icon(
                        Icons.arrow_forward_ios,
                        color: Colors.white24,
                        size: 16,
                      ),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // NÚT CHUYỂN SANG TRANG GỢI Ý SỬ DỤNG
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white.withAlpha((0.05 * 255).toInt()),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: Colors.white.withAlpha((0.1 * 255).toInt()),
                      ),
                    ),
                    child: ListTile(
                      onTap: () {
                        Navigator.push(
                          context,
                          PageRouteBuilder(
                            pageBuilder:
                                (context, animation, secondaryAnimation) =>
                                    const UsageSuggestionsScreen(),
                            transitionsBuilder:
                                (
                                  context,
                                  animation,
                                  secondaryAnimation,
                                  child,
                                ) {
                                  return FadeTransition(
                                    opacity: animation,
                                    child: child,
                                  );
                                },
                            transitionDuration: const Duration(
                              milliseconds: 300,
                            ),
                          ),
                        );
                      },
                      leading: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(
                            0xFF10B981,
                          ).withAlpha((0.2 * 255).toInt()),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.lightbulb_outline,
                          color: Color(0xFF10B981),
                        ),
                      ),
                      title: const Text(
                        "Gợi ý sử dụng",
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      subtitle: const Text(
                        "Hướng dẫn thao tác và mẹo hay...",
                        style: TextStyle(color: Colors.white54, fontSize: 12),
                      ),
                      trailing: const Icon(
                        Icons.arrow_forward_ios,
                        color: Colors.white24,
                        size: 16,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // [MỚI THÊM] Widget cảnh báo tối ưu pin
  Widget _buildBatteryWarning() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0x26F59E0B), // Màu vàng cảnh báo (opacity thấp)
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFF59E0B), width: 1),
      ),
      child: Column(
        children: [
          const Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: Color(0xFFF59E0B)),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  "Cảnh báo tối ưu pin",
                  style: TextStyle(
                    color: Color(0xFFF59E0B),
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Text(
            "Hệ thống có thể tự động tắt bong bóng để tiết kiệm pin. Vui lòng chuyển ứng dụng sang chế độ 'Không hạn chế'.",
            style: TextStyle(color: Colors.white70, fontSize: 13),
          ),
          const SizedBox(height: 12),
          ElevatedButton(
            onPressed: () async {
              await _openBatterySettings();
              // Sau khi quay lại, kiểm tra lại trạng thái
              Future.delayed(const Duration(seconds: 2), () {
                _checkBatteryStatus();
              });
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFF59E0B),
              foregroundColor: Colors.black,
              minimumSize: const Size(double.infinity, 40),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text(
              "Đi đến cài đặt",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }
}
