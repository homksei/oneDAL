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

package(default_visibility = ["//visibility:public"])

load("@onedal//dev/bazel/toolchains:cc_toolchain_config_win.bzl", "cc_toolchain_config_win")

cc_toolchain_config_win(
    name = "cc_toolchain_config",
    cpu = "%{cpu}",
    compiler = "%{compiler}",
    toolchain_identifier = "%{cc_toolchain_identifier}",
    host_system_name = "%{host_system_name}",
    target_system_name = "%{target_system_name}",
    target_libc = "%{target_libc}",
    abi_version = "%{abi_version}",
    abi_libc_version = "%{abi_libc_version}",
    tool_paths = %{tool_paths},
    compile_flags = %{compile_flags},
    cxx_flags = %{cxx_flags},
    link_flags = %{link_flags},
    cxx_builtin_include_directories = %{cxx_builtin_include_directories},
    builtin_sysroot = "%{builtin_sysroot}",
    msvc_env_path = "%{msvc_env_path}",
    msvc_env_include = "%{msvc_env_include}",
    msvc_env_lib = "%{msvc_env_lib}",
    msvc_env_tmp = "%{msvc_env_tmp}",
)

filegroup(name = "empty")

cc_toolchain(
    name = "%{name}",
    toolchain_identifier = "%{cc_toolchain_identifier}",
    toolchain_config = ":cc_toolchain_config",
    all_files = ":empty",
    compiler_files = ":empty",
    dwp_files = ":empty",
    linker_files = ":empty",
    objcopy_files = ":empty",
    strip_files = ":empty",
    supports_param_files = 1,
)
