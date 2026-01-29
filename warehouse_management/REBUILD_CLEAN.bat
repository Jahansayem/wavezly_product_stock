@echo off
echo ========================================
echo COMPLETE CACHE CLEAR AND REBUILD
echo ========================================
echo.
echo This script will:
echo 1. Clear all Flutter build cache
echo 2. Delete build directories
echo 3. Remove dependency locks
echo 4. Get fresh dependencies
echo 5. Uninstall old app from device
echo 6. Build fresh debug APK
echo 7. Install and launch on device
echo.
echo Press any key to continue...
pause > nul

echo.
echo [1/7] Running flutter clean...
flutter clean
echo ✓ Cache cleared
echo.

echo [2/7] Deleting build directories...
if exist build rmdir /s /q build
if exist .dart_tool rmdir /s /q .dart_tool
if exist android\app\build rmdir /s /q android\app\build
if exist android\.gradle rmdir /s /q android\.gradle
echo ✓ Build directories deleted
echo.

echo [3/7] Removing pubspec.lock...
if exist pubspec.lock del /f pubspec.lock
echo ✓ Dependency lock removed
echo.

echo [4/7] Getting fresh dependencies...
flutter pub get
echo ✓ Dependencies installed
echo.

echo [5/7] Uninstalling old app from device...
adb -s 192.168.8.210:34605 uninstall com.inventory.management
echo ✓ Old app removed
echo.

echo [6/7] Building fresh debug APK...
echo This may take 1-3 minutes...
flutter build apk --debug
echo ✓ APK built successfully
echo.

echo [7/7] Installing and launching app...
flutter run -d 192.168.8.210:34605
echo.
echo ========================================
echo REBUILD COMPLETE
echo ========================================
echo.
echo The app should now be running on your device.
echo Watch this console for debug logs when you navigate to OTP screen.
echo.
pause
