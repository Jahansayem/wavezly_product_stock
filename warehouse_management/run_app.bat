@echo off
cd /d "%~dp0"
flutter run -d 192.168.8.210:35577 > flutter_run_output.log 2>&1
