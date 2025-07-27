# Windows Support for oneDAL Bazel Build

This document describes the Windows support added to the oneDAL Bazel build system.

## Overview

Windows support has been added to the oneDAL Bazel toolchain system, allowing builds on Windows using either Microsoft Visual Studio (MSVC) or Intel oneAPI C++ Compiler (ICX).

## Files Added/Modified

### New Files
- `dev/bazel/toolchains/cc_toolchain_config_win.bzl` - Windows-specific C++ toolchain configuration
- `dev/bazel/toolchains/cc_toolchain_win.bzl` - Windows toolchain setup and tool discovery
- `dev/bazel/toolchains/cc_toolchain_win.tpl.BUILD` - BUILD template for Windows toolchain
- `dev/bazel/toolchains/extra_toolchain_win.bzl` - Windows extra toolchain configuration
- `dev/bazel/toolchains/extra_toolchain_win.tpl.BUILD` - BUILD template for Windows extra toolchain
- `dev/bazel/toolchains/tools/merge_static_libs_win.tpl.bat` - Windows static library merger
- `dev/bazel/toolchains/tools/dynamic_link_win.tpl.bat` - Windows dynamic linking wrapper
- `dev/bazel/toolchains/tools/patch_daal_kernel_defines.bat` - Windows DAAL kernel defines patcher

### Modified Files
- `dev/bazel/toolchains/cc_toolchain.bzl` - Added Windows support to main toolchain configuration
- `dev/bazel/toolchains/common.bzl` - Improved Windows compiler detection
- `dev/bazel/toolchains/extra_toolchain.bzl` - Added Windows support to extra toolchain
- `dev/bazel/toolchains/extra_toolchain_lnx.bzl` - Updated interface to match Windows version

## Prerequisites

### Visual Studio
- Visual Studio 2019 or later with C++ build tools
- Or Visual Studio Build Tools 2019/2022

### Intel oneAPI (Optional)
- Intel oneAPI DPC++/C++ Compiler for Windows
- Intel oneAPI Math Kernel Library (oneMKL)

## Usage

The Windows toolchain is automatically detected and configured when building on Windows. The system will:

1. Detect the operating system as Windows
2. Search for available compilers (ICX -> MSVC cl.exe)
3. Configure Visual Studio environment using vcvarsall.bat
4. Set up appropriate compilation and linking flags

### Environment Variables

The following environment variables can be used to customize the build:

- `CC` - Override compiler detection (e.g., `cl`, `icx`)
- `PATH` - Should include Visual Studio tools
- `INCLUDE` - Additional include directories
- `LIB` - Additional library directories

### Building

```bash
# Standard build (will auto-detect Windows toolchain)
bazel build //...

# Build with specific compiler
set CC=icx
bazel build //...

# Build with debug configuration
bazel build -c dbg //...
```

## Supported Compilers

1. **Microsoft Visual C++ (cl.exe)** - Default Windows compiler
   - Supports C++17 standard
   - Optimized for Windows development

2. **Intel oneAPI C++ Compiler (icx)** - Intel's modern C++ compiler
   - Based on LLVM/Clang
   - Better optimization for Intel hardware
   - Full C++17 support

## Features

### Automatic Tool Discovery
- Automatically locates Visual Studio installation
- Uses vswhere.exe when available
- Falls back to common installation paths

### Environment Setup
- Executes vcvarsall.bat to set up MSVC environment
- Handles PATH, INCLUDE, and LIB variables
- Supports both x86 and x64 architectures

### Windows-Specific Features
- Proper .exe, .dll, .lib file extensions
- Windows-specific compilation flags
- MSVC-style static library merging
- Support for Windows subsystem linking

## Limitations

1. **Assembly Support** - Limited assembly support (ml64/ml)
2. **DAAL Kernel Patching** - Windows-specific patching not yet implemented
3. **Debug Symbols** - PDB support may need additional configuration

## Troubleshooting

### Common Issues

1. **Visual Studio Not Found**
   ```
   Error: Cannot find Visual Studio installation
   ```
   Solution: Install Visual Studio Build Tools or full Visual Studio

2. **Compiler Not Found**
   ```
   Error: Cannot find cl; try to correct your $PATH
   ```
   Solution: Run build from Visual Studio Developer Command Prompt

3. **Missing vcvarsall.bat**
   ```
   Error: Cannot find vcvarsall.bat
   ```
   Solution: Ensure Visual Studio is properly installed with C++ tools

### Debug Information

To debug toolchain issues, you can:

1. Check detected OS: Should show "win" for Windows
2. Verify compiler detection: Should find "cl" or "icx"
3. Examine generated BUILD files in bazel-out directories

## Future Improvements

1. Enhanced Intel compiler integration
2. Better debugging support (PDB files)
3. Windows-specific DAAL kernel optimization
4. Support for different Visual Studio versions
5. Cross-compilation support

## Contributing

When adding Windows-specific features:

1. Test with both MSVC and Intel compilers
2. Ensure proper file path handling (forward vs back slashes)
3. Use appropriate file extensions (.exe, .bat)
4. Consider Windows-specific environment variables
