import 'dart:io';
import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:open_filex/open_filex.dart';
import 'package:package_info_plus/package_info_plus.dart';

class UpdateHelper {
  static const String _githubApiUrl =
      "https://api.github.com/repos/nguyentatuong92-ux/app_amluong/releases/latest";

  // [ĐÃ SỬA] Thay Future<void> thành Future<bool>
  static Future<bool> checkForUpdates(
    BuildContext context, {
    bool showMessage = false,
  }) async {
    try {
      if (showMessage) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: const Color(0xFF64B5F6),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15.0),
            ),
            content: const Text(
              "Đang kiểm tra cập nhật...",
              style: TextStyle(fontSize: 20),
            ),
            duration: const Duration(seconds: 1),
          ),
        );
      }

      PackageInfo packageInfo = await PackageInfo.fromPlatform();
      String currentVersion = packageInfo.version;

      final response = await Dio().get(_githubApiUrl);

      if (response.statusCode == 200) {
        String latestVersion = response.data['tag_name'].toString().replaceAll(
          'v',
          '',
        );

        List assets = response.data['assets'];
        String? apkDownloadUrl;
        for (var asset in assets) {
          if (asset['name'].toString().endsWith('.apk')) {
            apkDownloadUrl = asset['browser_download_url'];
            break;
          }
        }

        bool isUpdateAvailable = _isNewVersionGreater(
          currentVersion,
          latestVersion,
        );

        if (isUpdateAvailable && apkDownloadUrl != null) {
          if (context.mounted) {
            _showUpdateDialog(context, latestVersion, apkDownloadUrl);
          }
          // [MỚI THÊM] Báo về là CÓ cập nhật
          return true;
        } else if (showMessage && context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              backgroundColor: const Color(0xFF64B5F6),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15.0),
              ),
              content: const Text(
                "Bạn đang dùng phiên bản mới nhất!",
                style: TextStyle(fontSize: 20),
              ),
            ),
          );
        }
      }
      // [MỚI THÊM] Báo về là KHÔNG có cập nhật
      return false;
    } catch (e) {
      debugPrint("Lỗi kiểm tra cập nhật: $e");
      if (showMessage && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: const Color(0xFF64B5F6),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15.0),
            ),
            content: const Text(
              "Không thể kiểm tra cập nhật lúc này.",
              style: TextStyle(fontSize: 20),
            ),
          ),
        );
      }
      // [MỚI THÊM] Báo về là KHÔNG có cập nhật (do lỗi)
      return false;
    }
  }

  static bool _isNewVersionGreater(String current, String latest) {
    List<int> currentParts = current
        .split('.')
        .map((s) => int.tryParse(s) ?? 0)
        .toList();
    List<int> latestParts = latest
        .split('.')
        .map((s) => int.tryParse(s) ?? 0)
        .toList();

    int maxLength = currentParts.length > latestParts.length
        ? currentParts.length
        : latestParts.length;
    while (currentParts.length < maxLength) currentParts.add(0);
    while (latestParts.length < maxLength) latestParts.add(0);

    for (int i = 0; i < maxLength; i++) {
      if (latestParts[i] > currentParts[i]) {
        return true;
      }
      if (latestParts[i] < currentParts[i]) {
        return false;
      }
    }

    return false;
  }

  static void _showUpdateDialog(
    BuildContext context,
    String newVersion,
    String url,
  ) {
    showDialog(
      context: context,
      barrierDismissible: false,
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
                Navigator.pop(context);
                _downloadAndInstall(context, url);
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
    ValueNotifier<double> progress = ValueNotifier(0.0);
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF1E293B),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15.0),
          ),
          title: Text(
            "Đang tải bản cập nhật...",
            style: const TextStyle(color: Colors.white, fontSize: 16),
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
      Directory tempDir = await getTemporaryDirectory();
      String savePath = "${tempDir.path}/update.apk";

      await Dio().download(
        url,
        savePath,
        onReceiveProgress: (received, total) {
          if (total != -1) {
            progress.value = received / total;
          }
        },
      );

      if (context.mounted) {
        Navigator.pop(context);
      }

      await OpenFilex.open(savePath);
    } catch (e) {
      debugPrint("Lỗi tải file: $e");
      if (context.mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: const Color(0xFF64B5F6),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15.0),
            ),
            content: const Text("Lỗi tải xuống! Vui lòng kiểm tra lại mạng."),
          ),
        );
      }
    }
  }
}
