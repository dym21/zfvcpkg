vcpkg_check_linkage(ONLY_STATIC_LIBRARY)

vcpkg_from_github(
    OUT_SOURCE_PATH SOURCE_PATH
    REPO snowballstem/snowball
    REF v3.1.1
    SHA512 47a33f6319a728238b93b344a29c49b9aeb76bc8202b891da8134660be97d256e35980a25e557637c74fa6a8aff00b7e2d8e406d52b03233b71644989e4be9ac
    HEAD_REF master
)

# Snowball's repository contains its generator, but not the generated C files.
# Build the generator with a host compiler and GNU make, then compile the
# generated target sources with the vcpkg target toolchain below.
vcpkg_find_acquire_program(PERL)
get_filename_component(perl_dir "${PERL}" DIRECTORY)
vcpkg_add_to_path("${perl_dir}")

if(VCPKG_TARGET_IS_WINDOWS)
    vcpkg_find_acquire_program(CLANG)
    vcpkg_acquire_msys(MSYS_ROOT PACKAGES make)
    vcpkg_add_to_path(PREPEND "${MSYS_ROOT}/usr/bin")
    set(SNOWBALL_HOST_CC "${CLANG}")
    set(SNOWBALL_HOST_MAKE "${MSYS_ROOT}/usr/bin/make.exe")
else()
    find_program(SNOWBALL_HOST_CC NAMES cc gcc REQUIRED)
    find_program(SNOWBALL_HOST_MAKE NAMES make gmake REQUIRED)
endif()

set(snowball_codegen_targets
    libstemmer/libstemmer_utf8.c
    libstemmer/modules_utf8.h
)
file(STRINGS "${SOURCE_PATH}/libstemmer/modules.txt" snowball_modules)
foreach(line IN LISTS snowball_modules)
    if(line MATCHES "^([a-z_]+)[ \t]+([A-Z_0-9,]+)")
        list(APPEND snowball_codegen_targets
             "src_c/stem_UTF_8_${CMAKE_MATCH_1}.c")
    endif()
endforeach()

vcpkg_execute_required_process(
    COMMAND "${SNOWBALL_HOST_MAKE}"
            ${snowball_codegen_targets}
            "CC=${SNOWBALL_HOST_CC}"
            "CFLAGS=-O2"
    WORKING_DIRECTORY "${SOURCE_PATH}"
    LOGNAME codegen-${TARGET_TRIPLET}
)

vcpkg_cmake_configure(
    SOURCE_PATH "${CMAKE_CURRENT_LIST_DIR}"
    OPTIONS "-DSNOWBALL_SOURCE_DIR=${SOURCE_PATH}"
)
vcpkg_cmake_install()
vcpkg_cmake_config_fixup(CONFIG_PATH lib/cmake/snowball)
vcpkg_copy_pdbs()

file(REMOVE_RECURSE
    "${CURRENT_PACKAGES_DIR}/debug/include"
    "${CURRENT_PACKAGES_DIR}/debug/share"
)
file(INSTALL "${CMAKE_CURRENT_LIST_DIR}/usage"
     DESTINATION "${CURRENT_PACKAGES_DIR}/share/${PORT}")
vcpkg_install_copyright(FILE_LIST "${SOURCE_PATH}/COPYING")
