# 目标架构
set(VCPKG_CMAKE_SYSTEM_NAME Linux)
set(VCPKG_TARGET_ARCHITECTURE x64)

set(VCPKG_CHAINLOAD_TOOLCHAIN_FILE "/opt/zftoolchain/toolchain_x64.cmake")

# Linux 默认使用 glibc + 动态库
set(VCPKG_CRT_LINKAGE dynamic)
set(VCPKG_LIBRARY_LINKAGE static)

# 使用你自己的交叉工具链

set(VCPKG_PREFER_SYSTEM_LIBS ON)