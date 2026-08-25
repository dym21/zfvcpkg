set(MBWS_LIBSSH2_ARCHIVE
    "${DOWNLOADS}/mbws/mbws-libssh2-1.11.0.tar.gz")
set(MBWS_LIBSSH2_ARCHIVE_SHA512
    "275ea7e82a7da67dd598bd97095c77f4bb4b7f0333fb494c261fe48cec7ae58f7e6e1bb8a4341f0778d3658451fb0403955928a14b411da021c921bf90e5e1e3")
if(NOT EXISTS "${MBWS_LIBSSH2_ARCHIVE}")
    message(FATAL_ERROR "Missing MBWS libssh2 source cache: ${MBWS_LIBSSH2_ARCHIVE}")
endif()
file(SHA512 "${MBWS_LIBSSH2_ARCHIVE}"
    MBWS_LIBSSH2_ARCHIVE_ACTUAL_SHA512)
if(NOT MBWS_LIBSSH2_ARCHIVE_ACTUAL_SHA512 STREQUAL
   MBWS_LIBSSH2_ARCHIVE_SHA512)
    message(FATAL_ERROR "SHA512 mismatch for ${MBWS_LIBSSH2_ARCHIVE}")
endif()
vcpkg_extract_source_archive(
    SOURCE_PATH
    ARCHIVE "${MBWS_LIBSSH2_ARCHIVE}"
    PATCHES
        gmssl-include-order.patch
)

vcpkg_check_features(OUT_FEATURE_OPTIONS FEATURE_OPTIONS
    FEATURES
        zlib    ENABLE_ZLIB_COMPRESSION
)
if("gmssl" IN_LIST FEATURES)
    if("openssl" IN_LIST FEATURES)
        message(FATAL_ERROR "libssh2[gmssl] cannot be combined with libssh2[openssl]")
    endif()
    list(APPEND FEATURE_OPTIONS
        "-DCRYPTO_BACKEND=OpenSSL"
        "-DOPENSSL_INCLUDE_DIR=${CURRENT_INSTALLED_DIR}/include/mbws-gmssl"
        "-DOPENSSL_SSL_LIBRARY=${CURRENT_INSTALLED_DIR}/lib/mbws-gmssl/libssl.a"
        "-DOPENSSL_CRYPTO_LIBRARY=${CURRENT_INSTALLED_DIR}/lib/mbws-gmssl/libcrypto.a"
        -DOPENSSL_USE_STATIC_LIBS=ON
    )
elseif("openssl" IN_LIST FEATURES)
    list(APPEND FEATURE_OPTIONS "-DCRYPTO_BACKEND=OpenSSL")
elseif(VCPKG_TARGET_IS_WINDOWS)
    list(APPEND FEATURE_OPTIONS "-DCRYPTO_BACKEND=WinCNG")
else()
    message(FATAL_ERROR "Port ${PORT} only supports OpenSSL and WinCNG crypto backends.")
endif()
if(VCPKG_LIBRARY_LINKAGE STREQUAL "dynamic")
    list(APPEND FEATURE_OPTIONS "-DBUILD_STATIC_LIBS:BOOL=OFF")
endif()

vcpkg_find_acquire_program(PKGCONFIG)
set(ENV{PKG_CONFIG} "${PKGCONFIG}")

vcpkg_cmake_configure(
    SOURCE_PATH "${SOURCE_PATH}"
    OPTIONS
        -DBUILD_EXAMPLES=OFF
        -DBUILD_TESTING=OFF
        -DENABLE_DEBUG_LOGGING=OFF
        ${FEATURE_OPTIONS}
)

vcpkg_cmake_install()
vcpkg_copy_pdbs()
vcpkg_fixup_pkgconfig()
vcpkg_cmake_config_fixup(CONFIG_PATH lib/cmake/libssh2)

