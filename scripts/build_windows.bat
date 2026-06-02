@echo off
REM Build script for Caisse POS Windows Installer
REM Prerequisites: Flutter SDK, Visual Studio Build Tools, Inno Setup

echo ============================================
echo   Caisse POS - Windows Build Script
echo ============================================
echo.

REM Check if Flutter is installed
where flutter >nul 2>nul
if %ERRORLEVEL% NEQ 0 (
    echo [ERROR] Flutter not found in PATH. Please install Flutter SDK.
    exit /b 1
)

echo [1/4] Getting Flutter dependencies...
call flutter pub get
if %ERRORLEVEL% NEQ 0 (
    echo [ERROR] Failed to get dependencies
    exit /b 1
)

echo.
echo [2/4] Building Windows release...
call flutter build windows --release
if %ERRORLEVEL% NEQ 0 (
    echo [ERROR] Build failed
    exit /b 1
)

echo.
echo [3/4] Checking build output...
if not exist "build\windows\x64\runner\Release\caisse_1.exe" (
    echo [ERROR] Executable not found after build
    exit /b 1
)
echo [OK] Build successful: build\windows\x64\runner\Release\caisse_1.exe

echo.
echo [4/4] Creating installer with Inno Setup...
where iscc >nul 2>nul
if %ERRORLEVEL% NEQ 0 (
    echo [WARNING] Inno Setup Compiler (iscc) not found in PATH
    echo [INFO] Installer not created. To create installer:
    echo        1. Install Inno Setup from https://jrsoftware.org/isdl.php
    echo        2. Add to PATH or run:
    echo        "C:\Program Files (x86)\Inno Setup 6\ISCC.exe" scripts\installer.iss
    goto shortcuts
)

call iscc.exe "scripts\installer.iss"
if %ERRORLEVEL% NEQ 0 (
    echo [WARNING] Inno Setup compilation failed
    goto shortcuts
)

echo [OK] Installer created: build\windows\installer\CaissePOS-Setup-*.exe

:shortcuts
echo.
echo [INFO] Creating desktop shortcuts...
powershell -ExecutionPolicy Bypass -File scripts\create_shortcut_win.ps1

echo.
echo ============================================
echo   Build completed successfully!
echo ============================================
echo.
echo Output files:
echo   - Executable: build\windows\x64\runner\Release\caisse_1.exe
echo   - Installer:  build\windows\installer\CaissePOS-Setup-1.0.0.exe
echo.
pause
