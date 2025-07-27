## Test Build Configuration for Windows

This directory contains a simple test to verify Windows toolchain functionality.

### Usage

```bash
# Test basic C++ compilation on Windows
bazel build //dev/bazel/toolchains/test:hello_world_win

# Test with Intel compiler (if available)
set CC=icx
bazel build //dev/bazel/toolchains/test:hello_world_win

# Test static library creation
bazel build //dev/bazel/toolchains/test:test_lib_win
```

### Files

- `hello_world.cpp` - Simple C++ test program
- `test_lib.cpp` - Test library source
- `BUILD` - Bazel build configuration for Windows testing
