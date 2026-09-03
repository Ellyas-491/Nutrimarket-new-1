@echo off
echo ========================================
echo   Clev AI - Setup Flutter Project
echo ========================================
echo.

where flutter >nul 2>&1
if %ERRORLEVEL% neq 0 (
    echo [ERROR] Flutter belum terinstall!
    echo Download dari: https://docs.flutter.dev/get-started/install/windows
    pause
    exit /b 1
)

echo [1/3] Melengkapi file platform Flutter...
flutter create . --org com.clevai

echo.
echo [2/3] Install dependencies...
flutter pub get

echo.
echo [3/3] Cek environment...
flutter doctor

echo.
echo ========================================
echo   Setup selesai!
echo.
echo   Langkah selanjutnya:
echo   1. Edit file .env - masukkan GROQ_API_KEY
echo   2. Jalankan: flutter run
echo   3. Build APK: flutter build apk --release
echo ========================================
pause
