# Implementation Plan - Fix Tile Switch Synchronization

The "Add Tile" switch in the Dashboard screen currently experiences a "snap-back" effect where it reverts to the "Off" state even after successfully requesting to add the tile. This is caused by the `SharedPreferences` cache in Flutter not being updated when the native Android code writes to the same preference file.

## Proposed Changes

### Native Side (Android)

Ensure that tile status updates are written to disk immediately so that the Flutter side can read them accurately.

#### [MainActivity.kt](file:///C:/am_luong/android/app/src/main/kotlin/com/example/am_luong/MainActivity.kt)
- Change `apply()` to `commit()` when saving `flutter.isTileAdded` to ensure it is written to disk before the MethodChannel returns.

#### [VolumeTileService.kt](file:///C:/am_luong/android/app/src/main/kotlin/com/example/am_luong/VolumeTileService.kt)
- Change `apply()` to `commit()` in `saveTileStatus` for consistency.

---

### Flutter Side

Ensure the `SharedPreferences` cache is reloaded and the UI state is managed more robustly.

#### [dashboard_screen.dart](file:///C:/am_luong/lib/dashboard_screen.dart)
- Update `_loadSettings()` to call `await prefs.reload()` before reading values.
- Refactor the `Switch.onChanged` logic:
    - Update `_isTileAdded` immediately for UI responsiveness.
    - Call the native method and await its completion.
    - Force a `_loadSettings()` call (which now includes `reload()`) to sync with the final state.
    - Add proper error handling to rollback the switch state if the native call fails.
- Remove redundant `Future.delayed` and manual state toggling that conflicts with `_loadSettings()`.

## Verification Plan

### Manual Verification
1. Open the app and toggle the "Thêm nút gạt" (Add Tile) switch.
2. Verify that the switch stays in the "On" state and the snackbar appears.
3. Check the Quick Settings panel to see if the "Volume Bubble" tile is present (or a request dialog appears on Android 13+).
4. Remove the tile manually from the Quick Settings panel.
5. Re-open the app (or trigger a refresh) and verify the switch is now "Off".
6. Toggle the switch "Off" in the app and verify the tile is removed from the Quick Settings panel.
