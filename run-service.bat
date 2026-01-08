@echo off
REM PacketBuddy Service Launcher
REM This script is used by Windows Task Scheduler to run PacketBuddy service
REM It properly sets up the environment before starting the server

REM Get the directory where this script is located
set "SCRIPT_DIR=%~dp0"
set "PROJECT_DIR=%SCRIPT_DIR:~0,-1%"

REM Change to project directory
cd /d "%PROJECT_DIR%"

REM Set PYTHONPATH so Python can find the src module
set "PYTHONPATH=%PROJECT_DIR%"

REM Detect pythonw.exe (windowless) for headless operation
set "PYTHON_EXE=%PROJECT_DIR%\venv\Scripts\pythonw.exe"
if not exist "%PYTHON_EXE%" (
    set "PYTHON_EXE=%PROJECT_DIR%\venv\Scripts\python.exe"
)

REM Run the server module
"%PYTHON_EXE%" -m src.api.server
