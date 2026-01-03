@echo off
REM PacketBuddy Service Starter
REM This starts the background monitor in headless mode

set "SCRIPT_DIR=%~dp0"
cd /d "%SCRIPT_DIR%"

if exist "pb.cmd" (
    call pb.cmd service start
) else (
    echo Error: pb.cmd not found. Please run service\windows\setup.bat first.
    pause
)
