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
    if tool_name.endswith(".exe") or "\\" in tool_name:
        # Absolute path or Windows executable
        return tool_name, True

    # Look for tool in PATH
    tool_path = repo_ctx.which(tool_name + ".exe")
    if tool_path == None:
        tool_path = repo_ctx.which(tool_name)

    is_found = tool_path != None
    if not is_found:
        if mandatory:
            auto_configure_fail("Cannot find {}; try to correct your $PATH".format(tool_name))
        else:
            repo_ctx.template(
                "tool_not_found.bat",
                Label("@onedal//dev/bazel/toolchains/tools:tool_not_found.tpl.bat"),
                {"%{tool_name}": tool_name},
            )
            tool_path = repo_ctx.path("tool_not_found.bat")
    return str(tool_path), is_found

def find_tool(repo_ctx, tool_name, mandatory = False):
    return _find_tool(repo_ctx, tool_name, mandatory)

def find_tool(repo_ctx, tool_name, mandatory = False):
    return _find_tool(repo_ctx, tool_name, mandatory)

def _create_lib_merge_tool(repo_ctx, lib_path):
    lib_merge_name = "merge_static_libs.bat"
    repo_ctx.template(
        lib_merge_name,
        Label("@onedal//dev/bazel/toolchains/tools:merge_static_libs_win.tpl.bat"),
        {"%{lib_path}": lib_path},
    )
    lib_merge_path = repo_ctx.path(lib_merge_name)
    return str(lib_merge_path)

def _create_dynamic_link_wrapper(repo_ctx, prefix, cc_path):
    wrapper_name = prefix + "_dynamic_link.bat"
    repo_ctx.template(
        wrapper_name,
        Label("@onedal//dev/bazel/toolchains/tools:dynamic_link_win.tpl.bat"),
        {"%{cc_path}": cc_path},
    )
    wrapper_path = repo_ctx.path(wrapper_name)
    return str(wrapper_path)

def _find_vs_path(repo_ctx):
    """Find Visual Studio installation path."""
    # Try common Visual Studio paths
    vs_paths = [
        "C:/Program Files/Microsoft Visual Studio/2022/Professional",
        "C:/Program Files/Microsoft Visual Studio/2022/Enterprise",
        "C:/Program Files/Microsoft Visual Studio/2022/Community",
        "C:/Program Files (x86)/Microsoft Visual Studio/2019/Professional",
        "C:/Program Files (x86)/Microsoft Visual Studio/2019/Enterprise",
        "C:/Program Files (x86)/Microsoft Visual Studio/2019/Community",
    ]

    for vs_path in vs_paths:
        if repo_ctx.path(vs_path).exists:
            return vs_path

    # Try using vswhere if available
    vswhere_path = repo_ctx.which("vswhere.exe")
    if vswhere_path:
        result = repo_ctx.execute([
            vswhere_path,
            "-latest",
            "-products", "*",
            "-requires", "Microsoft.VisualStudio.Component.VC.Tools.x86.x64",
            "-property", "installationPath"
        ])
        if result.return_code == 0 and result.stdout.strip():
            return result.stdout.strip()

    return None

def _setup_msvc_env(repo_ctx, reqs):
    """Setup MSVC environment variables."""
    vs_path = _find_vs_path(repo_ctx)
    if not vs_path:
        auto_configure_fail("Cannot find Visual Studio installation")

    # Try to find vcvarsall.bat
    vcvarsall_path = vs_path + "/VC/Auxiliary/Build/vcvarsall.bat"
    if not repo_ctx.path(vcvarsall_path).exists:
        auto_configure_fail("Cannot find vcvarsall.bat at {}".format(vcvarsall_path))

    # Execute vcvarsall.bat to get environment variables
    arch = "x64" if reqs.target_arch_id == "intel64" else "x86"
    result = repo_ctx.execute([
        "cmd.exe", "/c",
        "\"{}\" {} && set".format(vcvarsall_path, arch)
    ])

    if result.return_code != 0:
        auto_configure_fail("Failed to execute vcvarsall.bat: {}".format(result.stderr))

    # Parse environment variables
    env_vars = {}
    for line in result.stdout.split("\n"):
        if "=" in line:
            key, value = line.split("=", 1)
            env_vars[key.strip()] = value.strip()

    return {
        "PATH": env_vars.get("PATH", ""),
        "INCLUDE": env_vars.get("INCLUDE", ""),
        "LIB": env_vars.get("LIB", ""),
        "TMP": env_vars.get("TMP", "C:/temp"),
    }

