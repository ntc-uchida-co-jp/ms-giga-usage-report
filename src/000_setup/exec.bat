@echo off

start /wait powershell.exe -ExecutionPolicy Bypass -File "%~dp0deploy1.ps1"
start powershell.exe -ExecutionPolicy Bypass -File "%~dp0deploy2.ps1"
pause