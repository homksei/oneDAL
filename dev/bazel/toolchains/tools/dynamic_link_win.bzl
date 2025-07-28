def dynamic_link_win(name, toolchain_identifier, target_arch_id):
    native.genrule(
        name = name,
        outs = [name + ".bat"],
        cmd = "cp $(location @onedal//dev/bazel/toolchains/tools:dynamic_link_win.tpl.bat) $@",
        tools = ["@onedal//dev/bazel/toolchains/tools:dynamic_link_win.tpl.bat"],
        executable = True,
    )
