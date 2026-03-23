# x64 Linux triplet for native compilation

set(VCPKG_CMAKE_SYSTEM_NAME Linux)
set(VCPKG_TARGET_ARCHITECTURE x64)

# Use system toolchain (native build, not cross-compile)
set(VCPKG_CRT_LINKAGE dynamic)
set(VCPKG_LIBRARY_LINKAGE static)

# Enable C++17
set(VCPKG_CXX_FLAGS "-std=c++17")

# Optimize for current machine
set(VCPKG_CMAKE_BUILD_TYPE "Release")
