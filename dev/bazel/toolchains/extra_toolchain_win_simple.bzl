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

def configure_extra_toolchain_win(repo_ctx, compiler_id):
    """Configure extra toolchain for Windows"""
    patch_daal_kernel_defines_path = str(repo_ctx.path("@onedal//dev/bazel/toolchains/tools:patch_daal_kernel_defines_win.tpl.bat"))

    # Template substitutions for Windows toolchain
    substitutions = {
        "%{patch_daal_kernel_defines}": patch_daal_kernel_defines_path,
        "%{compiler_id}": compiler_id,  # Include compiler info for potential future use
    }

    repo_ctx.template(
        "BUILD",
        Label("@onedal//dev/bazel/toolchains:extra_toolchain_win.tpl.BUILD"),
        substitutions
    )
