vcpkg_download_distfile(
    ARCHIVE
    URLS "https://dev-www.libreoffice.org/src/libmspub/libmspub-0.1.5.tar.xz"
    FILENAME "libmspub-0.1.5.tar.xz"
    SHA512 4936aff75bc14f48f561ce7ab5d6a12da01b54a5c7fb2eb576641204439038237f57132aadfead7e137e7382886a1f6fffe8acea64ea2acf5cf8cb666ea96f5e
)

vcpkg_extract_source_archive(
    SOURCE_PATH
    ARCHIVE "${ARCHIVE}"
    PATCHES
        0001-use-libiconv.patch
)

file(COPY "${CMAKE_CURRENT_LIST_DIR}/CMakeLists.txt"
     DESTINATION "${SOURCE_PATH}")
file(COPY "${CMAKE_CURRENT_LIST_DIR}/libmspub-config.cmake.in"
     DESTINATION "${SOURCE_PATH}")

vcpkg_cmake_configure(SOURCE_PATH "${SOURCE_PATH}")
vcpkg_cmake_install()
vcpkg_cmake_config_fixup(
    PACKAGE_NAME libmspub
    CONFIG_PATH lib/cmake/libmspub
)

file(REMOVE_RECURSE "${CURRENT_PACKAGES_DIR}/debug/include")
vcpkg_install_copyright(FILE_LIST "${SOURCE_PATH}/COPYING.MPL")
