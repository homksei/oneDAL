load("@onedal//dev/bazel/toolchains:cc_toolchain_config_win.bzl", "cc_toolchain_config")

package(default_visibility = ["//visibility:public"])

filegroup(name = "empty")

cc_toolchain_config(
    name = "cc_toolchain_config",
    cc_path = "%{cc_path}",
    dpcc_path = "%{dpcc_path}",
    link_path = "%{link_path}",
    lib_path = "%{lib_path}",
    ml64_path = "%{ml64_path}",
    rc_path = "%{rc_path}",
    vcvars_path = "%{vcvars_path}",
    toolchain_identifier = "%{toolchain_identifier}",
    host_system_name = "%{host_system_name}",
    target_system_name = "%{target_system_name}",
    target_cpu = "%{target_cpu}",
    target_libc = "%{target_libc}",
    compiler = "%{compiler}",
    abi_version = "%{abi_version}",
    abi_libc_version = "%{abi_libc_version}",
    cc_target_os = "%{cc_target_os}",
    builtin_sysroot = "%{builtin_sysroot}",
    cxx_builtin_include_directories = [
%{cxx_builtin_include_directories}
    ],
    tool_bin_path = "%{tool_bin_path}",
    common_options = [
%{common_options}
    ],
    pedantic_options = [
%{pedantic_options}
    ],
    dpcc_common_options = [
%{dpcc_common_options}
    ],
    dpcc_pedantic_options = [
%{dpcc_pedantic_options}
    ],
    cpu_options = {
        %{cpu_options}
    },
    dpcc_cpu_options = {
        %{dpcc_cpu_options}
    },
    system_lib_directories = [
%{system_lib_directories}
    ],
)

cc_toolchain(
    name = "cc_toolchain",
    toolchain_identifier = "%{toolchain_identifier}",
    toolchain_config = ":cc_toolchain_config",
    all_files = ":empty",
    ar_files = ":empty",
    as_files = ":empty",
    compiler_files = ":empty",
    dwp_files = ":empty",
    linker_files = ":empty",
    objcopy_files = ":empty",
    strip_files = ":empty",
)

toolchain(
    name = "toolchain",
    target_compatible_with = [
        "@platforms//os:windows",
        "@platforms//cpu:x86_64",
    ],
    toolchain = ":cc_toolchain",
    toolchain_type = "@bazel_tools//tools/cpp:toolchain_type",
)
