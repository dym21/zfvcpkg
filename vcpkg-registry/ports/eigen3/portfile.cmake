vcpkg_from_github(
    OUT_SOURCE_PATH SOURCE_PATH
    REPO eigen-mirror/eigen
    REF master  # 或你想用的 tag，例如 3.4.0
    SHA512 0  # 设为 0 可跳过哈希校验（或用实际值）
    HEAD_REF master
    PATCHES
        0001-fix-loongarch-error.patch
)

if(VCPKG_TARGET_IS_ANDROID OR VCPKG_TARGET_IS_IOS)
    list(APPEND PLATFORM_OPTIONS -DCMAKE_Fortran_COMPILER=OFF)
endif()

vcpkg_cmake_configure(
    SOURCE_PATH "${SOURCE_PATH}"
    OPTIONS
        -DBUILD_TESTING=OFF
        -DEIGEN_BUILD_DOC=OFF
        -DEIGEN_BUILD_PKGCONFIG=ON
        ${PLATFORM_OPTIONS}
    OPTIONS_RELEASE
        -DCMAKEPACKAGE_INSTALL_DIR=${CURRENT_PACKAGES_DIR}/lib/cmake/${PORT}
        -DPKGCONFIG_INSTALL_DIR=${CURRENT_PACKAGES_DIR}/lib/pkgconfig
    OPTIONS_DEBUG
        -DCMAKEPACKAGE_INSTALL_DIR=${CURRENT_PACKAGES_DIR}/debug/lib/cmake/${PORT}
        -DPKGCONFIG_INSTALL_DIR=${CURRENT_PACKAGES_DIR}/debug/lib/pkgconfig
)

vcpkg_cmake_install()
vcpkg_cmake_config_fixup(CONFIG_PATH lib/cmake/${PORT} PACKAGE_NAME Eigen3)
vcpkg_fixup_pkgconfig()

file(REMOVE_RECURSE
    "${CURRENT_PACKAGES_DIR}/debug/include"
    "${CURRENT_PACKAGES_DIR}/debug/share"
)

file(INSTALL "${SOURCE_PATH}/COPYING.README" DESTINATION "${CURRENT_PACKAGES_DIR}/share")
