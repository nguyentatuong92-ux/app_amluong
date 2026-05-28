import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_volume_controller/flutter_volume_controller.dart';

// ==========================================
// WIDGET BONG BÓNG TRÔI NỔI (CHẠY NỀN OVERLAY)
// ==========================================
class VolumeBubbleOverlay extends StatefulWidget {
  const VolumeBubbleOverlay({super.key});

  @override
  State<VolumeBubbleOverlay> createState() => _VolumeBubbleOverlayState();
}

class _VolumeBubbleOverlayState extends State<VolumeBubbleOverlay> {
  double _volumeValue = 0.0;
  bool _isExpanded = false;
  Timer? _collapseTimer;

  // --- ĐÃ ĐIỀU CHỈNH KÍCH THƯỚC CHO ĐIỆN THOẠI THẬT ---
  final double _bubbleSize =
      68.0; // Tăng từ 56 lên 68 để chứa đủ chữ không bị rớt dòng
  final double _expandedHeight = 180.0; // Tăng chiều cao tương ứng
  // ----------------------------------------------

  @override
  void initState() {
    super.initState();
    _fetchAndListenVolume();
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
        setState(() {
          _isExpanded = false;
        });
      }
    });
  }

  void _increaseVolume() {
    double nVol = (_volumeValue + 0.07).clamp(0.0, 1.0);
    FlutterVolumeController.setVolume(nVol, stream: AudioStream.music);
    setState(() {
      _volumeValue = nVol;
    });
    _resetTimer();
  }

  void _decreaseVolume() {
    double nVol = (_volumeValue - 0.07).clamp(0.0, 1.0);
    FlutterVolumeController.setVolume(nVol, stream: AudioStream.music);
    setState(() {
      _volumeValue = nVol;
    });
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
      child: Center(
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOutCubic,
          width: _bubbleSize,
          height: _isExpanded ? _expandedHeight : _bubbleSize,
          decoration: BoxDecoration(
            // ĐÃ LÀM MỜ THÊM: Giảm từ 0.85 xuống 0.60
            color: const Color(0xFF0F172A).withOpacity(0.5),
            borderRadius: BorderRadius.circular(100),
            border: Border.all(
              color: const Color(0xFF38BDF8).withOpacity(0.3),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.15), // Làm bóng mờ nhạt hơn
                blurRadius: 8,
                spreadRadius: 1,
              ),
            ],
          ),
          clipBehavior: Clip.antiAlias,
          child: _isExpanded
              ? _buildExpandedToolbar()
              : _buildCollapsedCircularBubble(volPercentage),
        ),
      ),
    );
  }

  // GIAO DIỆN BONG BÓNG THU GỌN
  Widget _buildCollapsedCircularBubble(int volPercentage) {
    return GestureDetector(
      onTap: () {
        setState(() {
          _isExpanded = true;
        });
        _resetTimer();
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
              color: const Color(0xFF38BDF8),
              backgroundColor: Colors.transparent,
            ),
          ),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                volPercentage == 0
                    ? Icons.volume_mute
                    : Icons.volume_up_rounded,
                color: Colors.white,
                size: 18,
              ),
              const SizedBox(height: 2),
              // Ép chữ không rớt dòng bằng FittedBox
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  "$volPercentage%",
                  textAlign: TextAlign.center,
                  maxLines: 1, // Bắt buộc nằm trên 1 dòng
                  style: const TextStyle(
                    color: Color(0xFF38BDF8),
                    fontSize: 12,
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

  // GIAO DIỆN THANH CHỈNH DỌC
  Widget _buildExpandedToolbar() {
    int volPercentage = (_volumeValue * 100).toInt();

    return SingleChildScrollView(
      physics: const NeverScrollableScrollPhysics(),
      child: SizedBox(
        height: _expandedHeight,
        child: Column(
          children: [
            GestureDetector(
              onTap: _increaseVolume,
              behavior: HitTestBehavior.opaque,
              child: SizedBox(
                width: _bubbleSize,
                height: 56, // Tăng vùng chạm
                child: const Icon(
                  Icons.add,
                  color: Color(0xFF4ADE80),
                  size: 28,
                ),
              ),
            ),
            // DÙNG EXPANDED KẾT HỢP CENTER ĐỂ CĂN GIỮA TUYỆT ĐỐI
            Expanded(
              child: Center(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    "$volPercentage%",
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    style: const TextStyle(
                      color: Color(0xFF38BDF8),
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
            GestureDetector(
              onTap: _decreaseVolume,
              behavior: HitTestBehavior.opaque,
              child: SizedBox(
                width: _bubbleSize,
                height: 56, // Tăng vùng chạm
                child: const Icon(
                  Icons.remove,
                  color: Color(0xFFF87171),
                  size: 28,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
