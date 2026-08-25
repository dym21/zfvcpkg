vcpkg_from_sourceforge(
    OUT_SOURCE_PATH SOURCE_PATH
    REPO libwpd/librevenge
    REF librevenge-0.0.6
    FILENAME "librevenge-0.0.6.tar.bz2"
    SHA512 173e0eaa6c359af31c10da501d611e3ed8a36956072adbfc38b674c2400926871348e81f45a0f7784010be0eee5e8d55752a16a235768c3f6a12472d31a94d6e
)

file(COPY "${CMAKE_CURRENT_LIST_DIR}/CMakeLists.txt"
     DESTINATION "${SOURCE_PATH}")
file(COPY "${CMAKE_CURRENT_LIST_DIR}/librevenge-config.cmake.in"
     DESTINATION "${SOURCE_PATH}")

vcpkg_cmake_configure(SOURCE_PATH "${SOURCE_PATH}")
vcpkg_cmake_install()
vcpkg_cmake_config_fixup(
    PACKAGE_NAME librevenge
    CONFIG_PATH lib/cmake/librevenge
)

file(REMOVE_RECURSE "${CURRENT_PACKAGES_DIR}/debug/include")
vcpkg_install_copyright(
    FILE_LIST
        "${SOURCE_PATH}/COPYING.MPL"
        "${SOURCE_PATH}/COPYING.LGPL"
)
