# 目标架构：LoongArch64 新世界 ABI
set(VCPKG_CMAKE_SYSTEM_NAME Linux)
set(VCPKG_TARGET_ARCHITECTURE loongarch64)

set(VCPKG_CHAINLOAD_TOOLCHAIN_FILE "/opt/zftoolchain/toolchain_loongarch64_newworld.cmake")
set(VCPKG_MESON_CROSS_FILE "${VCPKG_ROOT_DIR}/scripts/loongarch64-linux-newworld.meson")

# Linux 默认使用 glibc + 动态库
set(VCPKG_CRT_LINKAGE dynamic)
set(VCPKG_LIBRARY_LINKAGE static)

# 使用你自己的交叉工具链
set(VCPKG_PREFER_SYSTEM_LIBS ON)
