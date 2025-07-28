@echo off
setlocal enabledelayedexpansion

REM Script for creating dynamic libraries on Windows
REM Usage: dynamic_link_win.bat <output.dll> <inputs...>

if "%~1"=="" (
    echo Error: No output file specified
    exit /b 1
)

set OUTPUT=%~1
shift

REM Extract filename without extension for .lib file
for %%f in ("%OUTPUT%") do (
    set BASENAME=%%~nf
    set DIRNAME=%%~dpf
)

set IMPLIB=%DIRNAME%%BASENAME%.lib

REM Collect all input files
set INPUTS=
:collect_args
if "%~1"=="" goto done_collecting
set INPUTS=!INPUTS! "%~1"
shift
goto collect_args

:done_collecting

if "!INPUTS!"=="" (
    echo Error: No input files specified
    exit /b 1
)

REM Use link.exe to create DLL with import library
link.exe /DLL /OUT:"%OUTPUT%" /IMPLIB:"%IMPLIB%" !INPUTS!

if %ERRORLEVEL% neq 0 (
    echo Error: Failed to create dynamic library
    exit /b %ERRORLEVEL%
)

echo Successfully created dynamic library %OUTPUT% with import library %IMPLIB%
exit /b 0
