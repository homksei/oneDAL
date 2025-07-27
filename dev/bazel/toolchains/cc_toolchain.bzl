#===============================================================================
# Copyright 2020 Intel Corporation
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#===============================================================================

load("@onedal//dev/bazel/toolchains:common.bzl", "detect_os", "detect_compiler")
load("@onedal//dev/bazel/toolchains:cc_toolchain_lnx.bzl", "configure_cc_toolchain_lnx", "find_tool")

def _detect_requirements(repo_ctx):
    os_id = detect_os(repo_ctx)
    compiler_id = detect_compiler(repo_ctx, os_id)
    dpc_compiler_id = "icpx"
    dpcc_path, dpcpp_found = find_tool(repo_ctx, dpc_compiler_id, mandatory = False)
    dpc_compiler_version = _detect_compiler_version(repo_ctx, dpcc_path) if dpcpp_found else "local"
    return struct(
        os_id = os_id,
        compiler_id = compiler_id,

        libc_version = "local",
        libc_abi_version = "local",
        compiler_abi_version = "local",

        host_arch_id = "intel64",
        target_arch_id = "intel64",

        # TODO: Detect compiler version
        compiler_version = "local",

        # TODO: Detect DPC++ compiler, use $env{DPCC}
        dpc_compiler_id = dpc_compiler_id,

        # TODO: Detect compiler version
        dpc_compiler_version = dpc_compiler_version,
    )

def _detect_compiler_version(repo_ctx, dpcc_path):
    year, major, minor, date = repo_ctx.execute([dpcc_path, "--version"])\
                                       .stdout.split(" ")[5].split("(")[1]\
                                       .split(")")[0].split(".")
    return date

def _configure_cc_toolchain(repo_ctx, reqs):
    if reqs.os_id == "lnx":
        configure_cc_toolchain_lnx(repo_ctx, reqs)
    elif reqs.os_id == "win":
        # For Windows, we need to use a different approach
        # Create a repository rule for Windows toolchain
        repo_ctx.template(
            "BUILD",
            Label("@onedal//dev/bazel/toolchains:cc_toolchain_win.tpl.BUILD"),
            {
                "%{cc}": "cl.exe",
                "%{cpp}": "cl.exe",
                "%{cxx}": "cl.exe",
                "%{ar}": "lib.exe",
                "%{ld}": "link.exe",
                "%{gcov}": "gcov.exe",
                "%{objcopy}": "objcopy.exe",
                "%{objdump}": "objdump.exe",
                "%{strip}": "strip.exe",
                "%{nm}": "nm.exe",
                "%{toolchain_identifier}": "msvc_x64",
                "%{host_system_name}": "local",
                "%{target_system_name}": "local",
                "%{target_cpu}": "x64_windows",
                "%{target_libc}": "msvcrt",
                "%{compiler}": "msvc",
                "%{abi_version}": "local",
                "%{abi_libc_version}": "local",
                "%{builtin_include_directories}": "[]",
                "%{compile_flags}": '["/std:c++17", "/EHsc", "/nologo"]',
                "%{cxx_flags}": "[]",
                "%{link_flags}": '["/NOLOGO"]',
                "%{opt_compile_flags}": '["/O2", "/DNDEBUG"]',
                "%{opt_link_flags}": '["/OPT:REF"]',
                "%{dbg_compile_flags}": '["/Od", "/Zi"]',
                "%{coverage_compile_flags}": "[]",
                "%{coverage_link_flags}": "[]",
                "%{supports_start_end_lib}": "False",
            }
        )
    else:
        fail("Unsupported OS: " + reqs.os_id)

def _onedal_cc_toolchain_impl(repo_ctx):
    reqs = _detect_requirements(repo_ctx)
    _configure_cc_toolchain(repo_ctx, reqs)

onedal_cc_toolchain = repository_rule(
    implementation = _onedal_cc_toolchain_impl,
    environ = [
        "CC",
        "PATH",
        "INCLUDE",
        "LIB",
    ],
)
