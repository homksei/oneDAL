@echo off
rem ============================================================================
rem Windows Bazel Build Test Script for oneDAL
rem ============================================================================

setlocal EnableDelayedExpansion

echo Testing oneDAL Bazel build on Windows...
echo.

rem Check if Bazel is installed
bazel version >nul 2>&1
if %ERRORLEVEL% neq 0 (
    echo ERROR: Bazel is not installed or not in PATH
    echo Please install Bazel from https://bazel.build/install/windows
    exit /b 1
)

echo ✓ Bazel is installed

rem Check if Visual Studio is available
cl /? >nul 2>&1
if %ERRORLEVEL% neq 0 (
    echo WARNING: Visual Studio compiler (cl.exe) not found in PATH
    echo Trying to set up Visual Studio environment...

    rem Try common Visual Studio paths
    set VSPATH="C:\Program Files\Microsoft Visual Studio\2022\Professional\VC\Auxiliary\Build\vcvars64.bat"
    if exist !VSPATH! (
        echo Found Visual Studio 2022 Professional
        call !VSPATH!
    ) else (
        set VSPATH="C:\Program Files\Microsoft Visual Studio\2022\Enterprise\VC\Auxiliary\Build\vcvars64.bat"
        if exist !VSPATH! (
            echo Found Visual Studio 2022 Enterprise
            call !VSPATH!
        ) else (
            set VSPATH="C:\Program Files\Microsoft Visual Studio\2022\Community\VC\Auxiliary\Build\vcvars64.bat"
            if exist !VSPATH! (
                echo Found Visual Studio 2022 Community
                call !VSPATH!
            ) else (
                echo ERROR: Could not find Visual Studio installation
                echo Please install Visual Studio with C++ development tools
                exit /b 1
            )
        )
    )

    rem Check again after setup
    cl /? >nul 2>&1
    if %ERRORLEVEL% neq 0 (
        echo ERROR: Still cannot find Visual Studio compiler
        exit /b 1
    )
)

echo ✓ Visual Studio compiler is available

rem Test basic configuration
echo.
echo Testing Bazel configuration...
bazel info --config=win >nul 2>&1
if %ERRORLEVEL% neq 0 (
    echo ERROR: Bazel Windows configuration failed
    exit /b 1
)

echo ✓ Bazel Windows configuration is working

rem Test simple build
echo.
echo Testing simple build...
bazel build @config//:version --config=win
if %ERRORLEVEL% neq 0 (
    echo ERROR: Simple build test failed
    exit /b 1
)

echo ✓ Simple build test passed

rem Test CPU detection
echo.
echo Testing CPU detection...
bazel build @config//:cpu --config=win
if %ERRORLEVEL% neq 0 (
    echo WARNING: CPU detection failed, but this is not critical
) else (
    echo ✓ CPU detection working
)

echo.
echo ============================================================================
echo All basic tests passed!
echo Your Windows environment is ready for oneDAL Bazel builds.
echo.
echo To build oneDAL, run:
echo   bazel build @onedal//:release --config=win
echo.
echo To run tests, run:
echo   bazel test //cpp/... --config=win --test_output=errors
echo ============================================================================
