load("@onedal//dev/bazel/toolchains/tools:merge_static_libs_win.bzl", "merge_static_libs_win")
load("@onedal//dev/bazel/toolchains/tools:dynamic_link_win.bzl", "dynamic_link_win")
load("@onedal//dev/bazel/toolchains/tools:patch_daal_kernel_defines_win.bzl", "patch_daal_kernel_defines_win")

package(default_visibility = ["//visibility:public"])

merge_static_libs_win(
    name = "merge_static_libs_win",
    toolchain_identifier = "%{toolchain_identifier}",
)

dynamic_link_win(
    name = "dynamic_link_win",
    toolchain_identifier = "%{toolchain_identifier}",
    target_arch_id = "%{target_arch_id}",
)

patch_daal_kernel_defines_win(
    name = "patch_daal_kernel_defines_win",
    toolchain_identifier = "%{toolchain_identifier}",
)
