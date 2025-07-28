#===============================================================================
# Copyright contributors to the oneDAL project
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
)
load(
    "@onedal//dev/bazel:utils.bzl",
    "paths",
)
load(
    "@onedal//dev/bazel/toolchains:common.bzl",
    "escape_string_for_starlark",
    "get_cpu_specific_options",
    "get_default_compiler_options",
    "get_starlark_list_dict",
    "get_starlark_list_safe",
    "get_toolchain_identifier",
)

def _find_tool_win(repo_ctx, tool_name, mandatory = False):
    """Find a tool on Windows. Check both .exe and no extension versions."""
    if tool_name.startswith("C:") or tool_name.startswith("c:"):
        return tool_name, True

    # Try tool_name.exe first, then tool_name
    for name in [tool_name + ".exe", tool_name]:
        tool_path = repo_ctx.which(name)
        if tool_path != None:
            return str(tool_path), True

    if mandatory:
        auto_configure_fail("Cannot find {}; try to correct your %PATH%".format(tool_name))
    else:
        repo_ctx.template(
            "tool_not_found.bat",
            Label("@onedal//dev/bazel/toolchains/tools:tool_not_found.tpl.bat"),
            {"%{tool_name}": tool_name},
        )
        tool_path = repo_ctx.path("tool_not_found.bat")
        return str(tool_path), False

def _find_tools_win(repo_ctx, reqs):
    compiler_id = reqs.compiler_id

    if compiler_id == "cl":
        # Microsoft Visual C++
        cc_path, _ = _find_tool_win(repo_ctx, "cl", mandatory = True)
        lib_path, _ = _find_tool_win(repo_ctx, "lib", mandatory = True)
        link_path, _ = _find_tool_win(repo_ctx, "link", mandatory = True)
        ml64_path, _ = _find_tool_win(repo_ctx, "ml64", mandatory = False)
        rc_path, _ = _find_tool_win(repo_ctx, "rc", mandatory = False)
    elif compiler_id == "icx":
        # Intel C++ Compiler
        cc_path, _ = _find_tool_win(repo_ctx, "icx", mandatory = True)
        lib_path, _ = _find_tool_win(repo_ctx, "lib", mandatory = True)
        link_path, _ = _find_tool_win(repo_ctx, "xilink", mandatory = False)
        if not link_path or not _find_tool_win(repo_ctx, "xilink")[1]:
            link_path, _ = _find_tool_win(repo_ctx, "link", mandatory = True)
        ml64_path, _ = _find_tool_win(repo_ctx, "ml64", mandatory = False)
        rc_path, _ = _find_tool_win(repo_ctx, "rc", mandatory = False)
    elif compiler_id == "icpx":
        # Intel DPC++ Compiler
        cc_path, _ = _find_tool_win(repo_ctx, "icpx", mandatory = True)
        lib_path, _ = _find_tool_win(repo_ctx, "lib", mandatory = True)
        link_path, _ = _find_tool_win(repo_ctx, "xilink", mandatory = False)
        if not link_path or not _find_tool_win(repo_ctx, "xilink")[1]:
            link_path, _ = _find_tool_win(repo_ctx, "link", mandatory = True)
        ml64_path, _ = _find_tool_win(repo_ctx, "ml64", mandatory = False)
        rc_path, _ = _find_tool_win(repo_ctx, "rc", mandatory = False)
    else:
        auto_configure_fail("Unsupported Windows compiler: {}".format(compiler_id))

    # DPC++ compiler detection
    dpcc_path, dpcpp_found = _find_tool_win(repo_ctx, reqs.dpc_compiler_id, mandatory = False)

    return struct(
        cc = cc_path,
        lib = lib_path,
        link = link_path,
        ml64 = ml64_path,
        rc = rc_path,
        dpcc = dpcc_path if dpcpp_found else "",
        dpcpp_found = dpcpp_found,
    )

def _get_builtin_include_directories_win(repo_ctx, tools, reqs):
    """Get include directories for Windows."""
    builtin_include_directories = []

    # Get standard includes from INCLUDE environment variable
    include_env = repo_ctx.os.environ.get("INCLUDE", "")
    if include_env:
        for path in include_env.split(";"):
            if path.strip():
                builtin_include_directories.append(path.strip())

    # Add some common Windows SDK paths if not found
    if not builtin_include_directories:
        common_includes = [
            "C:\\Program Files (x86)\\Windows Kits\\10\\Include\\10.0.19041.0\\ucrt",
            "C:\\Program Files (x86)\\Windows Kits\\10\\Include\\10.0.19041.0\\shared",
            "C:\\Program Files (x86)\\Windows Kits\\10\\Include\\10.0.19041.0\\um",
            "C:\\Program Files (x86)\\Microsoft Visual Studio\\2019\\Professional\\VC\\Tools\\MSVC\\14.29.30133\\include",
        ]
        for path in common_includes:
            if repo_ctx.path(path).exists:
                builtin_include_directories.append(path)

    return builtin_include_directories

