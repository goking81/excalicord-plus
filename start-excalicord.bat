@echo off
rem ============================================================
rem  Excalicord Studio - launcher
rem
rem  HARD RULES when editing this file:
rem    1) keep it PURE ASCII - no Chinese, not even in comments
rem    2) never add a codepage switch command: cmd.exe mis-parses
rem       batch files holding multi-byte chars after a codepage
rem       change, and starts running text fragments as commands
rem    3) no BOM (cmd.exe would treat the BOM as a command)
rem
rem  This launcher deliberately does NOT use PowerShell. Some
rem  machines block .ps1 files via ExecutionPolicy (Restricted),
rem  which is a per-machine wall you cannot talk your way past.
rem  It runs the bundled Node binary directly instead - a plain
rem  .exe is never subject to ExecutionPolicy.
rem ============================================================

setlocal
cd /d "%~dp0"
title Excalicord Studio - local server

set "NODEEXE="

if exist "%~dp0node\node.exe" set "NODEEXE=%~dp0node\node.exe"
if not defined NODEEXE if exist "%~dp0node.exe" set "NODEEXE=%~dp0node.exe"

if not defined NODEEXE (
  for /d %%D in ("%~dp0node*") do (
    if not defined NODEEXE if exist "%%~fD\node.exe" set "NODEEXE=%%~fD\node.exe"
  )
)

if not defined NODEEXE (
  for /f "delims=" %%P in ('where node 2^>nul') do (
    if not defined NODEEXE set "NODEEXE=%%P"
  )
)

if not defined NODEEXE (
  echo.
  echo   [ERROR] Node.js was not found.
  echo.
  echo   This package is supposed to ship:  node\node.exe
  echo   If that file is missing, download the Windows win-x64 ZIP
  echo   from nodejs.org ^(NOT the .msi installer^) and extract it
  echo   into this folder so that "node\node.exe" exists again.
  echo.
  pause
  exit /b 1
)

echo.
echo   Excalicord Studio - local server
echo   --------------------------------------------------------
echo   Node : %NODEEXE%
echo   URL  : http://127.0.0.1:5001/
echo.
echo   Open that URL in Chrome or Edge.
echo   Keep THIS window open while recording. Ctrl+C stops it.
echo   --------------------------------------------------------
echo.

"%NODEEXE%" "no-cache-server.js"

echo.
echo   Server stopped. Press any key to close this window.
pause >nul
