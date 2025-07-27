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

load("@bazel_tools//tools/cpp:cc_toolchain_config_lib.bzl",
    "feature",
    "feature_set",
    "flag_group",
    "flag_set",
    "tool_path",
    "variable_with_value",
    "with_feature_set",
    "action_config",
    "tool",
    "artifact_name_pattern",
    "env_set",
    "env_entry",
)
load("@bazel_tools//tools/build_defs/cc:action_names.bzl", "ACTION_NAMES")
load("@onedal//dev/bazel/toolchains:action_names.bzl", "CPP_MERGE_STATIC_LIBRARIES")

all_compile_actions = [
    ACTION_NAMES.c_compile,
    ACTION_NAMES.cpp_compile,
    ACTION_NAMES.linkstamp_compile,
    ACTION_NAMES.assemble,
    ACTION_NAMES.preprocess_assemble,
    ACTION_NAMES.cpp_header_parsing,
    ACTION_NAMES.cpp_module_compile,
    ACTION_NAMES.cpp_module_codegen,
    ACTION_NAMES.clif_match,
    ACTION_NAMES.lto_backend,
]

all_cpp_compile_actions = [
    ACTION_NAMES.cpp_compile,
    ACTION_NAMES.linkstamp_compile,
    ACTION_NAMES.cpp_header_parsing,
    ACTION_NAMES.cpp_module_compile,
    ACTION_NAMES.cpp_module_codegen,
]

preprocessor_compile_actions = [
    ACTION_NAMES.c_compile,
    ACTION_NAMES.cpp_compile,
    ACTION_NAMES.linkstamp_compile,
    ACTION_NAMES.preprocess_assemble,
    ACTION_NAMES.cpp_header_parsing,
    ACTION_NAMES.cpp_module_compile,
]

codegen_compile_actions = [
    ACTION_NAMES.c_compile,
    ACTION_NAMES.cpp_compile,
    ACTION_NAMES.linkstamp_compile,
    ACTION_NAMES.assemble,
    ACTION_NAMES.preprocess_assemble,
    ACTION_NAMES.cpp_module_codegen,
    ACTION_NAMES.lto_backend,
]

all_link_actions = [
    ACTION_NAMES.cpp_link_executable,
    ACTION_NAMES.cpp_link_dynamic_library,
    ACTION_NAMES.cpp_link_nodeps_dynamic_library,
]

lto_index_actions = [
    ACTION_NAMES.lto_index_for_executable,
    ACTION_NAMES.lto_index_for_dynamic_library,
    ACTION_NAMES.lto_index_for_nodeps_dynamic_library,
]