def _get_system_lib_directories_win(repo_ctx, tools, reqs):
    """Get system library directories for Windows."""
    system_lib_directories = []

    # Get library directories from LIB environment variable
    lib_env = repo_ctx.os.environ.get("LIB", "")
    if lib_env:
        for path in lib_env.split(";"):
            if path.strip():
                system_lib_directories.append(path.strip())

    # Add some common Windows SDK lib paths if not found
    if not system_lib_directories:
        common_libs = [
            "C:\\Program Files (x86)\\Windows Kits\\10\\Lib\\10.0.19041.0\\ucrt\\x64",
            "C:\\Program Files (x86)\\Windows Kits\\10\\Lib\\10.0.19041.0\\um\\x64",
            "C:\\Program Files (x86)\\Microsoft Visual Studio\\2019\\Professional\\VC\\Tools\\MSVC\\14.29.30133\\lib\\x64",
        ]
        for path in common_libs:
            if repo_ctx.path(path).exists:
                system_lib_directories.append(path)

    return system_lib_directories

def configure_cc_toolchain_win(repo_ctx, reqs):
    tools = _find_tools_win(repo_ctx, reqs)
    toolchain_identifier = get_toolchain_identifier(reqs)

    # Get include and library directories
    builtin_include_directories = _get_builtin_include_directories_win(repo_ctx, tools, reqs)
    system_lib_directories = _get_system_lib_directories_win(repo_ctx, tools, reqs)

    # Get compiler options
    common_options = get_default_compiler_options(repo_ctx, reqs, tools.cc, False, "common")
    pedantic_options = get_default_compiler_options(repo_ctx, reqs, tools.cc, False, "pedantic")

    dpcc_common_options = []
    dpcc_pedantic_options = []
    if tools.dpcpp_found:
        dpcc_common_options = get_default_compiler_options(repo_ctx, reqs, tools.dpcc, True, "common")
        dpcc_pedantic_options = get_default_compiler_options(repo_ctx, reqs, tools.dpcc, True, "pedantic")

    # Get CPU-specific options
    cpu_options = get_cpu_specific_options(reqs, False)
    dpcc_cpu_options = get_cpu_specific_options(reqs, True) if tools.dpcpp_found else {}

    # Template the BUILD file
    repo_ctx.template(
        "BUILD",
        Label("@onedal//dev/bazel/toolchains:cc_toolchain_win.tpl.BUILD"),
        substitutions = {
            "%{cc_path}": tools.cc.replace("\\", "/"),
            "%{dpcc_path}": tools.dpcc.replace("\\", "/"),
            "%{link_path}": tools.link.replace("\\", "/"),
            "%{lib_path}": tools.lib.replace("\\", "/"),
            "%{ml64_path}": tools.ml64.replace("\\", "/"),
            "%{rc_path}": tools.rc.replace("\\", "/"),
            "%{vcvars_path}": "",
            "%{toolchain_identifier}": toolchain_identifier,
            "%{host_system_name}": "local",
            "%{target_system_name}": "local",
            "%{target_cpu}": reqs.target_arch_id,
            "%{target_libc}": "msvcrt",
            "%{compiler}": reqs.compiler_id,
            "%{abi_version}": reqs.compiler_abi_version,
            "%{abi_libc_version}": reqs.libc_abi_version,
            "%{cc_target_os}": "windows",
            "%{builtin_sysroot}": "",
            "%{cxx_builtin_include_directories}": get_starlark_list_safe(builtin_include_directories),
            "%{tool_bin_path}": paths.dirname(tools.cc).replace("\\", "/"),
            "%{common_options}": get_starlark_list_safe(common_options),
            "%{pedantic_options}": get_starlark_list_safe(pedantic_options),
            "%{dpcc_common_options}": get_starlark_list_safe(dpcc_common_options),
            "%{dpcc_pedantic_options}": get_starlark_list_safe(dpcc_pedantic_options),
            "%{cpu_options}": get_starlark_list_dict(cpu_options),
            "%{dpcc_cpu_options}": get_starlark_list_dict(dpcc_cpu_options),
            "%{system_lib_directories}": get_starlark_list_safe(system_lib_directories),
        },
        executable = False,
    )
