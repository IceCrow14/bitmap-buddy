@REM Windows launcher for Bitmap Buddy
@REM 
@REM This launcher is needed to wrap the main script, so it inherits the directory path from the shell
@REM Lua 5.1 cannot get the script path by itself reliably on Windows
@ECHO OFF
SET original_directory=%CD%
SET root_directory=%~dp0
CD %root_directory%
@REM All arguments are passed intact with %*
lua main.lua %*
CD %original_directory%