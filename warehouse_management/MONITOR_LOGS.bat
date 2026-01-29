@echo off
echo ========================================
echo OTP Screen Debug Log Monitor
echo ========================================
echo.
echo Monitoring device: 192.168.8.210:34605
echo Package: com.inventory.management
echo.
echo Waiting for OTP navigation debug logs...
echo.
echo Instructions:
echo 1. Make sure the app is running on your device
echo 2. Navigate: Login screen → Enter phone → Click "এগিয়ে যান"
echo 3. Watch for debug logs below
echo.
echo ----------------------------------------
echo.

adb -s 192.168.8.210:34605 logcat -s flutter:V | findstr /C:"NAVIGATING" /C:"OPENED CORRECT" /C:"OTP" /C:"Phone:"

pause
