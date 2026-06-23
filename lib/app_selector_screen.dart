import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:typed_data';

class AppSelectorScreen extends StatefulWidget {
  const AppSelectorScreen({super.key});

  @override
  State<AppSelectorScreen> createState() => _AppSelectorScreenState();
}

class _AppSelectorScreenState extends State<AppSelectorScreen> {
  static const platform = MethodChannel('com.example.am_luong/tile');
  List<Map<dynamic, dynamic>> _allApps = [];
  List<Map<dynamic, dynamic>> _filteredApps = [];
  bool _isLoading = true;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadApps();
  }

  Future<void> _loadApps() async {
    try {
      final List<dynamic> apps = await platform.invokeMethod(
        'getInstalledApps',
      );
      if (mounted) {
        setState(() {
          _allApps = apps.map((e) => e as Map<dynamic, dynamic>).toList();
          _allApps.sort(
            (a, b) => (a['name'] as String).toLowerCase().compareTo(
              (b['name'] as String).toLowerCase(),
            ),
          );
          _filteredApps = _allApps;
          _isLoading = false;
        });
      }
    } on PlatformException catch (e) {
      debugPrint("Lỗi tải app: ${e.message}");
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _filterApps(String query) {
    setState(() {
      _filteredApps = _allApps
          .where(
            (app) =>
                (app['name'] as String).toLowerCase().contains(
                  query.toLowerCase(),
                ) ||
                (app['packageName'] as String).toLowerCase().contains(
                  query.toLowerCase(),
                ),
          )
          .toList();
    });
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
          "Chọn ứng dụng",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              onChanged: _filterApps,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: "Tìm kiếm ứng dụng...",
                hintStyle: const TextStyle(color: Colors.white38),
                prefixIcon: const Icon(Icons.search, color: Colors.white38),
                filled: true,
                fillColor: Colors.white.withOpacity(0.05),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 0),
              ),
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(color: Color(0xFF38BDF8)),
                  )
                : _filteredApps.isEmpty
                ? const Center(
                    child: Text(
                      "Không tìm thấy ứng dụng nào",
                      style: TextStyle(color: Colors.white54),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: _filteredApps.length,
                    itemBuilder: (context, index) {
                      final app = _filteredApps[index];
                      return Card(
                        color: Colors.white.withOpacity(0.03),
                        margin: const EdgeInsets.only(bottom: 8),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: ListTile(
                          onTap: () => Navigator.pop(context, app),
                          leading: app['icon'] != null
                              ? Image.memory(
                                  app['icon'] as Uint8List,
                                  width: 40,
                                  height: 40,
                                  errorBuilder: (context, error, stackTrace) =>
                                      const Icon(
                                        Icons.android,
                                        color: Colors.white24,
                                      ),
                                )
                              : const Icon(
                                  Icons.android,
                                  color: Colors.white24,
                                ),
                          title: Text(
                            app['name'] ?? "Không tên",
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          subtitle: Text(
                            app['packageName'] ?? "",
                            style: const TextStyle(
                              color: Colors.white38,
                              fontSize: 12,
                            ),
                          ),
                          trailing: const Icon(
                            Icons.chevron_right,
                            color: Colors.white24,
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
