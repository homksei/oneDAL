@echo off
rem ============================================================================
rem Copyright 2020 Intel Corporation
rem
rem Licensed under the Apache License, Version 2.0 (the "License");
rem you may not use this file except in compliance with the License.
rem You may obtain a copy of the License at
rem
rem     http://www.apache.org/licenses/LICENSE-2.0
rem
rem Unless required by applicable law or agreed to in writing, software
rem distributed under the License is distributed on an "AS IS" BASIS,
rem WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
rem See the License for the specific language governing permissions and
rem limitations under the License.
rem ============================================================================

rem Windows version of merge_static_libs script
rem Usage: merge_static_libs_win.bat output.lib input1.lib input2.lib ...

setlocal EnableDelayedExpansion

set OUTPUT_LIB=%1
shift

set INPUT_LIBS=
:loop
if "%1"=="" goto :done
set INPUT_LIBS=!INPUT_LIBS! %1
shift
goto :loop

:done

rem Use lib.exe to merge static libraries
lib.exe /OUT:%OUTPUT_LIB% %INPUT_LIBS%

if %ERRORLEVEL% neq 0 (
    echo Error: Failed to merge static libraries
    exit /b 1
)

echo Successfully merged static libraries into %OUTPUT_LIB%
