# Windows Support for Bazel Build

This document describes how to build oneDAL using Bazel on Windows.

## Prerequisites

### Required Software

1. **Visual Studio 2019 or 2022** with C++ development tools
   - Visual Studio Community, Professional, or Enterprise
   - Install "Desktop development with C++" workload
   - Or install "MSVC v143 - VS 2022 C++ x64/x86 build tools" and "Windows 10/11 SDK"

2. **Bazel** (version 6.0 or later)
   - Download from [https://bazel.build/install/windows](https://bazel.build/install/windows)
   - Or install via Chocolatey: `choco install bazel`

3. **Intel oneAPI Toolkit** (optional, for Intel compilers)
   - Intel oneAPI Base Toolkit
   - Intel oneAPI HPC Toolkit (for Intel C++ Compiler)

### Environment Setup

1. **Setup Visual Studio Environment**
   ```cmd
   "C:\Program Files\Microsoft Visual Studio\2022\Professional\VC\Auxiliary\Build\vcvars64.bat"
   ```

2. **Setup Intel oneAPI (if using Intel compilers)**
   ```cmd
   "C:\Program Files (x86)\Intel\oneAPI\setvars.bat"
   ```

## Building

### Basic Build

To build oneDAL on Windows with default settings:

```cmd
bazel build @onedal//:release
```

### Build with Specific Configuration

1. **Using MSVC Compiler:**
   ```cmd
   bazel build @onedal//:release --config=win
   ```

2. **Using Intel C++ Compiler:**
   ```cmd
   set CC=icx
   bazel build @onedal//:release --config=win
   ```

3. **Debug Build:**
   ```cmd
   bazel build @onedal//:release --config=win --compilation_mode=dbg
   ```

4. **Optimized Build:**
   ```cmd
   bazel build @onedal//:release --config=win --compilation_mode=opt
   ```

### CPU Target Configuration

You can specify the target CPU architecture:

```cmd
# Build for modern CPUs (AVX2 support)
bazel build @onedal//:release --config=win --//dev/bazel/config:cpu=modern

# Build for all supported CPUs
bazel build @onedal//:release --config=win --//dev/bazel/config:cpu=all

# Build for specific CPU extensions
bazel build @onedal//:release --config=win --//dev/bazel/config:cpu="sse2 avx2"
```

### Backend Configuration

```cmd
# Build with Intel MKL backend (default)
bazel build @onedal//:release --config=win --//dev/bazel/config:backend_config=mkl

# Build with reference backend
bazel build @onedal//:release --config=win --//dev/bazel/config:backend_config=ref
```

## Testing

To run tests on Windows:

```cmd
bazel test //cpp/... --config=win --test_output=errors
```

## Troubleshooting

### Common Issues

1. **Compiler Not Found**
   - Ensure Visual Studio is properly installed
   - Run `vcvars64.bat` before building
   - Check that `cl.exe` is in your PATH

2. **Windows SDK Not Found**
   - Install Windows 10/11 SDK via Visual Studio Installer
   - Ensure SDK paths are in INCLUDE and LIB environment variables

3. **Intel Compiler Issues**
   - Source `setvars.bat` from Intel oneAPI installation
   - Ensure Intel compiler is compatible with your Visual Studio version

4. **Long Path Issues**
   - Enable long path support in Windows 10/11
   - Use `--output_user_root=C:\bazel` to shorten output paths

### Environment Variables

The following environment variables may be useful:

- `VCINSTALLDIR`: Path to Visual Studio installation
- `WindowsSDKDir`: Path to Windows SDK
- `CC`: Compiler to use (cl, icx, etc.)
- `BAZEL_VC`: Path to Visual C++ installation (if auto-detection fails)

## Features Supported on Windows

- ✅ MSVC Compiler (cl.exe)
- ✅ Intel C++ Compiler (icx.exe)
- ✅ Intel DPC++ Compiler (icpx.exe)
- ✅ Static and Dynamic Libraries
- ✅ CPU Architecture Detection
- ✅ AVX2/AVX512 Optimizations
- ✅ Intel MKL Backend
- ✅ Reference Backend
- ✅ Unit Tests
- ✅ Examples

For more information, see the main oneDAL documentation at [https://github.com/uxlfoundation/oneDAL](https://github.com/uxlfoundation/oneDAL).
