@echo off
where flutter >nul 2>nul
if errorlevel 1 (
  echo Flutter is not installed or not in PATH.
  pause
  exit /b 1
)
cd /d %~dp0
if not exist fakhar_fiverr_app flutter create fakhar_fiverr_app
copy /Y flutter_app\lib\main.dart fakhar_fiverr_app\lib\main.dart
cd fakhar_fiverr_app
flutter pub add http
flutter run -d windows
pause
