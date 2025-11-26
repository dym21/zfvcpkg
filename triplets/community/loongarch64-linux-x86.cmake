# 目标架构
set(VCPKG_TARGET_ARCHITECTURE loongarch64)

# Linux 默认使用 glibc + 动态库
set(VCPKG_CRT_LINKAGE dynamic)
set(VCPKG_LIBRARY_LINKAGE static)

# 使用你自己的交叉工具链
set(VCPKG_CHAINLOAD_TOOLCHAIN_FILE "/opt/zftoolchain/loongarch64-zftoolchain-linux-gnu/toolchain.cmake")

# Linux 平台
set(VCPKG_CMAKE_SYSTEM_NAME Linux)

# 禁用 vcpkg 内部的 cwd 证书检查（交叉编译常见问题）
set(VCPKG_FIXUP_ELF_RPATH ON)
