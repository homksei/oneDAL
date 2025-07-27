#include <iostream>
#include <string>

int main() {
    std::cout << "Hello, World from oneDAL Windows build!" << std::endl;

#ifdef _WIN32
    std::cout << "Platform: Windows" << std::endl;
#endif

#ifdef _MSC_VER
    std::cout << "Compiler: Microsoft Visual C++ " << _MSC_VER << std::endl;
#endif

#ifdef __INTEL_COMPILER
    std::cout << "Compiler: Intel C++ " << __INTEL_COMPILER << std::endl;
#endif

#ifdef __ICX_VERSION__
    std::cout << "Compiler: Intel oneAPI C++ " << __ICX_VERSION__ << std::endl;
#endif

    std::cout << "C++ Standard: " << __cplusplus << std::endl;

    return 0;
}
