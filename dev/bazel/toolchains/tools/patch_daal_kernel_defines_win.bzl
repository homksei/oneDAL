def patch_daal_kernel_defines_win(name, toolchain_identifier):
    native.genrule(
        name = name,
        outs = [name + ".bat"],
        cmd = "cp $(location @onedal//dev/bazel/toolchains/tools:patch_daal_kernel_defines_win.tpl.bat) $@",
        tools = ["@onedal//dev/bazel/toolchains/tools:patch_daal_kernel_defines_win.tpl.bat"],
        executable = True,
    )
