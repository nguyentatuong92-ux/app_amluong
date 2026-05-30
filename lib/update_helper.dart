import 'dart:io';
import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:open_filex/open_filex.dart';
import 'package:package_info_plus/package_info_plus.dart';

class UpdateHelper {
  // Đã sửa thành đường dẫn API chuẩn của GitHub để lấy bản Release mới nhất
  static const String _githubApiUrl =
      "https://github.com/nguyentatuong92-ux/app_amluong.git";

  static Future<void> checkForUpdates(
    BuildContext context, {
    bool showMessage = false,
  }) async {
    try {
      if (showMessage) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Đang kiểm tra cập nhật..."),
            duration: Duration(seconds: 1),
          ),
        );
      }

      // 1. Lấy phiên bản hiện tại của app (ví dụ: 1.0.0)
      PackageInfo packageInfo = await PackageInfo.fromPlatform();
      String currentVersion = packageInfo.version;

      // 2. Lấy thông tin bản phát hành mới nhất từ GitHub API
      final response = await Dio().get(_githubApiUrl);

      if (response.statusCode == 200) {
        // Tag trên github thường có chữ 'v' (vd: v1.0.2), ta cắt bỏ chữ 'v' để so sánh
        String latestVersion = response.data['tag_name'].toString().replaceAll(
          'v',
          '',
        );

        // Lấy link tải file APK đính kèm (ưu tiên file .apk đầu tiên tìm thấy)
        List assets = response.data['assets'];
        String? apkDownloadUrl;
        for (var asset in assets) {
          if (asset['name'].toString().endsWith('.apk')) {
            apkDownloadUrl = asset['browser_download_url'];
            break;
          }
        }

        // 3. So sánh phiên bản (Cách so sánh chuỗi đơn giản)
        if (latestVersion != currentVersion && apkDownloadUrl != null) {
          if (context.mounted) {
            _showUpdateDialog(context, latestVersion, apkDownloadUrl);
          }
        } else if (showMessage && context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Bạn đang dùng phiên bản mới nhất!")),
          );
        }
      }
    } catch (e) {
      debugPrint("Lỗi kiểm tra cập nhật: $e");
      if (showMessage && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Không thể kiểm tra cập nhật lúc này.")),
        );
      }
    }
  }

  static void _showUpdateDialog(
    BuildContext context,
    String newVersion,
    String url,
  ) {
    showDialog(
      context: context,
      barrierDismissible: false, // Bắt buộc người dùng phải chọn
      builder: (context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF1E293B),
          title: const Text(
            "Cập nhật mới!",
            style: TextStyle(color: Colors.white),
          ),
          content: Text(
            "Đã có phiên bản $newVersion.\nBạn có muốn tải về và cài đặt ngay không?",
            style: const TextStyle(color: Colors.white70),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Để sau", style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF38BDF8),
              ),
              onPressed: () {
                Navigator.pop(context); // Tắt bảng hỏi
                _downloadAndInstall(context, url); // Bắt đầu tải
              },
              child: const Text(
                "Cập nhật ngay",
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        );
      },
    );
  }

  static Future<void> _downloadAndInstall(
    BuildContext context,
    String url,
  ) async {
    // Hiện bảng tiến trình tải
    ValueNotifier<double> progress = ValueNotifier(0.0);
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF1E293B),
          title: const Text(
            "Đang tải bản cập nhật...",
            style: TextStyle(color: Colors.white, fontSize: 16),
          ),
          content: ValueListenableBuilder<double>(
            valueListenable: progress,
            builder: (context, value, child) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  LinearProgressIndicator(
                    value: value,
                    color: const Color(0xFF38BDF8),
                    backgroundColor: Colors.white10,
                  ),
                  const SizedBox(height: 10),
                  Text(
                    "${(value * 100).toStringAsFixed(0)}%",
                    style: const TextStyle(color: Colors.white),
                  ),
                ],
              );
            },
          ),
        );
      },
    );

    try {
      // Tìm thư mục lưu tạm trên điện thoại
      Directory tempDir = await getTemporaryDirectory();
      String savePath = "${tempDir.path}/update.apk";

      // Tải file
      await Dio().download(
        url,
        savePath,
        onReceiveProgress: (received, total) {
          if (total != -1) {
            progress.value = received / total;
          }
        },
      );

      // Tải xong, tắt bảng tiến trình
      if (context.mounted) {
        Navigator.pop(context);
      }

      // Kích hoạt bộ cài đặt của Android
      await OpenFilex.open(savePath);
    } catch (e) {
      debugPrint("Lỗi tải file: $e");
      if (context.mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Lỗi tải xuống! Vui lòng kiểm tra lại mạng."),
          ),
        );
      }
    }
  }
}
