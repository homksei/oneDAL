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

lnx_cc_common_flags = [
    "-fwrapv",
    "-fstack-protector-strong",
    "-fno-delete-null-pointer-checks",
    "-Werror",
    "-Wformat",
    "-Wformat-security",
    "-Wreturn-type",
]

lnx_cc_pedantic_flags = [
    "-pedantic",
    "-Wall",
    "-Wextra",
    "-Wno-unused-parameter",
    "-Wno-unused-but-set-parameter",
]

lnx_cc_flags = {
    "common": lnx_cc_common_flags,
    "pedantic": lnx_cc_pedantic_flags,
}

win_cc_common_flags = [
    "/W3",
    "/WX",
    "/EHsc",
    "/bigobj",
]

win_cc_pedantic_flags = [
    "/Wall",
    "/wd4514",  # unreferenced inline function has been removed
    "/wd4710",  # function not inlined
    "/wd4711",  # function selected for automatic inline expansion
    "/wd4820",  # padding added after data member
    "/wd5045",  # Spectre mitigation
]

win_cc_flags = {
    "common": win_cc_common_flags,
    "pedantic": win_cc_pedantic_flags,
}

def get_default_flags(arch_id, os_id, compiler_id, category = "common"):
    _check_flag_category(category)
    if os_id == "lnx":
        flags = lnx_cc_flags[category]
        if compiler_id == "icc" and category == "common":
            flags = flags + [
                "-qopenmp-simd",
                "-mGLOB_freestanding=TRUE",
                "-mCG_no_libirc=TRUE",
            ]
        if compiler_id == "icx" and category == "common":
            flags = flags + [
                "-qopenmp-simd",
                "-no-intel-lib=libirc",
                "-no-canonical-prefixes",
            ]
        if compiler_id == "icpx":
            flags = flags + ["-fsycl"] + ["-fno-canonical-system-headers"]+["-no-canonical-prefixes"]
        if compiler_id == "icpx" and category == "pedantic":
            # TODO: Consider removing
            flags = flags + ["-Wno-unused-command-line-argument"]
        if compiler_id == "gcc" or compiler_id == "icpx":
            flags = flags + ["-Wno-gnu-zero-variadic-macro-arguments"]
        if compiler_id not in ["icx", "icpx"]:
            flags = flags + ["-fno-strict-overflow"]
        return flags
    elif os_id == "win":
        flags = win_cc_flags[category]
        if compiler_id == "cl":
            if category == "common":
                flags = flags + [
                    "/MD",  # Multi-threaded DLL runtime
                    "/O2",  # Optimize for speed
                    "/Oi",  # Enable intrinsic functions
                    "/Ot",  # Favor fast code
                    "/Oy",  # Frame pointer omission
                    "/GL",  # Whole program optimization
                ]
        elif compiler_id == "icx":
            if category == "common":
                flags = flags + [
                    "/Qopenmp-simd",
                    "/O3",
                    "/MD",
                ]
        elif compiler_id == "icpx":
            if category == "common":
                flags = flags + [
                    "/fsycl",
                    "/Qopenmp-simd",
                    "/O3",
                    "/MD",
                ]
        return flags
    fail("Unsupported OS")

def get_cpu_flags(arch_id, os_id, compiler_id):
    sse2 = []
    sse42 = []
    avx2 = []
    avx512 = []
    if compiler_id == "gcc":
        sse2 = ["-march=nocona"]
        sse42 = ["-march=corei7"]
        avx2 = ["-march=haswell"]
        avx512 = ["-march=haswell"]
    elif compiler_id == "icc":
        sse2 = ["-xSSE2"]
        sse42 = ["-xSSE4.2"]
        avx2 = ["-xCORE-AVX2"]
        avx512 = ["-xCORE-AVX512", "-qopt-zmm-usage=high"]
    elif compiler_id in ["icx", "icpx"]:
        if os_id == "win":
            sse2 = ["/arch:SSE2"]
            sse42 = ["/arch:SSE2"]  # Windows doesn't have specific SSE4.2 flag
            avx2 = ["/arch:AVX2"]
            avx512 = ["/arch:AVX512"]
        else:
            sse2 = ["-march=nocona"]
            sse42 = ["-march=nehalem"]
            avx2 = ["-march=haswell"]
            avx512 = ["-march=skx"]
    elif compiler_id == "cl":
        sse2 = ["/arch:SSE2"]
        sse42 = ["/arch:SSE2"]  # MSVC doesn't have specific SSE4.2 flag
        avx2 = ["/arch:AVX2"]
        avx512 = ["/arch:AVX512"]
    return {
        "sse2": sse2,
        "sse42": sse42,
        "avx2": avx2,
        "avx512": avx512,
    }

def _check_flag_category(category):
    if not category in ["common", "pedantic"]:
        fail("Unsupported compiler flag category '{}' ".format(category) +
             "expected 'common' or 'pedantic'")
