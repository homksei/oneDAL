@echo off
REM Dynamic link wrapper for Windows
REM Usage: dynamic_link.bat [compiler options] -o output input.obj ...

set CC_PATH=%{cc_path}
%CC_PATH% %*
