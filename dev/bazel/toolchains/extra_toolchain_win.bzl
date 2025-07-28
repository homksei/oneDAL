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

def configure_extra_toolchain_win(repo_ctx, reqs):
    repo_ctx.template(
        "BUILD",
        Label("@onedal//dev/bazel/toolchains:extra_toolchain_win.tpl.BUILD"),
        substitutions = {
            "%{toolchain_identifier}": "win-{}-{}-{}".format(
                reqs.target_arch_id, reqs.compiler_id, reqs.compiler_version
            ),
            "%{target_arch_id}": reqs.target_arch_id,
            "%{os_id}": reqs.os_id,
            "%{compiler_id}": reqs.compiler_id,
            "%{compiler_version}": reqs.compiler_version,
        },
        executable = False,
    )
