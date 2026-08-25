vcpkg_download_distfile(
    ARCHIVE
    URLS "https://releases.pagure.org/mlocate/mlocate-0.26.tar.xz"
    FILENAME "mlocate-0.26.tar.xz"
    SHA512 b1207047e30a551cba39e70812439b554def567ebe9b8b81fed6f26435bb575beafe4875a21cd72876eadd85da4e7bfc942eb28b17c430b537c351690364837f
)

vcpkg_extract_source_archive(
    SOURCE_PATH
    ARCHIVE "${ARCHIVE}"
    PATCHES
        glibc-wchar-special-includes.patch
)

file(COPY
    "${VCPKG_ROOT_DIR}/scripts/config.guess"
    "${VCPKG_ROOT_DIR}/scripts/config.sub"
    DESTINATION "${SOURCE_PATH}/admin"
)

vcpkg_configure_make(
    SOURCE_PATH "${SOURCE_PATH}"
    COPY_SOURCE
    DETERMINE_BUILD_TRIPLET
    NO_DEBUG
    OPTIONS
        --disable-nls
        --disable-rpath
)
vcpkg_install_make()
file(RENAME
    "${CURRENT_PACKAGES_DIR}/tools/${PORT}/bin/locate"
    "${CURRENT_PACKAGES_DIR}/tools/${PORT}/locate"
)
file(RENAME
    "${CURRENT_PACKAGES_DIR}/tools/${PORT}/bin/updatedb"
    "${CURRENT_PACKAGES_DIR}/tools/${PORT}/updatedb"
)
file(REMOVE_RECURSE "${CURRENT_PACKAGES_DIR}/tools/${PORT}/bin")

file(REMOVE_RECURSE
    "${CURRENT_PACKAGES_DIR}/etc"
    "${CURRENT_PACKAGES_DIR}/share/man"
    "${CURRENT_PACKAGES_DIR}/var"
)
vcpkg_install_copyright(FILE_LIST "${SOURCE_PATH}/COPYING")
