import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_volume_controller/flutter_volume_controller.dart';
import 'dart:ui';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:package_info_plus/package_info_plus.dart';
import 'package:flutter_overlay_window/flutter_overlay_window.dart';

// [MỚI THÊM] Import thư viện Android Intent
import 'package:android_intent_plus/android_intent.dart';
import 'package:android_intent_plus/flag.dart';
import 'dart:developer';
import 'dart:convert';

class VolumeBubbleOverlay extends StatefulWidget {
  const VolumeBubbleOverlay({super.key});

  @override
  State<VolumeBubbleOverlay> createState() => _VolumeBubbleOverlayState();
}

class _VolumeBubbleOverlayState extends State<VolumeBubbleOverlay> {
  double _volumeValue = 0.0;
  bool _isExpanded = false;
  Timer? _collapseTimer;
  double _previousVolume = 0.5;

  // BIẾN CÀI ĐẶT TỪ BỘ NHỚ
  double _inactiveOpacity = 0.5;
  double _bubbleSize = 68.0;
  double _displayDuration = 3.0; // Mặc định 3 giây
  double _animDuration = 300.0; // Mặc định 300ms
  bool _useBouncy = true;
  bool _useScale = true;
  bool _useFade = true;
  String? _selectedAppPackage;

  StreamSubscription? _previewListener;

  // Chiều cao tự động giãn ra bằng 2.6 lần kích thước bong bóng
  double get _expandedHeight => _bubbleSize * 2.6;

  @override
  void initState() {
    super.initState();
    _fetchAndListenVolume();
    _loadSettings();
    _listenToPreviewUpdates();
  }

  // [MỚI THÊM] Lắng nghe cập nhật từ ứng dụng chính để xem trước thời gian thực
  void _listenToPreviewUpdates() {
    _previewListener = FlutterOverlayWindow.overlayListener.listen((event) {
      try {
        final data = jsonDecode(event.toString());
        if (data["type"] == "update_preview") {
          if (mounted) {
            setState(() {
              _bubbleSize = data["bubbleSize"] ?? _bubbleSize;
              _inactiveOpacity = data["inactiveOpacity"] ?? _inactiveOpacity;
              _displayDuration = data["displayDuration"] ?? _displayDuration;
              _animDuration = data["animDuration"] ?? _animDuration;
              _useBouncy = data["useBouncy"] ?? _useBouncy;
              _useScale = data["useScale"] ?? _useScale;
              _useFade = data["useFade"] ?? _useFade;
              _selectedAppPackage = data["selectedAppPackage"];
              _isExpanded =
                  false; // Khi chỉnh thì thu gọn lại để xem size chuẩn
            });
            _resetTimer(); // Hiện lên để người dùng thấy thay đổi
          }
        }
      } catch (e) {
        // Có thể là các event khác không phải JSON, bỏ qua
      }
    });
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();

    // ÉP TẢI LẠI TỪ Ổ CỨNG, BỎ QUA CACHE (SỬA LỖI KHÔNG NHẬN SIZE)
    await prefs.reload();

    if (mounted) {
      setState(() {
        _inactiveOpacity = prefs.getDouble('inactiveOpacity') ?? 0.5;
        _bubbleSize = prefs.getDouble('bubbleSize') ?? 68.0;
        _displayDuration = prefs.getDouble('displayDuration') ?? 3.0;
        _animDuration = prefs.getDouble('animDuration') ?? 300.0;
        _useBouncy = prefs.getBool('useBouncy') ?? true;
        _useScale = prefs.getBool('useScale') ?? true;
        _useFade = prefs.getBool('useFade') ?? true;
        _selectedAppPackage = prefs.getString('selectedAppPackage');
      });
    }
  }

  Future<void> _fetchAndListenVolume() async {
    final vol = await FlutterVolumeController.getVolume(
      stream: AudioStream.music,
    );
    if (mounted) {
      setState(() {
        _volumeValue = vol ?? 0.0;
      });
    }

    FlutterVolumeController.addListener((volume) {
      if (mounted) {
        setState(() {
          _volumeValue = volume;
        });
        _resetTimer();
      }
    });
  }

  void _resetTimer() {
    _collapseTimer?.cancel();
    _collapseTimer = Timer(
      Duration(milliseconds: (_displayDuration * 1000).toInt()),
      () {
        if (mounted) {
          _loadSettings();
          setState(() {
            _isExpanded = false;
          });
        }
      },
    );
  }

