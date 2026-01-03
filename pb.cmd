@echo off
REM PacketBuddy CLI Shortcut for Windows
REM This allows you to use 'pb' from anywhere

REM Get the directory where this script is located
set SCRIPT_DIR=%~dp0
set PROJECT_DIR=%SCRIPT_DIR:~0,-1%

REM Activate venv and run CLI
cd /d "%PROJECT_DIR%"
call "%PROJECT_DIR%\venv\Scripts\activate.bat" >nul 2>&1
set PYTHONPATH=%PROJECT_DIR%;%PYTHONPATH%
python -m src.cli.main %*
