@echo off
setlocal
if defined JAVA_HOME if exist "%JAVA_HOME%\bin\java.exe" goto java_ready
set "JAVA_HOME="
for /d %%D in ("%ProgramFiles%\Eclipse Adoptium\jdk-*") do if exist "%%~fD\bin\java.exe" set "JAVA_HOME=%%~fD"
if not defined JAVA_HOME if exist "%ProgramFiles%\Android\Android Studio\jbr\bin\java.exe" set "JAVA_HOME=%ProgramFiles%\Android\Android Studio\jbr"
if not defined JAVA_HOME (
  echo ERROR: No usable JDK was found. Install JDK 17 or newer.
  exit /b 1
)
:java_ready
set "PATH=%JAVA_HOME%\bin;%PATH%"
echo Starting Flutter...
C:\flutter\bin\flutter.bat run -d 192.168.8.210:35577
pause
