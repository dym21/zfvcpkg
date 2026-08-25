vcpkg_from_github(
    OUT_SOURCE_PATH SOURCE_PATH
    REPO BLAKE2/libb2
    REF 2c5142f12a2cd52f3ee0a43e50a3a76f75badf85
    SHA512 cf29cf9391ae37a978eb6618de6f856f3defa622b8f56c2d5a519ab34fd5e4d91f3bb868601a44e9c9164a2992e80dde188ccc4d1605dffbdf93687336226f8d
    HEAD_REF master
)

# The x86_64 cross linker shipped with the target SDK cannot decompress
# zlib-compressed DWARF sections emitted by GCC.  Keep debug information
# uncompressed for this triplet so dependent ports (notably python3) link
# successfully; other architectures retain the toolchain defaults.
if(VCPKG_TARGET_TRIPLET STREQUAL "cross-x64-linux-x86")
    set(ENV{CFLAGS} "$ENV{CFLAGS} -gz=none")
    set(ENV{CXXFLAGS} "$ENV{CXXFLAGS} -gz=none")
endif()

vcpkg_make_configure(
    AUTORECONF
    SOURCE_PATH "${SOURCE_PATH}"
    OPTIONS
        --disable-native            # toolchain may supply -march=native
        ax_cv_check_cflags___O3=no  # vcpkg provides actual flag
)
vcpkg_make_install()
vcpkg_fixup_pkgconfig()
vcpkg_copy_pdbs()

file(REMOVE_RECURSE "${CURRENT_PACKAGES_DIR}/debug/include")

vcpkg_install_copyright(FILE_LIST "${SOURCE_PATH}/COPYING")
