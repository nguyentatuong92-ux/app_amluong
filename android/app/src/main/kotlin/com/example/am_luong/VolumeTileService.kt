package com.example.am_luong

import android.content.Context
import android.content.Intent
import android.service.quicksettings.Tile
import android.service.quicksettings.TileService
import io.flutter.embedding.engine.FlutterEngineCache
import io.flutter.plugin.common.MethodChannel
import android.util.Log

class VolumeTileService : TileService() {
    private val CHANNEL = "com.example.am_luong/tile"
    private val PREFS_NAME = "FlutterSharedPreferences"
    private val KEY_TILE_ADDED = "flutter.isTileAdded"

    override fun onTileAdded() {
        super.onTileAdded()
        Log.d("VolumeTileService", "Tile added")
        saveTileStatus(true)
    }

    override fun onTileRemoved() {
        super.onTileRemoved()
        Log.d("VolumeTileService", "Tile removed")
        saveTileStatus(false)
    }

    private fun saveTileStatus(isAdded: Boolean) {
        val prefs = getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
        prefs.edit().putBoolean(KEY_TILE_ADDED, isAdded).apply()
    }

    override fun onClick() {
        super.onClick()
        Log.d("VolumeTileService", "Tile clicked")
        
        // 1. Phản hồi giao diện ngay lập tức để tránh cảm giác bị ngược
        val tile = qsTile ?: return
        val isCurrentlyActive = (tile.state == Tile.STATE_ACTIVE)
        tile.state = if (isCurrentlyActive) Tile.STATE_INACTIVE else Tile.STATE_ACTIVE
        tile.updateTile()

        // 2. Gửi lệnh xuống Flutter để xử lý logic thực tế
        val engine = FlutterEngineCache.getInstance().get("my_engine_id")
        if (engine != null) {
            val messenger = engine.dartExecutor.binaryMessenger
            MethodChannel(messenger, CHANNEL).invokeMethod("toggleBubble", null)
        } else {
            Log.d("VolumeTileService", "Engine not found, launching app")
            val intent = packageManager.getLaunchIntentForPackage(packageName)
            intent?.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
            startActivityAndCollapse(intent)
        }
    }

    override fun onStartListening() {
        super.onStartListening()
        Log.d("VolumeTileService", "Start listening")
        saveTileStatus(true) // Khi tile bắt đầu lắng nghe, nghĩa là nó đang hiện diện
        updateTileState()
    }

    private fun updateTileState() {
        val tile = qsTile ?: return
        
        // Gửi yêu cầu hỏi Flutter xem bong bóng có đang bật không
        val engine = FlutterEngineCache.getInstance().get("my_engine_id")
        if (engine != null) {
            val messenger = engine.dartExecutor.binaryMessenger
            MethodChannel(messenger, CHANNEL).invokeMethod("checkStatus", null, object : MethodChannel.Result {
                override fun success(result: Any?) {
                    val isActive = result as? Boolean ?: false
                    tile.state = if (isActive) Tile.STATE_ACTIVE else Tile.STATE_INACTIVE
                    tile.updateTile()
                }
                override fun error(errorCode: String, errorMessage: String?, errorDetails: Any?) {
                    tile.state = Tile.STATE_INACTIVE
                    tile.updateTile()
                }
                override fun notImplemented() {
                    tile.state = Tile.STATE_INACTIVE
                    tile.updateTile()
                }
            })
        } else {
            tile.state = Tile.STATE_INACTIVE
            tile.updateTile()
        }
    }
}
