vcpkg_from_github(
    OUT_SOURCE_PATH SOURCE_PATH
    REPO kakwa/libemf2svg
    REF ${VERSION}
    SHA512 0
    HEAD_REF master
    PATCHES
        0001-fix-compile-error.patch
)

vcpkg_cmake_configure(
    SOURCE_PATH "${SOURCE_PATH}"
    OPTIONS
        -DSTATIC=ON
    OPTIONS_DEBUG
        -DSKIP_INSTALL_HEADERS=ON
)

vcpkg_cmake_install()

# Install usage file
file(INSTALL "${CMAKE_CURRENT_LIST_DIR}/usage" DESTINATION "${CURRENT_PACKAGES_DIR}/share/${PORT}")

# Handle copyright
vcpkg_install_copyright(FILE_LIST "${SOURCE_PATH}/LICENSE")

# Fix pkgconfig files if they exist
vcpkg_fixup_pkgconfig()

# Remove debug includes and unnecessary files
file(REMOVE_RECURSE "${CURRENT_PACKAGES_DIR}/debug/include")
file(REMOVE_RECURSE "${CURRENT_PACKAGES_DIR}/debug/share")