def _impl(ctx):
    tool_paths = [
        tool_path(
            name = "gcc",
            path = ctx.attr.tool_paths["gcc"],
        ),
        tool_path(
            name = "ld",
            path = ctx.attr.tool_paths["ld"],
        ),
        tool_path(
            name = "ar",
            path = ctx.attr.tool_paths["ar"],
        ),
        tool_path(
            name = "cpp",
            path = ctx.attr.tool_paths["cpp"],
        ),
        tool_path(
            name = "gcov",
            path = ctx.attr.tool_paths["gcov"],
        ),
        tool_path(
            name = "nm",
            path = ctx.attr.tool_paths["nm"],
        ),
        tool_path(
            name = "objdump",
            path = ctx.attr.tool_paths["objdump"],
        ),
        tool_path(
            name = "strip",
            path = ctx.attr.tool_paths["strip"],
        ),
    ]

    default_compile_flags_feature = feature(
        name = "default_compile_flags",
        enabled = True,
        flag_sets = [
            flag_set(
                actions = all_compile_actions,
                flag_groups = ([
                    flag_group(
                        flags = ctx.attr.compile_flags,
                    ),
                ]),
            ),
            flag_set(
                actions = all_cpp_compile_actions,
                flag_groups = ([
                    flag_group(
                        flags = ctx.attr.cxx_flags,
                    ),
                ]),
            ),
        ],
    )

    default_link_flags_feature = feature(
        name = "default_link_flags",
        enabled = True,
        flag_sets = [
            flag_set(
                actions = all_link_actions,
                flag_groups = ([
                    flag_group(
                        flags = ctx.attr.link_flags,
                    ),
                ]),
            ),
        ],
    )

    windows_features = [
        feature(name = "no_legacy_features"),
        feature(
            name = "targets_windows",
            implies = ["copy_dynamic_libraries_to_binary"],
            enabled = True,
        ),
        feature(name = "copy_dynamic_libraries_to_binary"),
        feature(
            name = "supports_dynamic_linker",
            enabled = True,
        ),
        feature(
            name = "supports_interface_shared_libraries",
            enabled = True,
        ),
        feature(
            name = "has_configured_linker_path",
            enabled = True,
        ),
    ]

    # MSVC specific features
    msvc_compile_env_feature = feature(
        name = "msvc_compile_env",
        enabled = True,
        env_sets = [
            env_set(
                actions = all_compile_actions + all_link_actions,
                env_entries = [
                    env_entry(key = "PATH", value = ctx.attr.msvc_env_path),
                    env_entry(key = "INCLUDE", value = ctx.attr.msvc_env_include),
                    env_entry(key = "LIB", value = ctx.attr.msvc_env_lib),
                    env_entry(key = "TMP", value = ctx.attr.msvc_env_tmp),
                    env_entry(key = "TEMP", value = ctx.attr.msvc_env_tmp),
                ],
            ),
        ],
    )

    # Windows-specific artifact patterns
    artifact_name_patterns = [
        artifact_name_pattern(
            category_name = "executable",
            prefix = "",
            extension = ".exe",
        ),
        artifact_name_pattern(
            category_name = "static_library",
            prefix = "",
            extension = ".lib",
        ),
        artifact_name_pattern(
            category_name = "dynamic_library",
            prefix = "",
            extension = ".dll",
        ),
        artifact_name_pattern(
            category_name = "interface_library",
            prefix = "",
            extension = ".if.lib",
        ),
    ]

    # Archiver feature for Windows
    archiver_flags_feature = feature(
        name = "archiver_flags",
        enabled = True,
        flag_sets = [
            flag_set(
                actions = [ACTION_NAMES.cpp_link_static_library],
                flag_groups = [
                    flag_group(
                        expand_if_available = "output_execpath",
                        flags = ["/OUT:%{output_execpath}"],
                    ),
                ],
            ),
        ],
    )

    # Custom static library merging action for Windows
    merge_static_libraries = action_config(
        action_name = CPP_MERGE_STATIC_LIBRARIES,
        enabled = True,
        tools = [tool(path = ctx.attr.tool_paths["ar_merge"])],
    )

    features = [
        default_compile_flags_feature,
        default_link_flags_feature,
        msvc_compile_env_feature,
        archiver_flags_feature,
    ] + windows_features

    action_configs = [merge_static_libraries]

    return cc_common.create_cc_toolchain_config_info(
        ctx = ctx,
        features = features,
        action_configs = action_configs,
        artifact_name_patterns = artifact_name_patterns,
        cxx_builtin_include_directories = ctx.attr.cxx_builtin_include_directories,
        toolchain_identifier = ctx.attr.toolchain_identifier,
        host_system_name = ctx.attr.host_system_name,
        target_system_name = ctx.attr.target_system_name,
        target_cpu = ctx.attr.cpu,
        target_libc = ctx.attr.target_libc,
        compiler = ctx.attr.compiler,
        abi_version = ctx.attr.abi_version,
        abi_libc_version = ctx.attr.abi_libc_version,
        tool_paths = tool_paths,
        make_variables = [],
        builtin_sysroot = ctx.attr.builtin_sysroot,
        cc_target_os = None,
    )

cc_toolchain_config_win = rule(
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
        "compile_flags": attr.string_list(mandatory = True),
        "cxx_flags": attr.string_list(mandatory = True),
        "link_flags": attr.string_list(mandatory = True),
        "cxx_builtin_include_directories": attr.string_list(mandatory = True),
        "builtin_sysroot": attr.string(mandatory = False),
        "msvc_env_path": attr.string(mandatory = False),
        "msvc_env_include": attr.string(mandatory = False),
        "msvc_env_lib": attr.string(mandatory = False),
        "msvc_env_tmp": attr.string(mandatory = False),
    },
    provides = [CcToolchainConfigInfo],
)