if("gmssl" IN_LIST FEATURES)
    file(GLOB MBWS_LIBSSH2_CONFIG_FILES
        "${CURRENT_PACKAGES_DIR}/share/libssh2/*.cmake")
    foreach(MBWS_LIBSSH2_CONFIG_FILE IN LISTS MBWS_LIBSSH2_CONFIG_FILES)
        vcpkg_replace_string("${MBWS_LIBSSH2_CONFIG_FILE}"
            "${CURRENT_INSTALLED_DIR}/lib/mbws-gmssl/libssl.a"
            [[mbws-gmssl::ssl]] IGNORE_UNCHANGED)
        vcpkg_replace_string("${MBWS_LIBSSH2_CONFIG_FILE}"
            "${CURRENT_INSTALLED_DIR}/lib/mbws-gmssl/libcrypto.a"
            [[mbws-gmssl::crypto]] IGNORE_UNCHANGED)
    endforeach()
    foreach(MBWS_LIBSSH2_PC IN ITEMS
        "${CURRENT_PACKAGES_DIR}/lib/pkgconfig/libssh2.pc"
        "${CURRENT_PACKAGES_DIR}/debug/lib/pkgconfig/libssh2.pc")
        if(EXISTS "${MBWS_LIBSSH2_PC}")
            vcpkg_replace_string("${MBWS_LIBSSH2_PC}"
                [[libssl,libcrypto,]] [[]] IGNORE_UNCHANGED)
        endif()
    endforeach()
    vcpkg_replace_string(
        "${CURRENT_PACKAGES_DIR}/lib/pkgconfig/libssh2.pc" [[ -lssh2]]
        [[ -lssh2 "${prefix}/lib/mbws-gmssl/libssl.a" "${prefix}/lib/mbws-gmssl/libcrypto.a"]])
    if(EXISTS "${CURRENT_PACKAGES_DIR}/debug/lib/pkgconfig/libssh2.pc")
        vcpkg_replace_string(
            "${CURRENT_PACKAGES_DIR}/debug/lib/pkgconfig/libssh2.pc"
            [[ -lssh2]]
            [[ -lssh2 "${prefix}/../lib/mbws-gmssl/libssl.a" "${prefix}/../lib/mbws-gmssl/libcrypto.a"]])
    endif()
endif()

if (VCPKG_TARGET_IS_WINDOWS)
    if(VCPKG_LIBRARY_LINKAGE STREQUAL "dynamic")
        vcpkg_replace_string("${CURRENT_PACKAGES_DIR}/include/libssh2.h" "defined(_WINDLL)" "1")
    endif()
    if(VCPKG_TARGET_STATIC_LIBRARY_PREFIX STREQUAL "")
        vcpkg_replace_string("${CURRENT_PACKAGES_DIR}/lib/pkgconfig/libssh2.pc" " -lssh2" " -llibssh2")
        if(NOT VCPKG_BUILD_TYPE)
            vcpkg_replace_string("${CURRENT_PACKAGES_DIR}/debug/lib/pkgconfig/libssh2.pc" " -lssh2" " -llibssh2")
        endif()
    endif()
endif()

file(REMOVE_RECURSE "${CURRENT_PACKAGES_DIR}/debug/include")
file(REMOVE_RECURSE "${CURRENT_PACKAGES_DIR}/debug/share")
file(REMOVE_RECURSE "${CURRENT_PACKAGES_DIR}/share/doc")
file(REMOVE_RECURSE "${CURRENT_PACKAGES_DIR}/share/man")

file(INSTALL "${VCPKG_ROOT_DIR}/ports/libssh2/usage" DESTINATION "${CURRENT_PACKAGES_DIR}/share/${PORT}")
if("gmssl" IN_LIST FEATURES)
    file(INSTALL "${CURRENT_PORT_DIR}/libssh2-config.cmake"
        DESTINATION "${CURRENT_PACKAGES_DIR}/share/${PORT}")
    file(INSTALL "${CURRENT_PORT_DIR}/vcpkg-cmake-wrapper.cmake"
        DESTINATION "${CURRENT_PACKAGES_DIR}/share/${PORT}")
endif()
vcpkg_install_copyright(FILE_LIST "${SOURCE_PATH}/COPYING")
