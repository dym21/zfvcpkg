# LoongArch64 old-world ABI, GCC 13.4.0, glibc 2.28.
set(VCPKG_CMAKE_SYSTEM_NAME Linux)
set(VCPKG_TARGET_ARCHITECTURE loongarch64)

set(ZF_LOONGARCH_TOOLCHAIN_ROOT "/opt/zftoolchain/loongarch64-zftoolchain-linux-gnu-oldworld-x86_64")
if(NOT EXISTS "${ZF_LOONGARCH_TOOLCHAIN_ROOT}/bin/loongarch64-linux-gnu-gcc")
    message(FATAL_ERROR "LoongArch64 oldworld toolchain not found: ${ZF_LOONGARCH_TOOLCHAIN_ROOT}")
endif()

set(VCPKG_CHAINLOAD_TOOLCHAIN_FILE "/opt/zftoolchain/toolchain_loongarch64_oldworld.cmake")
set(VCPKG_MESON_CROSS_FILE "${VCPKG_ROOT_DIR}/scripts/loongarch64-linux-oldworld.meson")

set(VCPKG_CRT_LINKAGE dynamic)
set(VCPKG_LIBRARY_LINKAGE static)
set(VCPKG_PREFER_SYSTEM_LIBS ON)

# The crosstool-NG sysroot intentionally contains only the old-world glibc
# runtime. Build X11/XCB through vcpkg instead of treating them as preinstalled
# target-system packages.
set(X_VCPKG_FORCE_VCPKG_X_LIBRARIES ON)
