@echo off
title ME E-Commerce - Database Check & Server Launcher
color 0A

echo ========================================================
echo   ME E-Commerce - Pemeriksaan Database ^& Server
echo ========================================================
echo.

REM 1. Jalankan ADB Reverse secara otomatis jika adb tersedia
set ADB_PATH=%LOCALAPPDATA%\Android\Sdk\platform-tools\adb.exe
if exist "%ADB_PATH%" (
    echo [1/3] Menghubungkan ADB Reverse ke HP...
    "%ADB_PATH%" reverse tcp:8000 tcp:8000 >nul 2>&1
    if %errorlevel% equ 0 (
        echo      ^> Sukses! Port 8000 berhasil di-reverse ke HP.
    ) else (
        echo      ^> Info: HP belum terhubung via USB, atau USB debugging nonaktif.
    )
) else (
    echo [1/3] ADB tidak ditemukan di %ADB_PATH%.
)

echo.
echo [2/3] Memeriksa konfigurasi database Laravel...
echo.

cd /d "%~dp0backend"

if not exist ".env" (
    echo      ^> File backend\.env tidak ditemukan.
    echo      ^> Jalankan composer run setup dari folder backend terlebih dahulu.
    echo.
    pause
    exit /b 1
)

php artisan config:clear --no-ansi
if errorlevel 1 goto database_error

echo.
echo [3/3] Menguji koneksi database aktif...
php artisan db:show --no-ansi
if errorlevel 1 goto database_error

echo.
echo ========================================================
echo   Database terhubung. Server berjalan di Port 8000.
echo      - URL Lokal Laptop : http://127.0.0.1:8000
echo      - URL HP (USB ADB) : http://127.0.0.1:8000/api
echo      - URL HP (Wi-Fi)   : http://192.168.1.9:8000/api
echo.
echo ========================================================
echo   Server sedang berjalan. Tekan Ctrl+C untuk berhenti.
echo ========================================================
echo.

php artisan serve --host=0.0.0.0 --port=8000
exit /b %errorlevel%

:database_error
echo.
echo ========================================================
echo   Koneksi database gagal. Server tidak dijalankan.
echo.
echo   Untuk MySQL/Laragon:
echo   1. Buka Laragon dan klik Start All.
echo   2. Pastikan MySQL aktif pada host dan port di backend\.env.
echo   3. Pastikan database pada DB_DATABASE sudah dibuat.
echo   4. Jalankan file ini lagi; cache konfigurasi sudah dibersihkan.
echo.
echo   Periksa koneksi langsung dengan:
echo   cd /d "%~dp0backend"
echo   php artisan db:show
echo ========================================================
echo.
pause
exit /b 1
