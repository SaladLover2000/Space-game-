@echo off
setlocal
set "ORBIT_GODOT=%~dp0..\..\Godot_v4.4.1-stable_win64.exe\Godot_v4.4.1-stable_win64.exe"
if not exist "%ORBIT_GODOT%" (
  echo Godot was not found in its Downloads folder.
  echo Open project.godot in Godot 4.4.1 and press F5 instead.
  pause
  exit /b 1
)
start "Little Orbit" "%ORBIT_GODOT%" --path "%~dp0."
