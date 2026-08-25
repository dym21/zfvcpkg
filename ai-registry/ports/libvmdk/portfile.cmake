vcpkg_download_distfile(
    ARCHIVE
    URLS "https://github.com/libyal/libvmdk/releases/download/20240510/libvmdk-alpha-20240510.tar.gz"
    FILENAME "libvmdk-alpha-20240510.tar.gz"
    SHA512 2970fa3af3dc22ef0329c943b46069fc1c82a229bc38f3264780ff10404450eca2d5f0494643a2592fd0ed2249c221572d3750cda907c17fac4ff6db22a07e27
)

vcpkg_extract_source_archive(
    SOURCE_PATH
    ARCHIVE "${ARCHIVE}"
)

vcpkg_configure_make(
    SOURCE_PATH "${SOURCE_PATH}"
    COPY_SOURCE
    DETERMINE_BUILD_TRIPLET
    OPTIONS
        --disable-python
        --disable-shared-libs
)
vcpkg_install_make()
vcpkg_fixup_pkgconfig()

file(REMOVE_RECURSE
    "${CURRENT_PACKAGES_DIR}/bin"
    "${CURRENT_PACKAGES_DIR}/debug/bin"
    "${CURRENT_PACKAGES_DIR}/debug/include"
    "${CURRENT_PACKAGES_DIR}/debug/share"
    "${CURRENT_PACKAGES_DIR}/share/doc"
    "${CURRENT_PACKAGES_DIR}/share/man"
)
vcpkg_install_copyright(FILE_LIST "${SOURCE_PATH}/COPYING.LESSER")
