@echo off
echo ========================================
echo Flutter OTP Debug Test
echo ========================================
echo.
echo This will:
echo 1. Rebuild and install the app
echo 2. Show debug logs in console
echo 3. Monitor OTP screen navigation
echo.
echo Press any key to start...
pause > nul

echo.
echo Starting Flutter...
echo.

flutter run -d 192.168.8.210:34605

pause
