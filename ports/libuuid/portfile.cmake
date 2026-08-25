set(LIBUUID_VERSION 1.0.3)

if(VCPKG_TARGET_IS_OHOS)
    # The SourceForge archive is intermittently unavailable from the OHOS
    # Windows cross-build environment; use the matching upstream git source.
    vcpkg_from_git(
        OUT_SOURCE_PATH SOURCE_PATH
        URL "https://git.code.sf.net/p/libuuid/code"
        REF 16cb58d558844045f217d4ee416f931fc1b03794
        FETCH_REF libuuid-1.0.3
        PATCHES
            "${CMAKE_CURRENT_LIST_DIR}/fix-usleep-with-nanosleep.patch"
    )
else()
    vcpkg_from_sourceforge(
        OUT_SOURCE_PATH SOURCE_PATH
        REPO libuuid
        FILENAME "libuuid-${LIBUUID_VERSION}.tar.gz"
        SHA512 77488caccc66503f6f2ded7bdfc4d3bc2c20b24a8dc95b2051633c695e99ec27876ffbafe38269b939826e1fdb06eea328f07b796c9e0aaca12331a787175507
        PATCHES
            fix-usleep-with-nanosleep.patch
    )
endif()

file(COPY
    "${CMAKE_CURRENT_LIST_DIR}/CMakeLists.txt"
    "${CMAKE_CURRENT_LIST_DIR}/config.linux.h"
    "${CMAKE_CURRENT_LIST_DIR}/unofficial-libuuid-config.cmake.in"
    DESTINATION "${SOURCE_PATH}"
)

vcpkg_cmake_configure(
    SOURCE_PATH "${SOURCE_PATH}"
)

vcpkg_cmake_install()

set(prefix "${CURRENT_INSTALLED_DIR}")
set(exec_prefix \$\{prefix\})
set(libdir \$\{exec_prefix\}/lib)
set(includedir \$\{prefix\}/include)
configure_file("${SOURCE_PATH}/uuid.pc.in" "${SOURCE_PATH}/uuid.pc" @ONLY)
if(NOT DEFINED VCPKG_BUILD_TYPE OR VCPKG_BUILD_TYPE STREQUAL "release")
    file(INSTALL "${SOURCE_PATH}/uuid.pc" DESTINATION "${CURRENT_PACKAGES_DIR}/lib/pkgconfig")
endif()
if(NOT DEFINED VCPKG_BUILD_TYPE OR VCPKG_BUILD_TYPE STREQUAL "debug")
    file(INSTALL "${SOURCE_PATH}/uuid.pc" DESTINATION "${CURRENT_PACKAGES_DIR}/debug/lib/pkgconfig")
endif()

vcpkg_cmake_config_fixup(CONFIG_PATH lib/cmake/unofficial-libuuid PACKAGE_NAME unofficial-libuuid)
vcpkg_fixup_pkgconfig()

vcpkg_install_copyright(FILE_LIST "${SOURCE_PATH}/COPYING")

vcpkg_copy_pdbs()
