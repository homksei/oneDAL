@echo off
REM Script for merging static libraries on Windows
REM Usage: merge_static_libs.bat output.lib input1.lib input2.lib ...

set OUTPUT=%1
shift

set INPUTS=
:loop
if "%1"=="" goto merge
set INPUTS=%INPUTS% %1
shift
goto loop

:merge
"%{lib_path}" /OUT:%OUTPUT% %INPUTS%
