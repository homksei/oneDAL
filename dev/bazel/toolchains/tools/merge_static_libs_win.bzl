def merge_static_libs_win(name, toolchain_identifier):
    native.genrule(
        name = name,
        outs = [name + ".bat"],
        cmd = "cp $(location @onedal//dev/bazel/toolchains/tools:merge_static_libs_win.tpl.bat) $@",
        tools = ["@onedal//dev/bazel/toolchains/tools:merge_static_libs_win.tpl.bat"],
        executable = True,
    )
