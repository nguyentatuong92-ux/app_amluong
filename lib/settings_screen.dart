import 'package:flutter/material.dart';
import 'display_settings_widget.dart';

class SettingsScreen extends StatelessWidget {
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
  final VoidCallback onApply;

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
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          "Cài đặt hiển thị",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            DisplaySettingsWidget(
              bubbleSize: bubbleSize,
              inactiveOpacity: inactiveOpacity,
              displayDuration: displayDuration,
              animDuration: animDuration,
              useBouncy: useBouncy,
              useScale: useScale,
              useFade: useFade,
              onBubbleSizeChanged: onBubbleSizeChanged,
              onInactiveOpacityChanged: onInactiveOpacityChanged,
              onDisplayDurationChanged: onDisplayDurationChanged,
              onAnimDurationChanged: onAnimDurationChanged,
              onBouncyChanged: onBouncyChanged,
              onScaleChanged: onScaleChanged,
              onFadeChanged: onFadeChanged,
              onApply: onApply,
              onResetToDefault: onResetToDefault,
            ),
            // KHOẢNG TRỐNG Ở CUỐI TRANG
            const SizedBox(height: 100),
          ],
        ),
      ),
    );
  }
}
