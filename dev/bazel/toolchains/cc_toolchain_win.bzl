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

load(
    "@rules_cc//cc/private/toolchain:lib_cc_configure.bzl",
    "auto_configure_fail",
    "get_starlark_list",
    "write_builtin_include_directory_paths",
)
load(
    "@onedal//dev/bazel:utils.bzl",
    "paths",
    "utils",
)
load(
    "@onedal//dev/bazel/toolchains:common.bzl",
    "TEST_CPP_FILE",
    "add_compiler_option_if_supported",
    "add_linker_option_if_supported",
    "get_cpu_specific_options",
    "get_cxx_inc_directories",
    "get_default_compiler_options",
    "get_no_canonical_prefixes_opt",
    "get_starlark_list_dict",
    "get_toolchain_identifier",
    "get_tmp_dpcpp_inc_directories",
)

def _find_tool(repo_ctx, tool_name, mandatory = False):
    if tool_name.startswith("C:") or tool_name.startswith("c:"):
        return tool_name
    tool_path = repo_ctx.which(tool_name)
    is_found = tool_path != None
    if not is_found:
        if mandatory:
            auto_configure_fail("Cannot find required tool for Windows: " + tool_name)
        return repo_ctx.path("@onedal//dev/bazel/toolchains/tools:tool_not_found.tpl.bat").realpath
    return tool_path.realpath

def _get_msvc_vars(repo_ctx, msvc_path):
    """Gets the MSVC environment variables."""
    # Try to find vcvarsall.bat
    vcvarsall_path = None
    for vcvars in ["vcvarsall.bat", "vcvars64.bat"]:
        potential_path = paths.join(msvc_path, "VC", "Auxiliary", "Build", vcvars)
        if repo_ctx.path(potential_path).exists:
            vcvarsall_path = potential_path
            break
        # Try older MSVC layout
        potential_path = paths.join(msvc_path, "VC", vcvars)
        if repo_ctx.path(potential_path).exists:
            vcvarsall_path = potential_path
            break

    if not vcvarsall_path:
        auto_configure_fail("Cannot find vcvarsall.bat in " + msvc_path)

    # Run vcvarsall.bat to get environment variables
    result = repo_ctx.execute([
        "cmd", "/c", vcvarsall_path, "x64", "&", "set"
    ])

    if result.return_code != 0:
        auto_configure_fail("Failed to run vcvarsall.bat: " + result.stderr)

    env_vars = {}
    for line in result.stdout.split("\n"):
        if "=" in line:
            key, value = line.strip().split("=", 1)
            env_vars[key] = value

    return env_vars

def _get_compiler_and_linker_paths(repo_ctx):
    """Gets the paths to MSVC compiler and linker."""
    # Try to find MSVC installation
    msvc_path = None

    # Common MSVC installation paths
    potential_paths = [
        "C:\\Program Files\\Microsoft Visual Studio\\2022\\Professional",
        "C:\\Program Files\\Microsoft Visual Studio\\2022\\Enterprise",
        "C:\\Program Files\\Microsoft Visual Studio\\2022\\Community",
        "C:\\Program Files (x86)\\Microsoft Visual Studio\\2019\\Professional",
        "C:\\Program Files (x86)\\Microsoft Visual Studio\\2019\\Enterprise",
        "C:\\Program Files (x86)\\Microsoft Visual Studio\\2019\\Community",
    ]

    for path in potential_paths:
        if repo_ctx.path(path).exists:
            msvc_path = path
            break

    if not msvc_path:
        # Try to use environment variables
        vcinstalldir = repo_ctx.os.environ.get("VCINSTALLDIR")
        if vcinstalldir:
            msvc_path = vcinstalldir
        else:
            auto_configure_fail("Cannot find MSVC installation. Please set VCINSTALLDIR environment variable.")

    env_vars = _get_msvc_vars(repo_ctx, msvc_path)

    # Get compiler and linker paths from environment
    cl_path = _find_tool(repo_ctx, "cl.exe", mandatory = True)
    link_path = _find_tool(repo_ctx, "link.exe", mandatory = True)
    lib_path = _find_tool(repo_ctx, "lib.exe", mandatory = True)

    return {
        "cl": cl_path,
        "link": link_path,
        "lib": lib_path,
        "env": env_vars,
    }

def _get_windows_kit_paths(repo_ctx):
    """Gets Windows SDK paths."""
    # Common Windows SDK paths
    sdk_paths = [
        "C:\\Program Files (x86)\\Windows Kits\\10",
        "C:\\Program Files\\Windows Kits\\10",
    ]

    sdk_path = None
    for path in sdk_paths:
        if repo_ctx.path(path).exists:
            sdk_path = path
            break

    if not sdk_path:
        windowssdkdir = repo_ctx.os.environ.get("WindowsSDKDir")
        if windowssdkdir:
            sdk_path = windowssdkdir
        else:
            utils.warn("Cannot find Windows SDK")
            return {}

    # Find the latest SDK version
    include_path = paths.join(sdk_path, "Include")
    versions = []
    if repo_ctx.path(include_path).exists:
        for item in repo_ctx.path(include_path).readdir():
            if item.basename.startswith("10."):
                versions.append(item.basename)

    if not versions:
        utils.warn("Cannot find Windows SDK version")
        return {}

    latest_version = sorted(versions)[-1]

    return {
        "path": sdk_path,
        "version": latest_version,
        "include": paths.join(sdk_path, "Include", latest_version),
        "lib": paths.join(sdk_path, "Lib", latest_version),
    }

