package(default_visibility = ["//visibility:public"])

# Test library for Windows toolchain
cc_library(
    name = "test_lib_win",
    srcs = ["test_lib.cpp"],
    hdrs = ["test_lib.h"],
    target_compatible_with = [
        "@platforms//os:windows",
    ],
)

# Test executable for Windows toolchain
cc_binary(
    name = "hello_world_win",
    srcs = ["hello_world.cpp"],
    deps = [":test_lib_win"],
    target_compatible_with = [
        "@platforms//os:windows",
    ],
)

# Cross-platform library (works on any platform)
cc_library(
    name = "test_lib",
    srcs = ["test_lib.cpp"],
    hdrs = ["test_lib.h"],
)

# Cross-platform executable
cc_binary(
    name = "hello_world",
    srcs = ["hello_world.cpp"],
    deps = [":test_lib"],
)
