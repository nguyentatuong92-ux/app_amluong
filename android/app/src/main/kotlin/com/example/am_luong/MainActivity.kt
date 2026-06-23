package com.example.am_luong

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.embedding.engine.FlutterEngineCache
import io.flutter.plugin.common.MethodChannel
import android.app.StatusBarManager
import android.content.ComponentName
import android.graphics.drawable.Icon
import android.os.Build
import android.content.Context
import android.service.quicksettings.TileService
import android.content.pm.PackageManager
import android.os.PowerManager

class MainActivity : FlutterActivity() {
    private val CHANNEL = "com.example.am_luong/tile"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        // Cache the FlutterEngine to be used by TileService
        FlutterEngineCache
            .getInstance()
            .put("my_engine_id", flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            val componentName = ComponentName(this, VolumeTileService::class.java)

            if (call.method == "requestAddTile") {
                // Trước khi thêm, phải đảm bảo Component đã được BẬT
                packageManager.setComponentEnabledSetting(
                    componentName,
                    PackageManager.COMPONENT_ENABLED_STATE_ENABLED,
                    PackageManager.DONT_KILL_APP
                )

                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
                    val statusBarManager = getSystemService(Context.STATUS_BAR_SERVICE) as StatusBarManager
                    statusBarManager.requestAddTileService(
                        componentName,
                        "Volume Bubble",
                        Icon.createWithResource(this, R.mipmap.ic_launcher),
                        { it.run() },
                        {}
                    )
                    result.success(null)
                } else {
                    result.error("UNSUPPORTED", "Yêu cầu thêm Tile chỉ hỗ trợ từ Android 13 trở lên", null)
                }
            } else if (call.method == "removeTile") {
                // VÔ HIỆU HÓA Component để hệ thống tự xóa Tile khỏi thanh trạng thái
                packageManager.setComponentEnabledSetting(
                    componentName,
                    PackageManager.COMPONENT_ENABLED_STATE_DISABLED,
                    PackageManager.DONT_KILL_APP
                )
                
                // Cập nhật lại SharedPreferences để Flutter biết là đã xóa
                val prefs = getSharedPreferences("FlutterSharedPreferences", Context.MODE_PRIVATE)
                prefs.edit().putBoolean("flutter.isTileAdded", false).apply()
                
                result.success(null)
            } else if (call.method == "updateTileUI") {
                // Lệnh yêu cầu hệ thống cập nhật lại trạng thái nút gạt
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.N) {
                    TileService.requestListeningState(this, ComponentName(this, VolumeTileService::class.java))
                }
                result.success(null)
            } else if (call.method == "checkBatteryOptimization") {
                val powerManager = getSystemService(Context.POWER_SERVICE) as PowerManager
                val isIgnoring = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                    powerManager.isIgnoringBatteryOptimizations(packageName)
                } else {
                    true
                }
                result.success(isIgnoring)
            } else {
                result.notImplemented()
            }
        }
    }
}
