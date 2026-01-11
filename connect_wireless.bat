@echo off
echo Pairing with device...
echo 955612 | adb pair 192.168.8.243:33059
timeout /t 2 /nobreak >nul
echo.
echo Connecting to device...
adb connect 192.168.8.243:43731
echo.
echo Checking connected devices...
adb devices
echo.
echo Done! You can now run: flutter run
pause
