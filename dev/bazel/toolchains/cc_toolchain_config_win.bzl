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
    ACTION_NAMES.clif_match,
]

preprocessor_compile_actions = [
    ACTION_NAMES.c_compile,
    ACTION_NAMES.cpp_compile,
    ACTION_NAMES.linkstamp_compile,
    ACTION_NAMES.preprocess_assemble,
    ACTION_NAMES.cpp_header_parsing,
    ACTION_NAMES.cpp_module_compile,
    ACTION_NAMES.clif_match,
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
    cc_tool = tool(
        path = ctx.attr.cc_path,
        with_features = [
            with_feature_set(not_features = ["dpc++"])
        ]
    )

    dpcc_tool = tool(
        path = ctx.attr.dpcc_path,
        with_features = [
            with_feature_set(features = ["dpc++"]),
        ],
    ) if ctx.attr.dpcc_path else None

    tool_paths = [
        tool_path(
            name = "gcc",
            path = ctx.attr.cc_path,
        ),
        tool_path(
            name = "ld",
            path = ctx.attr.link_path,
        ),
        tool_path(
            name = "ar",
            path = ctx.attr.lib_path,
        ),
        tool_path(
            name = "cpp",
            path = ctx.attr.cc_path,
        ),
        tool_path(
            name = "gcov",
            path = "@onedal//dev/bazel/toolchains/tools:tool_not_found.tpl.bat",
        ),
        tool_path(
            name = "nm",
            path = "@onedal//dev/bazel/toolchains/tools:tool_not_found.tpl.bat",
        ),
        tool_path(
            name = "objdump",
            path = "@onedal//dev/bazel/toolchains/tools:tool_not_found.tpl.bat",
        ),
        tool_path(
            name = "strip",
            path = "@onedal//dev/bazel/toolchains/tools:tool_not_found.tpl.bat",
        ),
    ]

    compile_actions = [
        action_config(
            action_name = ACTION_NAMES.c_compile,
            tools = [cc_tool] + ([dpcc_tool] if dpcc_tool else []),
            implies = [
                "compiler_input_flags",
                "compiler_output_flags",
                "default_compile_flags",
                "user_compile_flags",
                "sysroot",
                "unfiltered_compile_flags",
            ],
        ),
        action_config(
            action_name = ACTION_NAMES.cpp_compile,
            tools = [cc_tool] + ([dpcc_tool] if dpcc_tool else []),
            implies = [
                "compiler_input_flags",
                "compiler_output_flags",
                "default_compile_flags",
                "user_compile_flags",
                "sysroot",
                "unfiltered_compile_flags",
            ],
        ),
    ]

    linking_actions = [
        action_config(
            action_name = ACTION_NAMES.cpp_link_executable,
            tools = [cc_tool] + ([dpcc_tool] if dpcc_tool else []),
            implies = [
                "linkstamps",
                "output_execpath_flags",
                "runtime_library_search_directories",
                "library_search_directories",
                "libraries_to_link",
                "force_pic_flags",
                "user_link_flags",
                "legacy_link_flags",
                "linker_subsystem_flag",
                "sysroot",
            ],
        ),
        action_config(
            action_name = ACTION_NAMES.cpp_link_dynamic_library,
            tools = [cc_tool] + ([dpcc_tool] if dpcc_tool else []),
            implies = [
                "shared_flag",
                "linkstamps",
                "output_execpath_flags",
                "runtime_library_search_directories",
                "library_search_directories",
                "libraries_to_link",
                "user_link_flags",
                "legacy_link_flags",
                "linker_subsystem_flag",
                "sysroot",
            ],
        ),
    ]

    archiving_actions = [
        action_config(
            action_name = ACTION_NAMES.cpp_link_static_library,
            tools = [
                tool(path = ctx.attr.lib_path)
            ],
            flag_sets = [
                flag_set(
                    flag_groups = [
                        flag_group(
                            flags = ["/OUT:%{output_execpath}"] +
                                   ["%{libraries_to_link.name}"] if ctx.attr.compiler == "cl" else
                                   ["rcs", "%{output_execpath}"] +
                                   ["%{libraries_to_link.name}"]
                        ),
                    ],
                ),
            ],
        ),
    ]

    merge_static_lib_actions = [
        action_config(
            action_name = CPP_MERGE_STATIC_LIBRARIES,
            tools = [
                tool(path = "@onedal//dev/bazel/toolchains/tools:merge_static_libs_win.tpl.bat")
            ],
            flag_sets = [
                flag_set(
                    flag_groups = [
                        flag_group(
                            flags = [
                                "%{output_execpath}",
                                "%{libraries_to_link.name}",
                            ]
                        ),
                    ],
                ),
            ],
        ),
    ]

    # Windows-specific features
    msvc_env_feature = feature(
        name = "msvc_env",
        flag_sets = [
            flag_set(
                actions = all_compile_actions + all_link_actions,
                flag_groups = [
                    flag_group(
                        flags = ["/nologo"] if ctx.attr.compiler == "cl" else []
                    ),
                ],
            ),
        ],
    )

    default_compile_flags_feature = feature(
        name = "default_compile_flags",
        enabled = True,
        flag_sets = [
            flag_set(
                actions = all_compile_actions,
                flag_groups = ([
                    flag_group(
                        flags = ctx.attr.common_options,
                    ),
                ]),
            ),
            flag_set(
                actions = all_compile_actions,
                flag_groups = ([
                    flag_group(
                        flags = ctx.attr.pedantic_options,
                    ),
                ]),
                with_features = [
                    with_feature_set(features = ["pedantic"]),
                ],
            ),
        ],
    )

    # DPC++ specific feature
    dpcpp_feature = feature(
        name = "dpc++",
        flag_sets = [
            flag_set(
                actions = all_compile_actions,
                flag_groups = ([
                    flag_group(
                        flags = ctx.attr.dpcc_common_options,
                    ),
                ]),
            ),
            flag_set(
                actions = all_compile_actions,
                flag_groups = ([
                    flag_group(
                        flags = ctx.attr.dpcc_pedantic_options,
                    ),
                ]),
                with_features = [
                    with_feature_set(features = ["pedantic"]),
                ],
            ),
        ],
    ) if ctx.attr.dpcc_path else None

    # CPU optimization features
    cpu_features = []
    for cpu, flags in ctx.attr.cpu_options.items():
        cpu_features.append(
            feature(
                name = cpu,
                flag_sets = [
                    flag_set(
                        actions = all_compile_actions,
                        flag_groups = [
                            flag_group(flags = flags),
                        ],
                    ),
                ],
            )
        )

    dpcc_cpu_features = []
    if dpcpp_feature:
        for cpu, flags in ctx.attr.dpcc_cpu_options.items():
            dpcc_cpu_features.append(
                feature(
                    name = "dpc++_" + cpu,
                    flag_sets = [
                        flag_set(
                            actions = all_compile_actions,
                            flag_groups = [
                                flag_group(flags = flags),
                            ],
                            with_features = [
                                with_feature_set(features = ["dpc++"]),
                            ],
                        ),
                    ],
                )
            )

    # Common features
    compiler_input_flags_feature = feature(
        name = "compiler_input_flags",
        flag_sets = [
            flag_set(
                actions = [
                    ACTION_NAMES.assemble,
                    ACTION_NAMES.preprocess_assemble,
                    ACTION_NAMES.c_compile,
                    ACTION_NAMES.cpp_compile,
                    ACTION_NAMES.cpp_header_parsing,
                    ACTION_NAMES.cpp_module_compile,
                    ACTION_NAMES.cpp_module_codegen,
                ],
                flag_groups = [
                    flag_group(
                        flags = ["/c", "%{source_file}"] if ctx.attr.compiler == "cl" else
                               ["-c", "%{source_file}"]
                    ),
                ],
            ),
        ],
    )

    compiler_output_flags_feature = feature(
        name = "compiler_output_flags",
        flag_sets = [
            flag_set(
                actions = [ACTION_NAMES.assemble],
                flag_groups = [
                    flag_group(
                        flags = ["/Fo%{output_file}"] if ctx.attr.compiler == "cl" else
                               ["-o", "%{output_file}"]
                    ),
                ],
            ),
            flag_set(
                actions = [
                    ACTION_NAMES.preprocess_assemble,
                    ACTION_NAMES.c_compile,
                    ACTION_NAMES.cpp_compile,
                    ACTION_NAMES.cpp_header_parsing,
                    ACTION_NAMES.cpp_module_compile,
                    ACTION_NAMES.cpp_module_codegen,
                ],
                flag_groups = [
                    flag_group(
                        flags = ["/Fo%{output_file}"] if ctx.attr.compiler == "cl" else
                               ["-o", "%{output_file}"]
                    ),
                ],
            ),
        ],
    )

    user_compile_flags_feature = feature(
        name = "user_compile_flags",
        enabled = True,
        flag_sets = [
            flag_set(
                actions = [
                    ACTION_NAMES.assemble,
                    ACTION_NAMES.preprocess_assemble,
                    ACTION_NAMES.c_compile,
                    ACTION_NAMES.cpp_compile,
                    ACTION_NAMES.cpp_header_parsing,
                    ACTION_NAMES.cpp_module_compile,
                    ACTION_NAMES.cpp_module_codegen,
                ],
                flag_groups = [
                    flag_group(
                        flags = ["%{user_compile_flags}"],
                        iterate_over = "user_compile_flags",
                        expand_if_available = "user_compile_flags",
                    ),
                ],
            ),
        ],
    )

    sysroot_feature = feature(
        name = "sysroot",
        enabled = True,
        flag_sets = [
            flag_set(
                actions = [
                    ACTION_NAMES.preprocess_assemble,
                    ACTION_NAMES.c_compile,
                    ACTION_NAMES.cpp_compile,
                    ACTION_NAMES.cpp_header_parsing,
                    ACTION_NAMES.cpp_module_compile,
                    ACTION_NAMES.cpp_module_codegen,
                    ACTION_NAMES.cpp_link_executable,
                    ACTION_NAMES.cpp_link_dynamic_library,
                    ACTION_NAMES.cpp_link_nodeps_dynamic_library,
                ],
                flag_groups = [
                    flag_group(
                        flags = ["--sysroot=%{sysroot}"],
                        expand_if_available = "sysroot",
                    ),
                ],
            ),
        ],
    )

    unfiltered_compile_flags_feature = feature(
        name = "unfiltered_compile_flags",
        enabled = True,
        flag_sets = [
            flag_set(
                actions = [
                    ACTION_NAMES.assemble,
                    ACTION_NAMES.preprocess_assemble,
                    ACTION_NAMES.c_compile,
                    ACTION_NAMES.cpp_compile,
                    ACTION_NAMES.cpp_header_parsing,
                    ACTION_NAMES.cpp_module_compile,
                    ACTION_NAMES.cpp_module_codegen,
                ],
                flag_groups = [
                    flag_group(
                        flags = ["%{unfiltered_compile_flags}"],
                        iterate_over = "unfiltered_compile_flags",
                        expand_if_available = "unfiltered_compile_flags",
                    ),
                ],
            ),
        ],
    )

    # Linking features
    libraries_to_link_feature = feature(
        name = "libraries_to_link",
        enabled = True,
        flag_sets = [
            flag_set(
                actions = all_link_actions,
                flag_groups = [
                    flag_group(
                        iterate_over = "libraries_to_link",
                        flag_groups = [
                            flag_group(
                                flags = ["%{libraries_to_link.name}"],
                                expand_if_available = "libraries_to_link.name",
                            ),
                        ],
                        expand_if_available = "libraries_to_link",
                    ),
                ],
            ),
        ],
    )

    user_link_flags_feature = feature(
        name = "user_link_flags",
        enabled = True,
        flag_sets = [
            flag_set(
                actions = all_link_actions,
                flag_groups = [
                    flag_group(
                        flags = ["%{user_link_flags}"],
                        iterate_over = "user_link_flags",
                        expand_if_available = "user_link_flags",
                    ),
                ],
            ),
        ],
    )

    linkstamps_feature = feature(
        name = "linkstamps",
        flag_sets = [
            flag_set(
                actions = all_link_actions,
                flag_groups = [
                    flag_group(
                        flags = ["%{linkstamp_paths}"],
                        iterate_over = "linkstamp_paths",
                        expand_if_available = "linkstamp_paths",
                    ),
                ],
            ),
        ],
    )

    output_execpath_flags_feature = feature(
        name = "output_execpath_flags",
        flag_sets = [
            flag_set(
                actions = all_link_actions,
                flag_groups = [
                    flag_group(
                        flags = ["/OUT:%{output_execpath}"] if ctx.attr.compiler == "cl" else
                               ["-o", "%{output_execpath}"]
                    ),
                ],
            ),
        ],
    )

    runtime_library_search_directories_feature = feature(
        name = "runtime_library_search_directories",
        flag_sets = [
            flag_set(
                actions = all_link_actions,
                flag_groups = [
                    flag_group(
                        iterate_over = "runtime_library_search_directories",
                        flag_groups = [
                            flag_group(
                                flags = [
                                    "/LIBPATH:%{runtime_library_search_directories}" if ctx.attr.compiler == "cl" else
                                    "-L%{runtime_library_search_directories}"
                                ],
                            ),
                        ],
                        expand_if_available = "runtime_library_search_directories",
                    ),
                ],
            ),
        ],
    )

    library_search_directories_feature = feature(
        name = "library_search_directories",
        flag_sets = [
            flag_set(
                actions = all_link_actions,
                flag_groups = [
                    flag_group(
                        iterate_over = "library_search_directories",
                        flag_groups = [
                            flag_group(
                                flags = [
                                    "/LIBPATH:%{library_search_directories}" if ctx.attr.compiler == "cl" else
                                    "-L%{library_search_directories}"
                                ],
                            ),
                        ],
                        expand_if_available = "library_search_directories",
                    ),
                ],
            ),
        ],
    )

    linker_subsystem_flag_feature = feature(
        name = "linker_subsystem_flag",
        flag_sets = [
            flag_set(
                actions = all_link_actions,
                flag_groups = [
                    flag_group(
                        flags = ["/SUBSYSTEM:CONSOLE"] if ctx.attr.compiler == "cl" else []
                    ),
                ],
            ),
        ],
    )

    shared_flag_feature = feature(
        name = "shared_flag",
        flag_sets = [
            flag_set(
                actions = [
                    ACTION_NAMES.cpp_link_dynamic_library,
                    ACTION_NAMES.cpp_link_nodeps_dynamic_library,
                ],
                flag_groups = [
                    flag_group(
                        flags = ["/DLL"] if ctx.attr.compiler == "cl" else ["-shared"]
                    ),
                ],
            ),
        ],
    )

    legacy_link_flags_feature = feature(
        name = "legacy_link_flags",
        flag_sets = [
            flag_set(
                actions = all_link_actions,
                flag_groups = [
                    flag_group(
                        flags = ["%{legacy_link_flags}"],
                        iterate_over = "legacy_link_flags",
                        expand_if_available = "legacy_link_flags",
                    ),
                ],
            ),
        ],
    )

    force_pic_flags_feature = feature(
        name = "force_pic_flags",
        flag_sets = [
            flag_set(
                actions = [ACTION_NAMES.cpp_link_executable],
                flag_groups = [
                    flag_group(
                        flags = ["%{force_pic}"],
                        expand_if_available = "force_pic",
                    ),
                ],
            ),
        ],
    )

    pedantic_feature = feature(name = "pedantic")

    # Collect all features
    features = [
        msvc_env_feature,
        default_compile_flags_feature,
        compiler_input_flags_feature,
        compiler_output_flags_feature,
        user_compile_flags_feature,
        sysroot_feature,
        unfiltered_compile_flags_feature,
        libraries_to_link_feature,
        user_link_flags_feature,
        linkstamps_feature,
        output_execpath_flags_feature,
        runtime_library_search_directories_feature,
        library_search_directories_feature,
        linker_subsystem_flag_feature,
        shared_flag_feature,
        legacy_link_flags_feature,
        force_pic_flags_feature,
        pedantic_feature,
    ] + cpu_features + dpcc_cpu_features

    if dpcpp_feature:
        features.append(dpcpp_feature)

    action_configs = compile_actions + linking_actions + archiving_actions + merge_static_lib_actions

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
            extension = ".lib",
        ),
    ]

    return cc_common.create_cc_toolchain_config_info(
        ctx = ctx,
        features = features,
        action_configs = action_configs,
        artifact_name_patterns = artifact_name_patterns,
        cxx_builtin_include_directories = ctx.attr.cxx_builtin_include_directories,
        toolchain_identifier = ctx.attr.toolchain_identifier,
        host_system_name = ctx.attr.host_system_name,
        target_system_name = ctx.attr.target_system_name,
        target_cpu = ctx.attr.target_cpu,
        target_libc = ctx.attr.target_libc,
        compiler = ctx.attr.compiler,
        abi_version = ctx.attr.abi_version,
        abi_libc_version = ctx.attr.abi_libc_version,
        tool_paths = tool_paths,
        make_variables = [],
        builtin_sysroot = ctx.attr.builtin_sysroot,
        cc_target_os = ctx.attr.cc_target_os
    )

