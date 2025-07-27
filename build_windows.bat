@echo off
rem ============================================================================
rem Example build script for oneDAL on Windows using Bazel
rem ============================================================================

echo Setting up Visual Studio environment...
call "C:\Program Files\Microsoft Visual Studio\2022\Professional\VC\Auxiliary\Build\vcvars64.bat"

if %ERRORLEVEL% neq 0 (
    echo Warning: Could not set up Visual Studio environment automatically
    echo Please run vcvars64.bat manually before using this script
)

echo.
echo Building oneDAL with Bazel...
echo.

rem Build with default configuration (MSVC)
echo Building with MSVC compiler...
bazel build @onedal//:release --config=win

if %ERRORLEVEL% neq 0 (
    echo Build failed!
    exit /b 1
)

echo.
echo Build completed successfully!
echo.

rem Optional: Run tests
echo Running tests...
bazel test //cpp/... --config=win --test_output=errors

if %ERRORLEVEL% neq 0 (
    echo Some tests failed!
    exit /b 1
)

echo.
echo All tests passed!
echo.
