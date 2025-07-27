# Windows Bazel Configuration Examples

This file contains various .bazelrc configuration examples for building oneDAL on Windows.

## Basic MSVC Configuration

```
# .bazelrc
build:win --cpu=x64_windows
build:win --host_cpu=x64_windows
build:win --compiler=msvc
build:win --copt=/std:c++17
build:win --copt=/EHsc
build:win --copt=/bigobj
build:win --copt=/nologo
build:win --linkopt=/NOLOGO
```

## Intel C++ Compiler Configuration

```
# .bazelrc
build:win-icx --config=win
build:win-icx --action_env=CC=icx
build:win-icx --copt=/Qopenmp-simd
```

## Intel DPC++ Compiler Configuration

```
# .bazelrc
build:win-dpcpp --config=win-icx
build:win-dpcpp --action_env=CC=icpx
build:win-dpcpp --copt=/Qsycl
```

## Debug Configuration

```
# .bazelrc
build:win-debug --config=win
build:win-debug --compilation_mode=dbg
build:win-debug --copt=/Od
build:win-debug --copt=/Zi
build:win-debug --copt=/DEBUG
```

## Release Configuration

```
# .bazelrc
build:win-release --config=win
build:win-release --compilation_mode=opt
build:win-release --copt=/O2
build:win-release --copt=/DNDEBUG
build:win-release --linkopt=/OPT:REF
build:win-release --linkopt=/OPT:ICF
```

## CPU-Specific Configurations

### Modern CPUs (AVX2)
```
# .bazelrc
build:win-modern --config=win
build:win-modern --//dev/bazel/config:cpu=modern
build:win-modern --copt=/arch:AVX2
```

### AVX-512 Support
```
# .bazelrc
build:win-avx512 --config=win
build:win-avx512 --//dev/bazel/config:cpu=avx512
build:win-avx512 --copt=/arch:AVX512
```

## Backend Configurations

### Intel MKL Backend
```
# .bazelrc
build:win-mkl --config=win
build:win-mkl --//dev/bazel/config:backend_config=mkl
```

### Reference Backend
```
# .bazelrc
build:win-ref --config=win
build:win-ref --//dev/bazel/config:backend_config=ref
```

## Testing Configurations

### Basic Testing
```
# .bazelrc
test:win --config=win
test:win --test_output=errors
test:win --test_timeout=900
```

### Verbose Testing
```
# .bazelrc
test:win-verbose --config=win
test:win-verbose --test_output=all
test:win-verbose --test_arg=--verbose
```

## Complete Production Configuration

```
# .bazelrc for Windows production builds

# Basic Windows settings
build:win --cpu=x64_windows
build:win --host_cpu=x64_windows
build:win --compiler=msvc
build:win --copt=/std:c++17
build:win --copt=/EHsc
build:win --copt=/bigobj
build:win --copt=/nologo
build:win --copt=/DWIN32
build:win --copt=/D_WINDOWS
build:win --copt=/D_CRT_SECURE_NO_WARNINGS
build:win --copt=/D_SCL_SECURE_NO_WARNINGS
build:win --copt=/DNOMINMAX
build:win --linkopt=/NOLOGO
build:win --linkopt=/SUBSYSTEM:CONSOLE
build:win --linkopt=/MACHINE:X64

# Production release build
build:win-prod --config=win
build:win-prod --compilation_mode=opt
build:win-prod --copt=/O2
build:win-prod --copt=/DNDEBUG
build:win-prod --linkopt=/OPT:REF
build:win-prod --linkopt=/OPT:ICF
build:win-prod --//dev/bazel/config:cpu=modern
build:win-prod --//dev/bazel/config:backend_config=mkl

# Development build with debug info
build:win-dev --config=win
build:win-dev --compilation_mode=opt
build:win-dev --copt=/O2
build:win-dev --copt=/Zi
build:win-dev --linkopt=/DEBUG

# Testing configuration
test:win --config=win
test:win --test_output=errors
test:win --test_timeout=900
test:win --test_env=DAAL_DATASETS
```

## Usage Examples

### Build with MSVC
```cmd
bazel build @onedal//:release --config=win
```

### Build with Intel C++ Compiler
```cmd
set CC=icx
bazel build @onedal//:release --config=win-icx
```

### Build with Intel DPC++
```cmd
set CC=icpx
bazel build @onedal//:release --config=win-dpcpp
```

### Run tests
```cmd
bazel test //cpp/... --config=win
```

### Build examples
```cmd
bazel build //examples/... --config=win
```

### Build for specific CPU
```cmd
bazel build @onedal//:release --config=win --//dev/bazel/config:cpu=avx512
```
