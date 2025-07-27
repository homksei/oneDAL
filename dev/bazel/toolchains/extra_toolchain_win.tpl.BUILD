package(default_visibility = ["//visibility:public"])

load("@onedal//dev/bazel/toolchains:extra_toolchain.bzl", "extra_toolchain")

extra_toolchain(
    name = "extra_toolchain",
    patch_daal_kernel_defines = "%{patch_daal_kernel_defines}",
)

toolchain(
    name = "toolchain",
    exec_compatible_with = [
        "@platforms//os:windows",
        "@platforms//cpu:x86_64",
    ],
    target_compatible_with = [
        "@platforms//os:windows",
        "@platforms//cpu:x86_64",
    ],
    toolchain = ":extra_toolchain",
    toolchain_type = "@onedal//dev/bazel/toolchains:extra",
)

# Export all toolchains for registration
alias(
    name = "all",
    actual = ":toolchain",
)
