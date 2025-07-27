package(default_visibility = ["//visibility:public"])

load("@onedal//dev/bazel/toolchains:cc_toolchain_config_win.bzl", "cc_toolchain_config")

cc_toolchain_config(
    name = "cc_toolchain_config",
    cpu = "%{target_cpu}",
    compiler = "%{compiler}",
    toolchain_identifier = "%{toolchain_identifier}",
    host_system_name = "%{host_system_name}",
    target_system_name = "%{target_system_name}",
    target_libc = "%{target_libc}",
    abi_version = "%{abi_version}",
    abi_libc_version = "%{abi_libc_version}",
    tool_paths = {
        "ar": "%{ar}",
        "compat-ld": "%{ld}",
        "cpp": "%{cpp}",
        "dwp": "%{dwp}",
        "gcc": "%{cc}",
        "gcov": "%{gcov}",
        "ld": "%{ld}",
        "nm": "%{nm}",
        "objcopy": "%{objcopy}",
        "objdump": "%{objdump}",
        "strip": "%{strip}",
    },
    compile_flags = %{compile_flags},
    cxx_flags = %{cxx_flags},
    link_flags = %{link_flags},
    opt_compile_flags = %{opt_compile_flags},
    opt_link_flags = %{opt_link_flags},
    dbg_compile_flags = %{dbg_compile_flags},
    coverage_compile_flags = %{coverage_compile_flags},
    coverage_link_flags = %{coverage_link_flags},
    builtin_include_directories = %{builtin_include_directories},
    supports_start_end_lib = %{supports_start_end_lib},
)

cc_toolchain(
    name = "cc_toolchain",
    all_files = ":all_files",
    ar_files = ":ar_files",
    as_files = ":as_files",
    compiler_files = ":compiler_files",
    dwp_files = ":dwp_files",
    linker_files = ":linker_files",
    objcopy_files = ":objcopy_files",
    strip_files = ":strip_files",
    supports_param_files = 1,
    toolchain_config = ":cc_toolchain_config",
    toolchain_identifier = "%{toolchain_identifier}",
)

filegroup(
    name = "all_files",
    srcs = [
        ":ar_files",
        ":as_files",
        ":compiler_files",
        ":dwp_files",
        ":linker_files",
        ":objcopy_files",
        ":strip_files",
    ],
)

filegroup(
    name = "ar_files",
    srcs = ["%{ar}"],
)

filegroup(
    name = "as_files",
    srcs = ["%{cc}"],
)

filegroup(
    name = "compiler_files",
    srcs = ["%{cc}"],
)

filegroup(
    name = "dwp_files",
    srcs = [],
)

filegroup(
    name = "linker_files",
    srcs = [
        "%{ar}",
        "%{cc}",
        "%{ld}",
    ],
)

filegroup(
    name = "objcopy_files",
    srcs = ["%{objcopy}"],
)

filegroup(
    name = "strip_files",
    srcs = ["%{strip}"],
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
    toolchain = ":cc_toolchain",
    toolchain_type = "@bazel_tools//tools/cpp:toolchain_type",
)
