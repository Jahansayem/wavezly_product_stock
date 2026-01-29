@echo off
setlocal enabledelayedexpansion

echo ========================================
echo Flutter Build and Run - Wavezly App
echo ========================================
echo.
echo Device: 192.168.8.210:34605
echo Package: com.inventory.management
echo Working Directory: %CD%
echo.

REM Check if we're in the right directory
if not exist "pubspec.yaml" (
    echo ERROR: Not in Flutter project directory!
    echo Please run this script from: warehouse_management\
    pause
    exit /b 1
)

echo [Step 1/5] Checking device connection...
adb devices | findstr "192.168.8.210:34605"
if errorlevel 1 (
    echo ERROR: Device not connected!
    echo Trying to reconnect...
    adb connect 192.168.8.210:34605
    timeout /t 2 > nul
)
echo ✓ Device connected
echo.

echo [Step 2/5] Cleaning previous build...
flutter clean
echo ✓ Clean complete
echo.

echo [Step 3/5] Getting dependencies...
flutter pub get
echo ✓ Dependencies ready
echo.

echo [Step 4/5] Building and installing app...
echo This may take 1-3 minutes for first build...
echo.
flutter run -d 192.168.8.210:34605

echo.
echo ========================================
echo Build Process Complete
echo ========================================
echo.
echo The app should be running on your device now.
echo Watch this console for debug logs.
echo.
echo When you navigate Login → OTP, you should see:
echo   ╔═══════════════════════════════════════════════════╗
echo   ║ 📱 NAVIGATING TO OTP SCREEN                      ║
echo   ╚═══════════════════════════════════════════════════╝
echo.
pause
