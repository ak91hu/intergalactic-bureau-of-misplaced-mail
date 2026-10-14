@echo off
if not exist "%~dp0export\windows\MisplacedMail.exe" (
  echo Build the game first with scripts\build.ps1.
  pause
  exit /b 1
)
start "" "%~dp0export\windows\MisplacedMail.exe"
