import 'package:flutter/material.dart';
import 'dart:ui';

class UsageSuggestionsScreen extends StatelessWidget {
  const UsageSuggestionsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          "Gợi ý sử dụng",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionHeader("Thao tác với Bong bóng"),
            const SizedBox(height: 16),
            _buildTipCard(
              icon: Icons.touch_app,
              title: "Chạm 1 lần",
              description:
                  "Mở rộng thanh điều khiển để tăng/giảm âm lượng nhanh chóng.",
            ),
            _buildTipCard(
              icon: Icons.ads_click,
              title: "Chạm 2 lần",
              description: "Bật/Tắt chế độ im lặng (Mute) ngay lập tức.",
            ),
            _buildTipCard(
              icon: Icons.ads_click,
              title: "Nhấn giữ",
              description:
                  "Mở ứng dụng nghe nhạc bạn yêu thích (có thể tùy chỉnh trong cài đặt).",
            ),
            const SizedBox(height: 24),
            _buildSectionHeader("Thanh trạng thái (Quick Tile)"),
            const SizedBox(height: 16),
            _buildTipCard(
              icon: Icons.bolt,
              title: "Tiếp cận nhanh",
              description:
                  "Thêm nút gạt vào thanh trạng thái để bật/tắt bong bóng mà không cần mở app.",
            ),
            const SizedBox(height: 24),
            _buildSectionHeader("Mẹo thu gọn thông báo"),
            const SizedBox(height: 16),
            _buildTipCard(
              icon: Icons.notifications_off,
              title: "Ẩn thông báo hệ thống",
              description:
                  "Nhấn giữ vào thông báo 'Volume Bubble đang hiển thị...' -> Chọn 'Tắt thông báo' để thanh trạng thái gọn gàng hơn.",
            ),
            const SizedBox(height: 24),
            _buildSectionHeader("Lưu ý quan trọng"),
            const SizedBox(height: 16),
            _buildTipCard(
              icon: Icons.battery_saver,
              title: "Tối ưu pin",
              description:
                  "Nếu bong bóng tự biến mất, hãy kiểm tra cài đặt 'Tối ưu hóa pin' và chuyển sang 'Không hạn chế'.",
            ),
            _buildTipCard(
              icon: Icons.visibility,
              title: "Quyền hiển thị",
              description:
                  "Ứng dụng cần quyền 'Hiển thị trên các ứng dụng khác' để bong bóng có thể hoạt động.",
            ),
            const SizedBox(height: 32),
            const Center(
              child: Text(
                "Chúc bạn có trải nghiệm tuyệt vời!",
                style: TextStyle(
                  color: Colors.white54,
                  fontStyle: FontStyle.italic,
                  fontSize: 14,
                ),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.bold,
        color: Color(0xFF38BDF8),
      ),
    );
  }

  Widget _buildTipCard({
    required IconData icon,
    required String title,
    required String description,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withAlpha((0.05 * 255).toInt()),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: Colors.white.withAlpha((0.1 * 255).toInt()),
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(
                      0xFF38BDF8,
                    ).withAlpha((0.15 * 255).toInt()),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, color: const Color(0xFF38BDF8), size: 22),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        description,
                        style: const TextStyle(
                          fontSize: 15,
                          color: Colors.white70,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
