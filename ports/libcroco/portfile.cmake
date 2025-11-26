vcpkg_download_distfile(ARCHIVE
    URLS "https://download.gnome.org/sources/libcroco/0.6/libcroco-${VERSION}.tar.xz"
         "https://www.mirrorservice.org/sites/ftp.gnome.org/pub/GNOME/sources/libcroco/0.6/libcroco-${VERSION}.tar.xz"
    FILENAME "libcroco-${VERSION}.tar.xz"
    SHA512 038a3ac9d160a8cf86a8a88c34367e154ef26ede289c93349332b7bc449a5199b51ea3611cebf3a2416ae23b9e45ecf8f9c6b24ea6d16a5519b796d3c7e272d4
)

vcpkg_extract_source_archive(
    SOURCE_PATH
    ARCHIVE "${ARCHIVE}"
)

#fix loongarch64 build
file(COPY "${VCPKG_ROOT_DIR}/scripts/config.guess" "${VCPKG_ROOT_DIR}/scripts/config.sub" DESTINATION "${SOURCE_PATH}")

set(OPTIONS "")
if(VCPKG_TARGET_IS_OSX)
    list(APPEND OPTIONS "--disable-Bsymbolic")
endif()

if(VCPKG_TARGET_ARCHITECTURE STREQUAL "loongarch64")
    list(APPEND OPTIONS "--host=loongarch64-linux-gnu")
endif()

if(VCPKG_TARGET_ARCHITECTURE STREQUAL "aarch64")
    list(APPEND OPTIONS "--host=aarch64-linux-gnu")
endif()

if(VCPKG_TARGET_ARCHITECTURE STREQUAL "mips64")
    list(APPEND OPTIONS "--host=mips64el-linux-gnu")
endif()

vcpkg_configure_make(
    USE_WRAPPERS
    SOURCE_PATH "${SOURCE_PATH}"
    OPTIONS
        ${OPTIONS}
)

vcpkg_install_make()

vcpkg_fixup_pkgconfig()

file(REMOVE_RECURSE "${CURRENT_PACKAGES_DIR}/debug/include" 
                    "${CURRENT_PACKAGES_DIR}/libcroco/bin/croco-0.6-config"
                    "${CURRENT_PACKAGES_DIR}/libcroco/debug/bin")

vcpkg_copy_pdbs()
vcpkg_fixup_pkgconfig()

file(COPY "${CURRENT_PORT_DIR}/unofficial-libcroco-config.cmake" DESTINATION "${CURRENT_PACKAGES_DIR}/share/unofficial-libcroco")
file(COPY "${CURRENT_PORT_DIR}/usage" DESTINATION "${CURRENT_PACKAGES_DIR}/share/${PORT}")
vcpkg_install_copyright(FILE_LIST "${SOURCE_PATH}/COPYING")
