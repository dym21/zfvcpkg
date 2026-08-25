vcpkg_from_github(
    OUT_SOURCE_PATH SOURCE_PATH
    REPO numactl/numactl
    REF "v${VERSION}"
    SHA512 a9aa93bdc6333b620c10ff3573d6ff645ab54beece75e67be8cdddb27d062cc56cea34db342005a171877f85f05eb1d24e43f8466be907ba3b7c8b1f897cd954
    HEAD_REF master
    PATCHES
        pkgconfig.diff
)

vcpkg_make_configure(
    SOURCE_PATH "${SOURCE_PATH}"
    AUTORECONF
)

# Prefer real compiler-runtime archives over relocated .la metadata that can
# contain an obsolete absolute installation prefix.
foreach(build_type rel dbg)
    set(libtool_file
        "${CURRENT_BUILDTREES_DIR}/${TARGET_TRIPLET}-${build_type}/libtool"
    )
    if(EXISTS "${libtool_file}")
        vcpkg_replace_string(
            "${libtool_file}"
            "for search_ext in .la $std_shrext .so .a; do"
            "for search_ext in $std_shrext .so .a .la; do"
        )
    endif()
endforeach()

vcpkg_make_install()
vcpkg_fixup_pkgconfig()

file(
    INSTALL "${CMAKE_CURRENT_LIST_DIR}/unofficial-numa-config.cmake"
    DESTINATION "${CURRENT_PACKAGES_DIR}/share/unofficial-numa"
)

file(REMOVE_RECURSE
    "${CURRENT_PACKAGES_DIR}/debug/include"
    "${CURRENT_PACKAGES_DIR}/debug/share"
)

vcpkg_install_copyright(
    FILE_LIST
        "${SOURCE_PATH}/README.md"
        "${SOURCE_PATH}/LICENSE.LGPL2.1"
        "${SOURCE_PATH}/LICENSE.GPL2"
)
vcpkg_replace_string(
    "${CURRENT_PACKAGES_DIR}/share/${PORT}/copyright"
    ".*# License"
    "# License"
    REGEX
)