  void _increaseVolume() {
    HapticFeedback.lightImpact();
    double nVol = (_volumeValue + 0.07).clamp(0.0, 1.0);
    FlutterVolumeController.setVolume(nVol, stream: AudioStream.music);
    setState(() {
      _volumeValue = nVol;
    });
    _resetTimer();
  }

  void _decreaseVolume() {
    HapticFeedback.lightImpact();
    double nVol = (_volumeValue - 0.07).clamp(0.0, 1.0);
    FlutterVolumeController.setVolume(nVol, stream: AudioStream.music);
    setState(() {
      _volumeValue = nVol;
    });
    _resetTimer();
  }

  void _toggleMute() {
    HapticFeedback.mediumImpact();
    if (_volumeValue > 0.0) {
      _previousVolume = _volumeValue;
      FlutterVolumeController.setVolume(0.0, stream: AudioStream.music);
      setState(() {
        _volumeValue = 0.0;
      });
    } else {
      double restoreVol = _previousVolume > 0.0 ? _previousVolume : 0.3;
      FlutterVolumeController.setVolume(restoreVol, stream: AudioStream.music);
      setState(() {
        _volumeValue = restoreVol;
      });
    }
    _resetTimer();
  }

  @override
  void dispose() {
    _collapseTimer?.cancel();
    _previewListener?.cancel();
    FlutterVolumeController.removeListener();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    int volPercentage = (_volumeValue * 100).toInt();

    return Material(
      color: Colors.transparent,
      elevation: 0,
      child: AnimatedScale(
        scale: (_isExpanded && _useScale) ? 1.05 : 1.0,
        duration: Duration(milliseconds: _animDuration.toInt()),
        curve: _useBouncy ? Curves.elasticOut : Curves.easeOutCubic,
        child: AnimatedOpacity(
          opacity: _isExpanded ? 1.0 : _inactiveOpacity,
          duration: Duration(milliseconds: _animDuration.toInt() * 2),
          child: Center(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(100),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 22.0, sigmaY: 22.0),
                child: AnimatedContainer(
                  duration: Duration(milliseconds: _animDuration.toInt()),
                  curve: _useBouncy ? Curves.elasticOut : Curves.easeOutCubic,
                  width: _bubbleSize,
                  height: _isExpanded ? _expandedHeight : _bubbleSize,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        const Color(0xFF1E293B).withAlpha((0.4 * 255).toInt()),
                        const Color(0xFF0F172A).withAlpha((0.6 * 255).toInt()),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(100),
                    border: Border.all(
                      color: Colors.white.withAlpha((0.25 * 255).toInt()),
                      width: 0.8,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withAlpha((0.4 * 255).toInt()),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: _useFade
                      ? AnimatedSwitcher(
                          duration: Duration(
                            milliseconds: (_animDuration * 0.8).toInt(),
                          ),
                          transitionBuilder:
                              (Widget child, Animation<double> animation) {
                                return FadeTransition(
                                  opacity: animation,
                                  child: ScaleTransition(
                                    scale: animation,
                                    child: child,
                                  ),
                                );
                              },
                          child: _isExpanded
                              ? _buildExpandedToolbar(
                                  key: const ValueKey('expanded'),
                                )
                              : _buildCollapsedCircularBubble(
                                  volPercentage,
                                  key: const ValueKey('collapsed'),
                                ),
                        )
                      : (_isExpanded
                            ? _buildExpandedToolbar()
                            : _buildCollapsedCircularBubble(volPercentage)),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCollapsedCircularBubble(int volPercentage, {Key? key}) {
    return GestureDetector(
      key: key,
      onTap: () {
        setState(() {
          _isExpanded = true;
        });
        _resetTimer();
      },
      onDoubleTap: _toggleMute,

      // [MỚI SỬA] Nhấn giữ sẽ mở trình phát nhạc mặc định của hệ thống
      onLongPress: () async {
        HapticFeedback.heavyImpact();

        if (_selectedAppPackage != null) {
          log("Đang mở ứng dụng tùy chỉnh: $_selectedAppPackage");
          try {
            final intent = AndroidIntent(
              action: 'android.intent.action.MAIN',
              category: 'android.intent.category.LAUNCHER',
              package: _selectedAppPackage,
              flags: [Flag.FLAG_ACTIVITY_NEW_TASK],
            );
            await intent.launch();
            return;
          } catch (e) {
            log("Lỗi mở app tùy chỉnh: $e");
          }
        }

        log("Đang mở trình phát nhạc...");

        bool success = false;

        // --- CÁCH 1: Dùng category APP_MUSIC (Phổ biến nhất) ---
        try {
          final intent = AndroidIntent(
            action: 'android.intent.action.MAIN',
            category: 'android.intent.category.APP_MUSIC',
            flags: [Flag.FLAG_ACTIVITY_NEW_TASK],
          );
          await intent.launch();
          success = true;
          log("Mở app nhạc bằng APP_MUSIC thành công");
        } catch (e) {
          log("Cách 1 (APP_MUSIC) lỗi: $e");
        }

        // --- CÁCH 2: Dùng action MUSIC_PLAYER (Cách cũ) ---
        if (!success) {
          try {
            const intent = AndroidIntent(
              action: 'android.intent.action.MUSIC_PLAYER',
              flags: [Flag.FLAG_ACTIVITY_NEW_TASK],
            );
            await intent.launch();
            success = true;
            log("Mở app nhạc bằng MUSIC_PLAYER thành công");
          } catch (e) {
            log("Cách 2 (MUSIC_PLAYER) lỗi: $e");
          }
        }

        // --- CÁCH 3: Dùng action VIEW với kiểu audio/* ---
        if (!success) {
          try {
            const intent = AndroidIntent(
              action: 'android.intent.action.VIEW',
              type: 'audio/*',
              flags: [Flag.FLAG_ACTIVITY_NEW_TASK],
            );
            await intent.launch();
            success = true;
            log("Mở app nhạc bằng audio/* thành công");
          } catch (e) {
            log("Cách 3 (audio/*) lỗi: $e");
          }
        }

        // --- NẾU TẤT CẢ ĐỀU THẤT BẠI (Máy ảo không có app nhạc) ---
        if (!success) {
          log("Không tìm thấy trình phát nhạc nào. Đang mở app để báo lỗi...");
          try {
            // 1. Gửi tín hiệu báo lỗi cho Dashboard
            FlutterOverlayWindow.shareData("music_player_not_found");

            // 2. Mở chính ứng dụng của mình để hiển thị thông báo
            PackageInfo packageInfo = await PackageInfo.fromPlatform();
            String pkgName = packageInfo.packageName;
            AndroidIntent intent = AndroidIntent(
              action: 'android.intent.action.MAIN',
              category: 'android.intent.category.LAUNCHER',
              package: pkgName,
              componentName: '$pkgName.MainActivity',
              flags: [Flag.FLAG_ACTIVITY_NEW_TASK],
            );
            await intent.launch();
          } catch (e) {
            log("Không thể mở app fallback: $e");
          }
        }
      },

      child: Stack(
        alignment: Alignment.center,
        children: [
          SizedBox(
            width: _bubbleSize - 8,
            height: _bubbleSize - 8,
            child: CircularProgressIndicator(
              value: _volumeValue,
              strokeWidth: 2.5,
              color: volPercentage == 0
                  ? const Color(0xFFF87171)
                  : const Color(0xFF38BDF8),
              backgroundColor: Colors.transparent,
            ),
          ),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                volPercentage == 0
                    ? Icons.volume_off_rounded
                    : Icons.volume_up_rounded,
                color: Colors.white,
                size: _bubbleSize * 0.26,
              ),
              const SizedBox(height: 2),
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  volPercentage == 0 ? "Mute" : "$volPercentage%",
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  style: TextStyle(
                    color: volPercentage == 0
                        ? const Color(0xFFF87171)
                        : const Color(0xFF38BDF8),
                    fontSize: _bubbleSize * 0.18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildExpandedToolbar({Key? key}) {
    int volPercentage = (_volumeValue * 100).toInt();

    return Column(
      key: key,
      children: [
        Expanded(
          child: GestureDetector(
            onTap: _increaseVolume,
            behavior: HitTestBehavior.opaque,
            child: SizedBox(
              width: _bubbleSize,
              child: Icon(
                Icons.add,
                color: const Color(0xFF4ADE80),
                size: _bubbleSize * 0.4,
              ),
            ),
          ),
        ),
        Expanded(
          child: Center(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                "$volPercentage%",
                textAlign: TextAlign.center,
                maxLines: 1,
                style: TextStyle(
                  color: const Color(0xFF38BDF8),
                  fontSize: _bubbleSize * 0.26,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ),
        Expanded(
          child: GestureDetector(
            onTap: _decreaseVolume,
            behavior: HitTestBehavior.opaque,
            child: SizedBox(
              width: _bubbleSize,
              child: Icon(
                Icons.remove,
                color: const Color(0xFFF87171),
                size: _bubbleSize * 0.4,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
