@echo off
title ME E-Commerce - Server & ADB Reverse Auto Launcher
color 0A

echo ========================================================
echo   ME E-Commerce - Otomatisasi ADB Reverse ^& Server
echo ========================================================
echo.

REM 1. Jalankan ADB Reverse secara otomatis jika adb tersedia
set ADB_PATH=%LOCALAPPDATA%\Android\Sdk\platform-tools\adb.exe
if exist "%ADB_PATH%" (
    echo [1/2] Menghubungkan ADB Reverse ke HP...
    "%ADB_PATH%" reverse tcp:8000 tcp:8000 >nul 2>&1
    if %errorlevel% equ 0 (
        echo      ^> Sukses! Port 8000 berhasil di-reverse ke HP.
    ) else (
        echo      ^> Info: HP belum terhubung via USB, atau USB debugging nonaktif.
    )
) else (
    echo [1/2] ADB tidak ditemukan di %ADB_PATH%.
)

echo.
echo [2/2] Menjalankan Laravel Backend Server (Port 8000)...
echo.
echo      - URL Lokal Laptop : http://127.0.0.1:8000
echo      - URL HP (USB ADB) : http://127.0.0.1:8000/api
echo      - URL HP (Wi-Fi)   : http://192.168.1.9:8000/api
echo.
echo ========================================================
echo   Server sedang berjalan. Tekan Ctrl+C untuk berhenti.
echo ========================================================
echo.

cd /d "%~dp0backend"
php artisan serve --host=0.0.0.0 --port=8000
