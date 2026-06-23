import 'package:flutter/material.dart';
import 'dart:ui';

class DisplaySettingsWidget extends StatelessWidget {
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
  final VoidCallback onApply;
  final VoidCallback onResetToDefault;

  const DisplaySettingsWidget({
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
    required this.onApply,
    required this.onResetToDefault,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                const Color(0xFF1E293B).withAlpha((0.2 * 255).toInt()),
                const Color(0xFF0F172A).withAlpha((0.1 * 255).toInt()),
              ],
            ),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: Colors.white.withAlpha((0.1 * 255).toInt()),
              width: 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Cài đặt hiển thị",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                  letterSpacing: 0.5,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 20),

              // Kích thước bong bóng
              _buildSettingRow(
                label: "Kích thước bong bóng:",
                value: "${bubbleSize.toInt()} px",
              ),
              _buildSliderRow(
                value: bubbleSize.clamp(40.0, 75.0),
                min: 40.0,
                max: 75.0,
                onDecrement: () =>
                    onBubbleSizeChanged((bubbleSize - 1).clamp(40.0, 75.0)),
                onIncrement: () =>
                    onBubbleSizeChanged((bubbleSize + 1).clamp(40.0, 75.0)),
                onChanged: onBubbleSizeChanged,
              ),

              const Divider(color: Colors.white10, height: 20),

              // Độ mờ khi không chạm
              _buildSettingRow(
                label: "Độ mờ khi không chạm:",
                value: "${(inactiveOpacity * 100).toInt()}%",
              ),
              _buildSliderRow(
                value: inactiveOpacity,
                min: 0.1,
                max: 1.0,
                onDecrement: () => onInactiveOpacityChanged(
                  (inactiveOpacity - 0.05).clamp(0.1, 1.0),
                ),
                onIncrement: () => onInactiveOpacityChanged(
                  (inactiveOpacity + 0.05).clamp(0.1, 1.0),
                ),
                onChanged: onInactiveOpacityChanged,
              ),

              const Divider(color: Colors.white10, height: 20),

              // Thời gian hiển thị
              _buildSettingRow(
                label: "Thời gian hiển thị:",
                value: "${displayDuration.toInt()} giây",
              ),
              _buildSliderRow(
                value: displayDuration,
                min: 1.0,
                max: 10.0,
                divisions: 9,
                onDecrement: () => onDisplayDurationChanged(
                  (displayDuration - 1).clamp(1.0, 10.0),
                ),
                onIncrement: () => onDisplayDurationChanged(
                  (displayDuration + 1).clamp(1.0, 10.0),
                ),
                onChanged: onDisplayDurationChanged,
              ),

              const Divider(color: Colors.white10, height: 20),

              // Thời gian thu gọn
              _buildSettingRow(
                label: "Thời gian thu gọn:",
                value: "${animDuration.toInt()} ms",
              ),
              _buildSliderRow(
                value: animDuration,
                min: 100.0,
                max: 1000.0,
                divisions: 18,
                onDecrement: () => onAnimDurationChanged(
                  (animDuration - 50).clamp(100.0, 1000.0),
                ),
                onIncrement: () => onAnimDurationChanged(
                  (animDuration + 50).clamp(100.0, 1000.0),
                ),
                onChanged: onAnimDurationChanged,
              ),

              const Divider(color: Colors.white10, height: 30),

              const Text(
                "Hiệu ứng chuyển cảnh",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 10),

              _buildSwitchRow(
                label: "Hiệu ứng nảy (Bouncy):",
                value: useBouncy,
                onChanged: onBouncyChanged,
              ),
              _buildSwitchRow(
                label: "Hiệu ứng phóng to (Scale):",
                value: useScale,
                onChanged: onScaleChanged,
              ),
              _buildSwitchRow(
                label: "Chuyển cảnh mượt (Fade):",
                value: useFade,
                onChanged: onFadeChanged,
              ),

              const SizedBox(height: 20),

              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: onResetToDefault,
                      icon: const Icon(Icons.refresh, size: 18),
                      label: const Text("Mặc định"),
                      style: OutlinedButton.styleFrom(
                        backgroundColor: const Color(
                          0xFF38BDF8,
                        ).withAlpha((0.1 * 255).toInt()),
                        foregroundColor: const Color(0xFF38BDF8),
                        side: const BorderSide(
                          color: Color(0xFF38BDF8),
                          width: 1,
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: onApply,
                      icon: const Icon(Icons.check_circle_outline, size: 18),
                      label: const Text("Áp dụng"),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(
                          0xFF38BDF8,
                        ).withAlpha((0.1 * 255).toInt()),
                        foregroundColor: const Color(0xFF38BDF8),
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(vertical: 12),
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
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSettingRow({required String label, required String value}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Text(
            label,
            style: const TextStyle(fontSize: 15, color: Colors.white70),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          value,
          style: const TextStyle(
            color: Color(0xFF38BDF8),
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildSliderRow({
    required double value,
    required double min,
    required double max,
    int? divisions,
    required VoidCallback onDecrement,
    required VoidCallback onIncrement,
    required Function(double) onChanged,
  }) {
    return Row(
      children: [
        IconButton(
          onPressed: onDecrement,
          icon: const Icon(Icons.remove_circle_outline, color: Colors.white54),
        ),
        Expanded(
          child: Slider(
            value: value,
            min: min,
            max: max,
            divisions: divisions,
            onChanged: onChanged,
            activeColor: const Color(0xFF38BDF8),
            inactiveColor: Colors.white10,
          ),
        ),
        IconButton(
          onPressed: onIncrement,
          icon: const Icon(Icons.add_circle_outline, color: Colors.white54),
        ),
      ],
    );
  }

  Widget _buildSwitchRow({
    required String label,
    required bool value,
    required Function(bool) onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 14, color: Colors.white70),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: const Color(0xFF38BDF8),
            activeTrackColor: const Color(0xFF38BDF8).withOpacity(0.3),
            inactiveThumbColor: Colors.white24,
            inactiveTrackColor: Colors.white12,
          ),
        ],
      ),
    );
  }
}
