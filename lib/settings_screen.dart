import 'package:flutter/material.dart';
import 'display_settings_widget.dart';

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
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late double _bubbleSize;
  late double _inactiveOpacity;
  late double _displayDuration;
  late double _animDuration;
  late bool _useBouncy;
  late bool _useScale;
  late bool _useFade;

  @override
  void initState() {
    super.initState();
    _bubbleSize = widget.bubbleSize;
    _inactiveOpacity = widget.inactiveOpacity;
    _displayDuration = widget.displayDuration;
    _animDuration = widget.animDuration;
    _useBouncy = widget.useBouncy;
    _useScale = widget.useScale;
    _useFade = widget.useFade;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          "Cài đặt hiển thị",
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            DisplaySettingsWidget(
              bubbleSize: _bubbleSize,
              inactiveOpacity: _inactiveOpacity,
              displayDuration: _displayDuration,
              animDuration: _animDuration,
              useBouncy: _useBouncy,
              useScale: _useScale,
              useFade: _useFade,
              onBubbleSizeChanged: (val) {
                setState(() => _bubbleSize = val);
                widget.onBubbleSizeChanged(val);
              },
              onInactiveOpacityChanged: (val) {
                setState(() => _inactiveOpacity = val);
                widget.onInactiveOpacityChanged(val);
              },
              onDisplayDurationChanged: (val) {
                setState(() => _displayDuration = val);
                widget.onDisplayDurationChanged(val);
              },
              onAnimDurationChanged: (val) {
                setState(() => _animDuration = val);
                widget.onAnimDurationChanged(val);
              },
              onBouncyChanged: (val) {
                setState(() => _useBouncy = val);
                widget.onBouncyChanged(val);
              },
              onScaleChanged: (val) {
                setState(() => _useScale = val);
                widget.onScaleChanged(val);
              },
              onFadeChanged: (val) {
                setState(() => _useFade = val);
                widget.onFadeChanged(val);
              },
              onApply: () {
                widget.onApply();
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: const Text("Đã áp dụng cài đặt!"),
                      backgroundColor: const Color(0xFF64B5F6),
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  );
                }
              },
              onResetToDefault: () {
                setState(() {
                  _bubbleSize = 68.0;
                  _inactiveOpacity = 0.5;
                  _displayDuration = 3.0;
                  _animDuration = 300.0;
                  _useBouncy = true;
                  _useScale = true;
                  _useFade = true;
                });
                widget.onResetToDefault();
              },
            ),
            const SizedBox(height: 100),
          ],
        ),
      ),
    );
  }
}
