vcpkg_check_linkage(ONLY_STATIC_LIBRARY)
set(VCPKG_BUILD_TYPE release)
set(VCPKG_POLICY_MISMATCHED_NUMBER_OF_BINARIES enabled)

set(MBWS_SM_ARCHIVE
    "${DOWNLOADS}/mbws/mbws-sm-1.0.0.tar.gz")
set(MBWS_SM_ARCHIVE_SHA512
    "39d7ec37d49e0b629c2e9efd4cbd27ceda1edc42225e1c59b3ead716e6fd578135623cec0c74ac94f3471e9bedd79c57e11a4a673ce1568ce341677f785fc281")
if(NOT EXISTS "${MBWS_SM_ARCHIVE}")
    message(FATAL_ERROR "Missing MBWS SM source cache: ${MBWS_SM_ARCHIVE}")
endif()
file(SHA512 "${MBWS_SM_ARCHIVE}" MBWS_SM_ACTUAL_SHA512)
if(NOT MBWS_SM_ACTUAL_SHA512 STREQUAL MBWS_SM_ARCHIVE_SHA512)
    message(FATAL_ERROR "SHA512 mismatch for ${MBWS_SM_ARCHIVE}")
endif()

vcpkg_extract_source_archive(
    SOURCE_PATH
    ARCHIVE "${MBWS_SM_ARCHIVE}"
    PATCHES
        declare-bn-reverse.patch
        fix-sm2-fixed-width-key-output.patch
)
file(COPY
    "${CURRENT_PORT_DIR}/CMakeLists.txt"
    "${CURRENT_PORT_DIR}/mbws-sm-config.cmake.in"
    DESTINATION "${SOURCE_PATH}"
)

vcpkg_cmake_configure(SOURCE_PATH "${SOURCE_PATH}")
vcpkg_cmake_install()
vcpkg_cmake_config_fixup(CONFIG_PATH lib/cmake/mbws-sm)

file(REMOVE_RECURSE
    "${CURRENT_PACKAGES_DIR}/debug"
    "${CURRENT_PACKAGES_DIR}/lib/cmake"
)
file(INSTALL
    "${CURRENT_PORT_DIR}/usage"
    "${CURRENT_PORT_DIR}/copyright"
    DESTINATION "${CURRENT_PACKAGES_DIR}/share/${PORT}"
)
