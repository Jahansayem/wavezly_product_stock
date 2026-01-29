@echo off
set JAVA_HOME=C:\Program Files\Eclipse Adoptium\jdk-21.0.8.9-hotspot
set PATH=%JAVA_HOME%\bin;%PATH%

echo JAVA_HOME set to: %JAVA_HOME%
echo.
echo Starting Flutter...
echo.

cd /d "%~dp0"
flutter run -d 192.168.8.210:35577