def _find_tools(repo_ctx, reqs):
    msvc_env = _setup_msvc_env(repo_ctx, reqs)

    # Find tools
    cl_path, _ = _find_tool(repo_ctx, "cl", mandatory = True)
    link_path, _ = _find_tool(repo_ctx, "link", mandatory = True)
    lib_path, _ = _find_tool(repo_ctx, "lib", mandatory = True)
    ml_path, _ = _find_tool(repo_ctx, "ml64", mandatory = False)
    if not ml_path:
        ml_path, _ = _find_tool(repo_ctx, "ml", mandatory = False)

    # Intel DPC++ compiler
    icx_path, icx_found = _find_tool(repo_ctx, reqs.dpc_compiler_id, mandatory = False)

    # Create wrapper scripts
    cl_link_path = _create_dynamic_link_wrapper(repo_ctx, "cl", cl_path)
    icx_link_path = _create_dynamic_link_wrapper(repo_ctx, "icx", icx_path) if icx_found else cl_link_path
    lib_merge_path = _create_lib_merge_tool(repo_ctx, lib_path)

    return struct(
        cc = cl_path,
        dpc = icx_path if icx_found else cl_path,
        link = link_path,
        ar = lib_path,
        ar_merge = lib_merge_path,
        asm = ml_path,
        cc_link = cl_link_path,
        dpc_link = icx_link_path,
        strip = "echo",  # No strip equivalent in Windows
        nm = "dumpbin",
        objdump = "dumpbin",
        gcov = "echo",
        cpp = cl_path,
        msvc_env = msvc_env,
    )

def _get_windows_compile_flags(repo_ctx, reqs, tools):
    """Get Windows-specific compile flags."""
    flags = [
        "/DWIN32",
        "/D_WINDOWS",
        "/W3",
        "/GR",  # Enable RTTI
        "/EHsc",  # Enable C++ exceptions
        "/bigobj",  # Allow large object files
        "/nologo",  # Suppress startup banner
    ]

    # Architecture-specific flags
    if reqs.target_arch_id == "intel64":
        flags.append("/D_WIN64")

    # Add Intel-specific flags if using Intel compiler
    if reqs.compiler_id == "icx":
        flags.extend([
            "/Qstd=c++17",
            "/Qipo-",  # Disable IPO by default
        ])
    else:
        flags.extend([
            "/std:c++17",
        ])

    return flags

def _get_windows_link_flags(repo_ctx, reqs, tools):
    """Get Windows-specific link flags."""
    flags = [
        "/SUBSYSTEM:CONSOLE",
        "/MACHINE:X64" if reqs.target_arch_id == "intel64" else "/MACHINE:X86",
        "/nologo",
    ]

    return flags

def _get_cxx_include_directories_win(repo_ctx, reqs, tools):
    """Get C++ include directories for Windows."""
    include_dirs = []

    # Add MSVC include directories
    msvc_include = tools.msvc_env.get("INCLUDE", "")
    if msvc_include:
        for inc_dir in msvc_include.split(";"):
            if inc_dir.strip():
                include_dirs.append(inc_dir.strip().replace("\\", "/"))

    # Add Intel compiler include directories if available
    if reqs.dpc_compiler_id == "icx" and tools.dpc != tools.cc:
        # Try to get Intel include directories
        result = repo_ctx.execute([tools.dpc, "/showIncludes", "/c", "/EP", "/Tp", TEST_CPP_FILE])
        if result.return_code == 0:
            # Parse Intel-specific includes
            pass

    return include_dirs

def configure_cc_toolchain_win(repo_ctx, reqs):
    """Configure Windows C++ toolchain."""

    # Find tools
    tools = _find_tools(repo_ctx, reqs)

    # Get compilation flags
    compile_flags = _get_windows_compile_flags(repo_ctx, reqs, tools)
    cxx_flags = []  # C++-specific flags are included in compile_flags
    link_flags = _get_windows_link_flags(repo_ctx, reqs, tools)

    # Get include directories
    cxx_builtin_include_directories = _get_cxx_include_directories_win(repo_ctx, reqs, tools)

    # Create toolchain identifier
    toolchain_identifier = get_toolchain_identifier(reqs)

    # Template BUILD file
    repo_ctx.template(
        "BUILD",
        Label("@onedal//dev/bazel/toolchains:cc_toolchain_win.tpl.BUILD"),
        {
            "%{cc_toolchain_identifier}": toolchain_identifier,
            "%{name}": "cc-compiler-" + reqs.compiler_id,
            "%{modulename}": "cc_toolchain_" + reqs.compiler_id,
            "%{cpu}": reqs.target_arch_id,
            "%{compiler}": reqs.compiler_id,
            "%{abi_version}": reqs.compiler_abi_version,
            "%{abi_libc_version}": reqs.libc_abi_version,
            "%{host_system_name}": reqs.os_id,
            "%{target_system_name}": reqs.os_id,
            "%{target_libc}": reqs.libc_version,
            "%{builtin_sysroot}": "",
            "%{compile_flags}": get_starlark_list(compile_flags),
            "%{cxx_flags}": get_starlark_list(cxx_flags),
            "%{link_flags}": get_starlark_list(link_flags),
            "%{cxx_builtin_include_directories}": get_starlark_list(cxx_builtin_include_directories),
            "%{tool_paths}": get_starlark_list_dict({
                "gcc": tools.cc,
                "ld": tools.link,
                "ar": tools.ar,
                "ar_merge": tools.ar_merge,
                "cpp": tools.cpp,
                "gcov": tools.gcov,
                "nm": tools.nm,
                "objdump": tools.objdump,
                "strip": tools.strip,
            }),
            "%{msvc_env_path}": tools.msvc_env.get("PATH", ""),
            "%{msvc_env_include}": tools.msvc_env.get("INCLUDE", ""),
            "%{msvc_env_lib}": tools.msvc_env.get("LIB", ""),
            "%{msvc_env_tmp}": tools.msvc_env.get("TMP", ""),
        },
    )
