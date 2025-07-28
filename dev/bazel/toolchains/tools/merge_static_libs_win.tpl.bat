@echo off
setlocal enabledelayedexpansion

REM Script for merging static libraries on Windows
REM Usage: merge_static_libs_win.bat <output.lib> <input1.lib> <input2.lib> ...

if "%~1"=="" (
    echo Error: No output file specified
    exit /b 1
)

set OUTPUT=%~1
shift

REM Collect all input libraries
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

REM Use lib.exe to merge static libraries
lib.exe /OUT:"%OUTPUT%" !INPUTS!

if %ERRORLEVEL% neq 0 (
    echo Error: Failed to merge static libraries
    exit /b %ERRORLEVEL%
)

echo Successfully merged static libraries into %OUTPUT%
exit /b 0
