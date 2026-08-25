vcpkg_from_github(
    OUT_SOURCE_PATH SOURCE_PATH
    REPO videolan/dav1d
    REF "${VERSION}"
    SHA512 7ee5906640495919462b2242c44a8c3cc577fdda52fc25257792f6df919429d54e4a48c315a7a11759385f044f68d3d6573fd720853f447e2d8520a13693827f
    HEAD_REF master
)

if (VCPKG_TARGET_ARCHITECTURE STREQUAL "x86" OR VCPKG_TARGET_ARCHITECTURE STREQUAL "x64")
    vcpkg_find_acquire_program(NASM)
    get_filename_component(NASM_EXE_PATH ${NASM} DIRECTORY)
    vcpkg_add_to_path(${NASM_EXE_PATH})
elseif (VCPKG_TARGET_IS_WINDOWS)
    vcpkg_find_acquire_program(GASPREPROCESSOR)
    foreach(GAS_PATH ${GASPREPROCESSOR})
        get_filename_component(GAS_ITEM_PATH ${GAS_PATH} DIRECTORY)
        vcpkg_add_to_path(${GAS_ITEM_PATH})
    endforeach(GAS_PATH)
endif()

if(VCPKG_TARGET_IS_OHOS)
    string(APPEND VCPKG_C_FLAGS " -D_POSIX_C_SOURCE=200809L")
    string(APPEND VCPKG_CXX_FLAGS " -D_POSIX_C_SOURCE=200809L")
endif()

# The custom aarch64/mips64 cross toolchains ship libgcc.a but not the
# shared libgcc_s runtime.  Meson's feature probes link small test programs
# before the project link flags are applied, so force the static GCC runtime
# for those targets explicitly.
set(_DAV1D_LINK_ARGS)
if(VCPKG_TARGET_ARCHITECTURE MATCHES "^(aarch64|mips64)$")
    set(_DAV1D_LINK_ARGS "-static-libgcc")
endif()

vcpkg_configure_meson(
    SOURCE_PATH "${SOURCE_PATH}"
    OPTIONS
        -Denable_tests=false
        -Denable_tools=false
        "-Dc_args=-DAT_HWCAP2=26" # add this to enable neon instruction set
        "-Dc_link_args=${_DAV1D_LINK_ARGS}"
        "-Dcpp_link_args=${_DAV1D_LINK_ARGS}"
)

vcpkg_install_meson()
vcpkg_copy_pdbs()
vcpkg_fixup_pkgconfig()

file(INSTALL "${CMAKE_CURRENT_LIST_DIR}/usage" DESTINATION "${CURRENT_PACKAGES_DIR}/share/${PORT}")
vcpkg_install_copyright(FILE_LIST "${SOURCE_PATH}/COPYING")
