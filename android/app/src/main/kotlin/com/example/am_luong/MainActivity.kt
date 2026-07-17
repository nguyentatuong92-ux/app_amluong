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
import android.content.Intent
import android.graphics.Bitmap
import android.graphics.Canvas
import android.graphics.drawable.Drawable
import java.io.ByteArrayOutputStream
import android.Manifest


class MainActivity : FlutterActivity() {
    private val CHANNEL = "com.example.am_luong/tile"
    private var pendingNotificationResult: MethodChannel.Result? = null

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

                // [CẬP NHẬT] Lưu trạng thái vào SharedPreferences ngay khi gửi yêu cầu
                val prefs = getSharedPreferences("FlutterSharedPreferences", Context.MODE_PRIVATE)
                prefs.edit().putBoolean("flutter.isTileAdded", true).commit()

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
                prefs.edit().putBoolean("flutter.isTileAdded", false).commit()
                
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
            } else if (call.method == "requestNotificationPermission") {
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
                    if (android.os.Build.VERSION.SDK_INT >= 23 && checkSelfPermission(Manifest.permission.POST_NOTIFICATIONS) == PackageManager.PERMISSION_GRANTED) {
                        result.success(true)
                    } else if (android.os.Build.VERSION.SDK_INT >= 23) {
                        pendingNotificationResult = result
                        requestPermissions(arrayOf(Manifest.permission.POST_NOTIFICATIONS), 101)
                    } else {
                        result.success(true)
                    }
                } else {
                    result.success(true)
                }
            } else if (call.method == "getInstalledApps") {
                val pm = packageManager
                val intent = Intent(Intent.ACTION_MAIN, null)
                intent.addCategory(Intent.CATEGORY_LAUNCHER)
                val apps = pm.queryIntentActivities(intent, 0)
                val appList = mutableListOf<Map<String, Any>>()

                for (app in apps) {
                    val appInfo = mutableMapOf<String, Any>()
                    appInfo["name"] = app.loadLabel(pm).toString()
                    appInfo["packageName"] = app.activityInfo.packageName
                    
                    // Lấy icon
                    try {
                        val icon = app.loadIcon(pm)
                        val bitmap = drawableToBitmap(icon)
                        val stream = ByteArrayOutputStream()
                        bitmap.compress(Bitmap.CompressFormat.PNG, 100, stream)
                        appInfo["icon"] = stream.toByteArray()
                    } catch (e: Exception) {
                        // Bỏ qua icon nếu lỗi
                    }
                    
                    appList.add(appInfo)
                }
                result.success(appList)
            } else {
                result.notImplemented()
            }
        }
    }

    override fun onRequestPermissionsResult(requestCode: Int, permissions: Array<out String>, grantResults: IntArray) {
        super.onRequestPermissionsResult(requestCode, permissions, grantResults)
        if (requestCode == 101) {
            val isGranted = grantResults.isNotEmpty() && grantResults[0] == PackageManager.PERMISSION_GRANTED
            pendingNotificationResult?.success(isGranted)
            pendingNotificationResult = null
        }
    }

    private fun drawableToBitmap(drawable: Drawable): Bitmap {
        var width = drawable.intrinsicWidth
        var height = drawable.intrinsicHeight
        if (width <= 0) width = 100
        if (height <= 0) height = 100
        
        val bitmap = Bitmap.createBitmap(width, height, Bitmap.Config.ARGB_8888)
        val canvas = Canvas(bitmap)
        drawable.setBounds(0, 0, canvas.width, canvas.height)
        drawable.draw(canvas)
        return bitmap
    }
}
