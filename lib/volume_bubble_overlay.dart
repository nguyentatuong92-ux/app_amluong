import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_volume_controller/flutter_volume_controller.dart';
import 'dart:ui';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_overlay_window/flutter_overlay_window.dart';
import 'package:package_info_plus/package_info_plus.dart';

// [MỚI THÊM] Import thư viện Android Intent
import 'package:android_intent_plus/android_intent.dart';
import 'package:android_intent_plus/flag.dart';
import 'dart:developer';

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

  // Chiều cao tự động giãn ra bằng 2.6 lần kích thước bong bóng
  double get _expandedHeight => _bubbleSize * 2.6;

  @override
  void initState() {
    super.initState();
    _fetchAndListenVolume();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();

    // ÉP TẢI LẠI TỪ Ổ CỨNG, BỎ QUA CACHE (SỬA LỖI KHÔNG NHẬN SIZE)
    await prefs.reload();

    if (mounted) {
      setState(() {
        _inactiveOpacity = prefs.getDouble('inactiveOpacity') ?? 0.5;
        _bubbleSize = prefs.getDouble('bubbleSize') ?? 68.0;
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
    _collapseTimer = Timer(const Duration(milliseconds: 3000), () {
      if (mounted) {
        _loadSettings();
        setState(() {
          _isExpanded = false;
        });
      }
    });
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
    FlutterVolumeController.removeListener();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    int volPercentage = (_volumeValue * 100).toInt();

    return Material(
      color: Colors.transparent,
      elevation: 0,
      child: AnimatedOpacity(
        opacity: _isExpanded ? 1.0 : _inactiveOpacity,
        duration: const Duration(milliseconds: 500),
        child: Center(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(100),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 12.0, sigmaY: 12.0),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                curve: Curves.easeOutCubic,
                width: _bubbleSize,
                height: _isExpanded ? _expandedHeight : _bubbleSize,
                decoration: BoxDecoration(
                  color: const Color(0xFF0F172A).withOpacity(0.2),
                  borderRadius: BorderRadius.circular(100),
                  border: Border.all(
                    color: const Color(0xFF38BDF8).withOpacity(0.3),
                    width: 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.15),
                      blurRadius: 8,
                    ),
                  ],
                ),
                child: _isExpanded
                    ? _buildExpandedToolbar()
                    : _buildCollapsedCircularBubble(volPercentage),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCollapsedCircularBubble(int volPercentage) {
    return GestureDetector(
      onTap: () {
        setState(() {
          _isExpanded = true;
        });
        _resetTimer();
      },
      onDoubleTap: _toggleMute,

      // [MỚI SỬA] Nhấn giữ sẽ mở Deep Link để đánh thức app
      // [MỚI SỬA] Nhấn giữ sẽ gọi thẳng tên gói ứng dụng để mở
      onLongPress: () async {
        HapticFeedback.heavyImpact(); // Rung điện thoại để báo hiệu
        log("Đang ra lệnh cho Android mở ứng dụng...");

        try {
          // 1. Lấy tên gói (Package Name) của app bạn
          PackageInfo packageInfo = await PackageInfo.fromPlatform();
          String pkgName = packageInfo.packageName;

          // 2. Tạo lệnh ép Android mở thẳng ứng dụng này lên
          AndroidIntent intent = AndroidIntent(
            action: 'android.intent.action.MAIN',
            category: 'android.intent.category.LAUNCHER',
            package: pkgName,
            componentName: '$pkgName.MainActivity',
            flags: [
              Flag.FLAG_ACTIVITY_NEW_TASK,
            ], // Cờ bắt buộc để mở app từ nền
          );

          await intent.launch();
        } catch (e) {
          log('Lỗi khi mở app: $e');
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

  Widget _buildExpandedToolbar() {
    int volPercentage = (_volumeValue * 100).toInt();

    return Column(
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
