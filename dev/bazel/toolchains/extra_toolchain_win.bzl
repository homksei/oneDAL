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

def _find_tool(repo_ctx, tool_name):
    if tool_name.startswith("C:") or tool_name.startswith("c:"):
        return tool_name
    tool_path = repo_ctx.which(tool_name)
    if tool_path:
        return tool_path.realpath
    return repo_ctx.path("@onedal//dev/bazel/toolchains/tools:tool_not_found.tpl.bat").realpath

def _impl_extra_toolchain_win(repo_ctx):
    repo_ctx.report_progress("Looking for extra tools on Windows")

    # Find tools
    merge_static_libs = _find_tool(repo_ctx, "lib.exe")
    dynamic_link = _find_tool(repo_ctx, "link.exe")
    patch_daal_kernel_defines = str(repo_ctx.path("@onedal//dev/bazel/toolchains/tools:patch_daal_kernel_defines_win.tpl.bat"))

    # Template substitutions
    template_vars = {
        "%{merge_static_libs}": str(repo_ctx.path("@onedal//dev/bazel/toolchains/tools:merge_static_libs_win.tpl.bat")),
        "%{dynamic_link}": str(repo_ctx.path("@onedal//dev/bazel/toolchains/tools:dynamic_link_win.tpl.bat")),
        "%{patch_daal_kernel_defines}": patch_daal_kernel_defines,
    }

    # Write the BUILD file
    repo_ctx.template(
        "BUILD",
        Label("@onedal//dev/bazel/toolchains:extra_toolchain_win.tpl.BUILD"),
        template_vars,
    )

extra_toolchain_autoconf_win = repository_rule(
    implementation = _impl_extra_toolchain_win,
    local = True,
    configure = True,
)
