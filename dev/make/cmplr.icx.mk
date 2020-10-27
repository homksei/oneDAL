#===============================================================================
# Copyright 2012-2020 Intel Corporation
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

#++
#  Intel compiler defenitions for makefile
#--

PLATs.icx = lnx32e win32e mac32e

CMPLRDIRSUFF.icx =

CORE.SERV.COMPILER.icx = generic
-DEBC.icx = $(if $(OS_is_win),-debug:all -Z7,-g)

-Zl.icx = $(if $(OS_is_win),-Zl,) -mGLOB_freestanding=TRUE -mCG_no_libirc=TRUE
-Qopt = $(if $(OS_is_win),-Qopt-,-qopt-)

COMPILER.lnx.icx  = $(if $(COVFILE),cov01 -1; covc -i )icx -qopenmp-simd \
                    -Werror -Wreturn-type
COMPILER.lnx.icx += $(if $(COVFILE), $(if $(IA_is_ia32), $(-Q)m32, $(-Q)m64))
COMPILER.win.icx = icx -nologo -WX -Qopenmp-simd
COMPILER.mac.icx = icx -stdlib=libc++ -mmacosx-version-min=10.14 \
				   -Werror -Wreturn-type

link.dynamic.lnx.icx = icx -no-cilk
link.dynamic.mac.icx = icx

pedantic.opts.lnx.icx = -pedantic \
                        -Wall \
                        -Wextra \
                        -Wno-unused-parameter

daaldep.lnx32e.rt.icx = -static-intel
daaldep.lnx32.rt.icx  = -static-intel

p4_OPT.icx   = $(-Q)$(if $(OS_is_mac),xSSE4.2,xSSE2)
mc_OPT.icx   = $(-Q)$(if $(OS_is_mac),xSSE4.2,xSSE3)
mc3_OPT.icx  = $(-Q)xSSE4.2
avx_OPT.icx  = $(-Q)xAVX
avx2_OPT.icx = $(-Q)xCORE-AVX2
knl_OPT.icx  = $(if $(OS_is_mac),$(-Q)xCORE-AVX2,$(-Q)xMIC-AVX512)
skx_OPT.icx  = $(-Q)xCORE-AVX512 $(-Qopt)zmm-usage=high
#TODO add march opts in GCC style
