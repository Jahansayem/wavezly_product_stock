@echo off
echo Running Flutter...
echo.
cd /d "%~dp0"
C:\flutter\bin\flutter run -d 192.168.8.210:35577 2>&1 | tee flutter_run.log
