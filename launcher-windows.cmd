@REM Windows launcher for Bitmap Buddy
@REM 
@REM This launcher is needed to wrap the main script, so it inherits the directory path from the shell: 
@REM Lua 5.1 cannot get the script path by itself reliably on Windows
@ECHO OFF
SET original_directory=%CD%
SET root_directory=%~dp0
CD %root_directory%
@REM All arguments are passed intact with %*
@REM This line launches the embedded Lua 5.1 interpreter for Windows x64, downloaded from LuaBinaries' Source Forge repository
@REM Even if you haven't installed Lua in your system, now this thing can run even in your grandma's PC
CALL ".\lua\windows-x64\lua5.1.exe" main.lua %*
CD %original_directory%