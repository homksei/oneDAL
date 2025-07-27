#include "test_lib.h"
#include <string>

namespace onedal_test {

std::string get_platform_info() {
#ifdef _WIN32
    return "Windows Platform";
#else
    return "Non-Windows Platform";
#endif
}

std::string get_compiler_info() {
#ifdef _MSC_VER
    return "Microsoft Visual C++";
#elif defined(__INTEL_COMPILER)
    return "Intel C++ Compiler";
#elif defined(__ICX_VERSION__)
    return "Intel oneAPI C++ Compiler";
#else
    return "Unknown Compiler";
#endif
}

int test_function(int a, int b) {
    return a + b;
}

}
