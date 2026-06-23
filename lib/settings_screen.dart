import 'package:flutter/material.dart';
import 'display_settings_widget.dart';
import 'dart:ui';

class SettingsScreen extends StatefulWidget {
  final double bubbleSize;
  final double inactiveOpacity;
  final double displayDuration;
  final double animDuration;
  final bool useBouncy;
  final bool useScale;
  final bool useFade;
  final Function(double) onBubbleSizeChanged;
  final Function(double) onInactiveOpacityChanged;
  final Function(double) onDisplayDurationChanged;
  final Function(double) onAnimDurationChanged;
  final Function(bool) onBouncyChanged;
  final Function(bool) onScaleChanged;
  final Function(bool) onFadeChanged;
  final VoidCallback onResetToDefault;
  final Future<void> Function() onApply;

  const SettingsScreen({
    super.key,
    required this.bubbleSize,
    required this.inactiveOpacity,
    required this.displayDuration,
    required this.animDuration,
    required this.useBouncy,
    required this.useScale,
    required this.useFade,
    required this.onBubbleSizeChanged,
    required this.onInactiveOpacityChanged,
    required this.onDisplayDurationChanged,
    required this.onAnimDurationChanged,
    required this.onBouncyChanged,
    required this.onScaleChanged,
    required this.onFadeChanged,
    required this.onResetToDefault,
    required this.onApply,
  });

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  // Chúng ta sử dụng local state để UI cập nhật mượt mà khi kéo slider
  late double _localBubbleSize;
  late double _localInactiveOpacity;
  late double _localDisplayDuration;
  late double _localAnimDuration;
  late bool _localUseBouncy;
  late bool _localUseScale;
  late bool _localUseFade;

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 1),
        behavior: SnackBarBehavior.floating,
        backgroundColor: const Color(0xFF38BDF8).withOpacity(0.8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    _localBubbleSize = widget.bubbleSize;
    _localInactiveOpacity = widget.inactiveOpacity;
    _localDisplayDuration = widget.displayDuration;
    _localAnimDuration = widget.animDuration;
    _localUseBouncy = widget.useBouncy;
    _localUseScale = widget.useScale;
    _localUseFade = widget.useFade;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          "Cài đặt",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            DisplaySettingsWidget(
              bubbleSize: _localBubbleSize,
              inactiveOpacity: _localInactiveOpacity,
              displayDuration: _localDisplayDuration,
              animDuration: _localAnimDuration,
              useBouncy: _localUseBouncy,
              useScale: _localUseScale,
              useFade: _localUseFade,
              onBubbleSizeChanged: (val) {
                setState(() => _localBubbleSize = val);
                widget.onBubbleSizeChanged(val);
              },
              onInactiveOpacityChanged: (val) {
                setState(() => _localInactiveOpacity = val);
                widget.onInactiveOpacityChanged(val);
              },
              onDisplayDurationChanged: (val) {
                setState(() => _localDisplayDuration = val);
                widget.onDisplayDurationChanged(val);
              },
              onAnimDurationChanged: (val) {
                setState(() => _localAnimDuration = val);
                widget.onAnimDurationChanged(val);
              },
              onBouncyChanged: (val) {
                setState(() => _localUseBouncy = val);
                widget.onBouncyChanged(val);
                _showSnackBar(
                  val ? "Đã bật hiệu ứng nảy" : "Đã tắt hiệu ứng nảy",
                );
              },
              onScaleChanged: (val) {
                setState(() => _localUseScale = val);
                widget.onScaleChanged(val);
                _showSnackBar(
                  val ? "Đã bật hiệu ứng phóng to" : "Đã tắt hiệu ứng phóng to",
                );
              },
              onFadeChanged: (val) {
                setState(() => _localUseFade = val);
                widget.onFadeChanged(val);
                _showSnackBar(
                  val ? "Đã bật chuyển cảnh mượt" : "Đã tắt chuyển cảnh mượt",
                );
              },
              onResetToDefault: () {
                setState(() {
                  _localBubbleSize = 68.0;
                  _localInactiveOpacity = 0.5;
                  _localDisplayDuration = 3.0;
                  _localAnimDuration = 300.0;
                  _localUseBouncy = false;
                  _localUseScale = false;
                  _localUseFade = false;
                });
                widget.onResetToDefault();
                _showSnackBar("Đã khôi phục cài đặt mặc định");
              },
              onApply: () async {
                await widget.onApply();
                _showSnackBar("Đã lưu cấu hình thay đổi");
              },
            ),
            const SizedBox(height: 30),
            const Text(
              "Mẹo: Các thay đổi sẽ được hiển thị ngay lập tức trên bong bóng (nếu đang bật).",
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white54,
                fontSize: 13,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
