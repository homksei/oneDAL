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

rem Windows version of patch_daal_kernel_defines script

setlocal EnableDelayedExpansion

set INPUT_FILE=%1
set OUTPUT_FILE=%2

rem Copy input to output first
copy "%INPUT_FILE%" "%OUTPUT_FILE%" >nul

rem Use PowerShell for text replacement (similar to sed on Linux)
powershell -Command "(Get-Content '%OUTPUT_FILE%') -replace '__DAAL_IMPLEMENTATION', '__DAAL_IMPLEMENTATION_PATCHED' | Set-Content '%OUTPUT_FILE%'"

if %ERRORLEVEL% neq 0 (
    echo Error: Failed to patch DAAL kernel defines
    exit /b 1
)

echo Successfully patched DAAL kernel defines
