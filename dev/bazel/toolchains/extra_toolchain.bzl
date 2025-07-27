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
load("@onedal//dev/bazel/toolchains:extra_toolchain_lnx.bzl",
    "configure_extra_toolchain_lnx")
load("@onedal//dev/bazel/toolchains:extra_toolchain_win.bzl",
    "extra_toolchain_autoconf_win")

ExtraToolchainInfo = provider(
    fields = [
        "patch_daal_kernel_defines",
    ],
)

def _extra_toolchain_impl(ctx):
    toolchain_info = platform_common.ToolchainInfo(
        extra_toolchain_info = ExtraToolchainInfo(
            patch_daal_kernel_defines = ctx.attr.patch_daal_kernel_defines,
        ),
    )
    return [toolchain_info]

extra_toolchain = rule(
    implementation = _extra_toolchain_impl,
    attrs = {
        "patch_daal_kernel_defines": attr.string(mandatory=True),
    },
)

def _onedal_extra_toolchain_impl(repo_ctx):
    os_id = detect_os(repo_ctx)
    compiler_id = detect_compiler(repo_ctx, os_id)

    if os_id == "lnx":
        configure_extra_toolchain_lnx(repo_ctx, compiler_id)
    elif os_id == "win":
        # For Windows, create a simple toolchain
        repo_ctx.template(
            "BUILD",
            Label("@onedal//dev/bazel/toolchains:extra_toolchain_win.tpl.BUILD"),
            {
                "%{patch_daal_kernel_defines}": str(repo_ctx.path("@onedal//dev/bazel/toolchains/tools:patch_daal_kernel_defines_win.tpl.bat")),
            }
        )
    else:
        fail("Unsupported OS: " + os_id)

onedal_extra_toolchain = repository_rule(
    implementation = _onedal_extra_toolchain_impl,
)