def _get_cxx_inc_directories_win(repo_ctx, tools):
    """Gets C++ include directories for Windows."""
    inc_dirs = []

    # MSVC include directories
    if "INCLUDE" in tools["env"]:
        for path in tools["env"]["INCLUDE"].split(";"):
            if path.strip():
                inc_dirs.append(path.strip())

    # Windows SDK include directories
    sdk_info = _get_windows_kit_paths(repo_ctx)
    if sdk_info:
        inc_dirs.extend([
            paths.join(sdk_info["include"], "um"),
            paths.join(sdk_info["include"], "shared"),
            paths.join(sdk_info["include"], "ucrt"),
        ])

    return inc_dirs

def _get_lib_directories_win(repo_ctx, tools):
    """Gets library directories for Windows."""
    lib_dirs = []

    # MSVC library directories
    if "LIB" in tools["env"]:
        for path in tools["env"]["LIB"].split(";"):
            if path.strip():
                lib_dirs.append(path.strip())

    # Windows SDK library directories
    sdk_info = _get_windows_kit_paths(repo_ctx)
    if sdk_info:
        lib_dirs.extend([
            paths.join(sdk_info["lib"], "um", "x64"),
            paths.join(sdk_info["lib"], "ucrt", "x64"),
        ])

    return lib_dirs

def _get_default_compiler_options_win(repo_ctx, cpu):
    """Gets default compiler options for Windows."""
    options = [
        "/std:c++17",
        "/EHsc",
        "/bigobj",
        "/nologo",
        "/DWIN32",
        "/D_WINDOWS",
        "/D_CRT_SECURE_NO_WARNINGS",
        "/D_SCL_SECURE_NO_WARNINGS",
        "/DNOMINMAX",
    ]

    # Add CPU-specific options
    cpu_options = get_cpu_specific_options(cpu)
    if cpu_options:
        options.extend(cpu_options)

    return options

def _get_default_linker_options_win(repo_ctx):
    """Gets default linker options for Windows."""
    return [
        "/NOLOGO",
        "/SUBSYSTEM:CONSOLE",
        "/MACHINE:X64",
    ]

def _impl_cc_autoconf_win(repo_ctx):
    repo_ctx.report_progress("Looking for C++ compiler on Windows")

    # Get compiler and linker tools
    tools = _get_compiler_and_linker_paths(repo_ctx)

    # CPU detection for Windows
    cpu = repo_ctx.attr.cpu
    if cpu == "auto":
        # Default to Intel 64-bit
        cpu = "intel64"

    # Include directories
    cxx_inc_dirs = _get_cxx_inc_directories_win(repo_ctx, tools)

    # Library directories
    lib_dirs = _get_lib_directories_win(repo_ctx, tools)

    # Compiler options
    compiler_options = _get_default_compiler_options_win(repo_ctx, cpu)

    # Linker options
    linker_options = _get_default_linker_options_win(repo_ctx)

    # Template substitutions
    template_vars = {
        "%{cc}": tools["cl"],
        "%{cpp}": tools["cl"],
        "%{cxx}": tools["cl"],
        "%{ar}": tools["lib"],
        "%{ld}": tools["link"],
        "%{gcov}": _find_tool(repo_ctx, "gcov"),
        "%{objcopy}": _find_tool(repo_ctx, "objcopy"),
        "%{objdump}": _find_tool(repo_ctx, "objdump"),
        "%{strip}": _find_tool(repo_ctx, "strip"),
        "%{nm}": _find_tool(repo_ctx, "nm"),
        "%{toolchain_identifier}": get_toolchain_identifier("msvc", cpu),
        "%{host_system_name}": "local",
        "%{target_system_name}": "local",
        "%{target_cpu}": cpu,
        "%{target_libc}": "msvcrt",
        "%{compiler}": "msvc",
        "%{abi_version}": "local",
        "%{abi_libc_version}": "local",
        "%{builtin_include_directories}": get_starlark_list(cxx_inc_dirs),
        "%{compile_flags}": get_starlark_list(compiler_options),
        "%{cxx_flags}": get_starlark_list([]),
        "%{link_flags}": get_starlark_list(linker_options),
        "%{opt_compile_flags}": get_starlark_list(["/O2", "/DNDEBUG"]),
        "%{opt_link_flags}": get_starlark_list(["/OPT:REF", "/OPT:ICF"]),
        "%{dbg_compile_flags}": get_starlark_list(["/Od", "/Zi", "/DEBUG"]),
        "%{coverage_compile_flags}": get_starlark_list([]),
        "%{coverage_link_flags}": get_starlark_list([]),
        "%{supports_start_end_lib}": "False",
    }

    # Write the BUILD file
    repo_ctx.template(
        "BUILD",
        Label("@onedal//dev/bazel/toolchains:cc_toolchain_win.tpl.BUILD"),
        template_vars,
    )

cc_autoconf_win = repository_rule(
    implementation = _impl_cc_autoconf_win,
    local = True,
    configure = True,
    attrs = {
        "cpu": attr.string(default = "auto"),
    },
)
