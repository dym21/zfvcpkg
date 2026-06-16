# 目标架构
set(VCPKG_CMAKE_SYSTEM_NAME Linux)
set(VCPKG_TARGET_ARCHITECTURE mips64)

set(VCPKG_CHAINLOAD_TOOLCHAIN_FILE "/opt/zftoolchain/toolchain_mips64.cmake")
set(VCPKG_MESON_CROSS_FILE "${VCPKG_ROOT_DIR}/scripts/mips64el-linux.meson")

# Linux 默认使用 glibc + 动态库
set(VCPKG_CRT_LINKAGE dynamic)
set(VCPKG_LIBRARY_LINKAGE static)

# 使用你自己的交叉工具链

set(VCPKG_PREFER_SYSTEM_LIBS ON)

# mips64el-zftoolchain 默认目标为 mips3，需要显式指定 mips64 才能支持 MSA/pref 等指令
set(VCPKG_C_FLAGS "-march=mips64 ${VCPKG_C_FLAGS}")
set(VCPKG_CXX_FLAGS "-march=mips64 ${VCPKG_CXX_FLAGS}")