cc_toolchain_config = rule(
    implementation = _impl,
    attrs = {
        "cc_path": attr.string(mandatory = True),
        "dpcc_path": attr.string(mandatory = False),
        "link_path": attr.string(mandatory = True),
        "lib_path": attr.string(mandatory = True),
        "ml64_path": attr.string(mandatory = True),
        "rc_path": attr.string(mandatory = True),
        "vcvars_path": attr.string(mandatory = False),
        "cxx_builtin_include_directories": attr.string_list(),
        "toolchain_identifier": attr.string(),
        "host_system_name": attr.string(),
        "target_system_name": attr.string(),
        "target_cpu": attr.string(),
        "target_libc": attr.string(),
        "compiler": attr.string(),
        "abi_version": attr.string(),
        "abi_libc_version": attr.string(),
        "cc_target_os": attr.string(),
        "builtin_sysroot": attr.string(),
        "tool_bin_path": attr.string(),
        "common_options": attr.string_list(),
        "pedantic_options": attr.string_list(),
        "dpcc_common_options": attr.string_list(),
        "dpcc_pedantic_options": attr.string_list(),
        "cpu_options": attr.string_list_dict(),
        "dpcc_cpu_options": attr.string_list_dict(),
        "system_lib_directories": attr.string_list(),
    },
    provides = [CcToolchainConfigInfo],
)
