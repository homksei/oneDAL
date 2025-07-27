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
    "@rules_cc//cc:action_names.bzl",
    "ACTION_NAMES",
)
load(
    "@rules_cc//cc:cc_toolchain_config_lib.bzl",
    "feature",
    "flag_group",
    "flag_set",
    "tool_path",
    "variable_with_value",
    "with_feature_set",
)

def _impl(ctx):
    tool_paths = [
        tool_path(
            name = name,
            path = path,
        )
        for name, path in ctx.attr.tool_paths.items()
    ]

    features = [
        feature(
            name = "default_compile_flags",
            enabled = True,
            flag_sets = [
                flag_set(
                    actions = [
                        ACTION_NAMES.assemble,
                        ACTION_NAMES.preprocess_assemble,
                        ACTION_NAMES.linkstamp_compile,
                        ACTION_NAMES.c_compile,
                        ACTION_NAMES.cpp_compile,
                        ACTION_NAMES.cpp_header_parsing,
                        ACTION_NAMES.cpp_module_compile,
                        ACTION_NAMES.cpp_module_codegen,
                        ACTION_NAMES.lto_backend,
                        ACTION_NAMES.clif_match,
                    ],
                    flag_groups = [
                        flag_group(
                            flags = ctx.attr.compile_flags if ctx.attr.compile_flags else ["/nologo"],
                        ),
                    ],
                ),
            ],
        ),
        feature(
            name = "default_cxx_flags",
            enabled = True,
            flag_sets = [
                flag_set(
                    actions = [
                        ACTION_NAMES.cpp_compile,
                        ACTION_NAMES.cpp_header_parsing,
                        ACTION_NAMES.cpp_module_compile,
                        ACTION_NAMES.cpp_module_codegen,
                        ACTION_NAMES.lto_backend,
                        ACTION_NAMES.clif_match,
                    ],
                    flag_groups = [
                        flag_group(
                            flags = ctx.attr.cxx_flags if ctx.attr.cxx_flags else ["/std:c++17"],
                        ),
                    ],
                ),
            ],
        ),
        feature(
            name = "default_link_flags",
            enabled = True,
            flag_sets = [
                flag_set(
                    actions = [
                        ACTION_NAMES.cpp_link_executable,
                        ACTION_NAMES.cpp_link_dynamic_library,
                        ACTION_NAMES.cpp_link_nodeps_dynamic_library,
                    ],
                    flag_groups = [
                        flag_group(
                            flags = ctx.attr.link_flags if ctx.attr.link_flags else ["/NOLOGO"],
                        ),
                    ],
                ),
            ],
        ),
        feature(
            name = "opt",
            flag_sets = [
                flag_set(
                    actions = [
                        ACTION_NAMES.assemble,
                        ACTION_NAMES.preprocess_assemble,
                        ACTION_NAMES.linkstamp_compile,
                        ACTION_NAMES.c_compile,
                        ACTION_NAMES.cpp_compile,
                        ACTION_NAMES.cpp_header_parsing,
                        ACTION_NAMES.cpp_module_compile,
                        ACTION_NAMES.cpp_module_codegen,
                        ACTION_NAMES.lto_backend,
                        ACTION_NAMES.clif_match,
                    ],
                    flag_groups = [
                        flag_group(
                            flags = ctx.attr.opt_compile_flags if ctx.attr.opt_compile_flags else ["/O2"],
                        ),
                    ],
                ),
                flag_set(
                    actions = [
                        ACTION_NAMES.cpp_link_executable,
                        ACTION_NAMES.cpp_link_dynamic_library,
                        ACTION_NAMES.cpp_link_nodeps_dynamic_library,
                    ],
                    flag_groups = [
                        flag_group(
                            flags = ctx.attr.opt_link_flags if ctx.attr.opt_link_flags else ["/OPT:REF"],
                        ),
                    ],
                ),
            ],
        ),
        feature(
            name = "dbg",
            flag_sets = [
                flag_set(
                    actions = [
                        ACTION_NAMES.assemble,
                        ACTION_NAMES.preprocess_assemble,
                        ACTION_NAMES.linkstamp_compile,
                        ACTION_NAMES.c_compile,
                        ACTION_NAMES.cpp_compile,
                        ACTION_NAMES.cpp_header_parsing,
                        ACTION_NAMES.cpp_module_compile,
                        ACTION_NAMES.cpp_module_codegen,
                        ACTION_NAMES.lto_backend,
                        ACTION_NAMES.clif_match,
                    ],
                    flag_groups = [
                        flag_group(
                            flags = ctx.attr.dbg_compile_flags if ctx.attr.dbg_compile_flags else ["/Od", "/Z7"],
                        ),
                    ],
                ),
            ],
        ),
        feature(
            name = "supports_dynamic_linker",
            enabled = True,
        ),
        feature(
            name = "windows_export_all_symbols",
            enabled = True,
        ),
        feature(
            name = "no_legacy_features",
            enabled = True,
        ),
        feature(
            name = "parse_showincludes",
            enabled = True,
        ),
    ]

    if ctx.attr.coverage_compile_flags or ctx.attr.coverage_link_flags:
        coverage_flag_sets = []

        if ctx.attr.coverage_compile_flags:
            coverage_flag_sets.append(
                flag_set(
                    actions = [
                        ACTION_NAMES.preprocess_assemble,
                        ACTION_NAMES.c_compile,
                        ACTION_NAMES.cpp_compile,
                        ACTION_NAMES.cpp_header_parsing,
                        ACTION_NAMES.cpp_module_compile,
                    ],
                    flag_groups = [
                        flag_group(
                            flags = ctx.attr.coverage_compile_flags,
                        ),
                    ],
                )
            )

        if ctx.attr.coverage_link_flags:
            coverage_flag_sets.append(
                flag_set(
                    actions = [
                        ACTION_NAMES.cpp_link_executable,
                        ACTION_NAMES.cpp_link_dynamic_library,
                    ],
                    flag_groups = [
                        flag_group(
                            flags = ctx.attr.coverage_link_flags,
                        ),
                    ],
                )
            )

        if coverage_flag_sets:
            features.append(
                feature(
                    name = "coverage",
                    provides = ["profile"],
                    flag_sets = coverage_flag_sets,
                ),
            )

    return cc_common.create_cc_toolchain_config_info(
        ctx = ctx,
        features = features,
        cxx_builtin_include_directories = ctx.attr.builtin_include_directories,
        toolchain_identifier = ctx.attr.toolchain_identifier,
        host_system_name = ctx.attr.host_system_name,
        target_system_name = ctx.attr.target_system_name,
        target_cpu = ctx.attr.cpu,
        target_libc = ctx.attr.target_libc,
        compiler = ctx.attr.compiler,
        abi_version = ctx.attr.abi_version,
        abi_libc_version = ctx.attr.abi_libc_version,
        tool_paths = tool_paths,
    )

cc_toolchain_config = rule(
    implementation = _impl,
    attrs = {
        "cpu": attr.string(mandatory = True),
        "compiler": attr.string(mandatory = True),
        "toolchain_identifier": attr.string(mandatory = True),
        "host_system_name": attr.string(mandatory = True),
        "target_system_name": attr.string(mandatory = True),
        "target_libc": attr.string(mandatory = True),
        "abi_version": attr.string(mandatory = True),
        "abi_libc_version": attr.string(mandatory = True),
        "tool_paths": attr.string_dict(mandatory = True),
        "compile_flags": attr.string_list(),
        "cxx_flags": attr.string_list(),
        "link_flags": attr.string_list(),
        "opt_compile_flags": attr.string_list(),
        "opt_link_flags": attr.string_list(),
        "dbg_compile_flags": attr.string_list(),
        "coverage_compile_flags": attr.string_list(),
        "coverage_link_flags": attr.string_list(),
        "builtin_include_directories": attr.string_list(),
        "supports_start_end_lib": attr.bool(),
    },
    provides = [CcToolchainConfigInfo],
)
