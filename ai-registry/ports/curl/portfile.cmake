set(MBWS_CURL_ARCHIVE
    "${DOWNLOADS}/mbws/mbws-curl-8.21.0-vcpkg-base.tar.gz")
set(MBWS_CURL_ARCHIVE_SHA512
    "85add161f2546d72c1ea3b32756d32d4893b09a4125dabb743413d62fc7e279537f20c8b223302ba8accbcc3e71dddf093c63dad89a1b4ef3c7372a3f7f4d5d7")
if(NOT EXISTS "${MBWS_CURL_ARCHIVE}")
    message(FATAL_ERROR "Missing MBWS curl source cache: ${MBWS_CURL_ARCHIVE}")
endif()
file(SHA512 "${MBWS_CURL_ARCHIVE}" MBWS_CURL_ARCHIVE_ACTUAL_SHA512)
if(NOT MBWS_CURL_ARCHIVE_ACTUAL_SHA512 STREQUAL
   MBWS_CURL_ARCHIVE_SHA512)
    message(FATAL_ERROR "SHA512 mismatch for ${MBWS_CURL_ARCHIVE}")
endif()
vcpkg_extract_source_archive(
    SOURCE_PATH
    ARCHIVE "${MBWS_CURL_ARCHIVE}"
    PATCHES
        gmssl.patch
)

vcpkg_check_features(OUT_FEATURE_OPTIONS FEATURE_OPTIONS
    FEATURES
        brotli      CURL_BROTLI
        c-ares      ENABLE_ARES
        gnutls      CURL_USE_GNUTLS
        gsasl       CURL_USE_GSASL
        gssapi      CURL_USE_GSSAPI
        gssapi      VCPKG_LOCK_FIND_PACKAGE_GSS
        http2       USE_NGHTTP2
        http2       VCPKG_LOCK_FIND_PACKAGE_NGHTTP2
        http3       USE_NGTCP2
        httpsrr     USE_HTTPSRR
        idn2        USE_LIBIDN2
        idn2        VCPKG_LOCK_FIND_PACKAGE_Libidn2
        ldap        VCPKG_LOCK_FIND_PACKAGE_LDAP
        mbedtls     CURL_USE_MBEDTLS
        openssl     CURL_CA_FALLBACK
        openssl     CURL_USE_OPENSSL
        psl         CURL_USE_LIBPSL
        ssh         CURL_USE_LIBSSH2
        ssh         VCPKG_LOCK_FIND_PACKAGE_Libssh2
        ssls-export USE_SSLS_EXPORT
        sspi        CURL_WINDOWS_SSPI
        tool        BUILD_CURL_EXE
        winidn      USE_WIN32_IDN
        wolfssl     CURL_USE_WOLFSSL
        zstd        CURL_ZSTD
    INVERTED_FEATURES
        ldap        CURL_DISABLE_LDAP
        ldap        CURL_DISABLE_LDAPS
        non-http    HTTP_ONLY
        websockets  CURL_DISABLE_WEBSOCKETS
)

if("gmssl" IN_LIST FEATURES)
    if(NOT VCPKG_TARGET_IS_LINUX)
        message(FATAL_ERROR "curl[gmssl] only supports Linux targets")
    endif()
    foreach(MBWS_TLS_FEATURE IN ITEMS openssl ssl gnutls mbedtls wolfssl)
        if(MBWS_TLS_FEATURE IN_LIST FEATURES)
            message(FATAL_ERROR
                "curl[gmssl] cannot be combined with curl[${MBWS_TLS_FEATURE}]")
        endif()
    endforeach()
endif()

if("ssl" IN_LIST FEATURES AND
    NOT "http3" IN_LIST FEATURES AND
    # Match curl[ssl]'s "platform": "windows & !uwp"
    (VCPKG_TARGET_IS_WINDOWS AND NOT VCPKG_TARGET_IS_UWP))
    list(APPEND FEATURE_OPTIONS -DCURL_USE_SCHANNEL=ON)
endif()

if("http3" IN_LIST FEATURES AND
    ("wolfssl" IN_LIST FEATURES OR
     "mbedtls" IN_LIST FEATURES OR
     "gnutls" IN_LIST FEATURES))
    message(FATAL_ERROR "http3 is incompatible with curl multi-ssl, preventing combination with wolfssl, mbedtls or \
gnutls in vcpkg's curated registry. To use curl http3 on ngtcp2 on one of the other TLS backends, author an \
overlay-port which exchanges curl[ssl]'s and curl[http3]'s openssl dependencies with the backend you want.")
endif()

set(OPTIONS "")

set(MBWS_CURL_USE_PKGCONFIG ON)
if("gmssl" IN_LIST FEATURES)
    set(MBWS_CURL_USE_PKGCONFIG OFF)
    list(APPEND FEATURE_OPTIONS -DCURL_USE_OPENSSL=ON)
    list(APPEND OPTIONS
        "-DCMAKE_C_FLAGS=-I${CURRENT_INSTALLED_DIR}/include/mbws-gmssl"
        "-DOPENSSL_INCLUDE_DIR=${CURRENT_INSTALLED_DIR}/include/mbws-gmssl"
        "-DOPENSSL_SSL_LIBRARY=${CURRENT_INSTALLED_DIR}/lib/mbws-gmssl/libssl.a"
        "-DOPENSSL_CRYPTO_LIBRARY=${CURRENT_INSTALLED_DIR}/lib/mbws-gmssl/libcrypto.a"
        -DOPENSSL_USE_STATIC_LIBS=ON
    )
endif()

if(VCPKG_TARGET_IS_UWP)
    list(APPEND OPTIONS
        -DCURL_DISABLE_TELNET=ON
        -DENABLE_UNIX_SOCKETS=OFF
    )
endif()

if(VCPKG_TARGET_IS_WINDOWS)
    list(APPEND OPTIONS -DENABLE_UNICODE=ON)
endif()

if(VCPKG_TARGET_IS_APPLE AND
    ("openssl" IN_LIST FEATURES OR "gnutls" IN_LIST FEATURES))
    list(APPEND OPTIONS -DUSE_APPLE_SECTRUST=ON)
endif()

vcpkg_find_acquire_program(PKGCONFIG)
set(ENV{PKG_CONFIG} "${PKGCONFIG}")

vcpkg_cmake_configure(
    SOURCE_PATH "${SOURCE_PATH}"
    OPTIONS
        "-DCMAKE_PROJECT_INCLUDE=${VCPKG_ROOT_DIR}/ports/curl/cmake-project-include.cmake"
        ${FEATURE_OPTIONS}
        ${OPTIONS}
        -DBUILD_TESTING=OFF
        -DENABLE_CURL_MANUAL=OFF
        -DIMPORT_LIB_SUFFIX=   # empty
        -DSHARE_LIB_OBJECT=OFF
        -DCURL_USE_CMAKECONFIG=ON
        "-DCURL_USE_PKGCONFIG=${MBWS_CURL_USE_PKGCONFIG}"
        -DCMAKE_DISABLE_FIND_PACKAGE_Perl=ON
    MAYBE_UNUSED_VARIABLES
        VCPKG_LOCK_FIND_PACKAGE_GSS
        VCPKG_LOCK_FIND_PACKAGE_LDAP
        VCPKG_LOCK_FIND_PACKAGE_Libidn2
        VCPKG_LOCK_FIND_PACKAGE_Libssh2
        VCPKG_LOCK_FIND_PACKAGE_NGHTTP2
)
vcpkg_cmake_install()
vcpkg_copy_pdbs()
vcpkg_cmake_config_fixup(CONFIG_PATH lib/cmake/CURL)

if("gmssl" IN_LIST FEATURES)
    set(MBWS_CURL_CONFIG
        "${CURRENT_PACKAGES_DIR}/share/curl/CURLConfig.cmake")
    vcpkg_replace_string("${MBWS_CURL_CONFIG}"
        [[find_dependency(OpenSSL "1")]]
        [[find_dependency(mbws-gmssl CONFIG)]])
    vcpkg_replace_string("${MBWS_CURL_CONFIG}"
        [[find_dependency(OpenSSL)]]
        [[find_dependency(mbws-gmssl CONFIG)]])
    file(GLOB MBWS_CURL_TARGET_FILES
        "${CURRENT_PACKAGES_DIR}/share/curl/CURLTargets*.cmake")
    list(APPEND MBWS_CURL_TARGET_FILES "${MBWS_CURL_CONFIG}")
    foreach(MBWS_CURL_TARGET_FILE IN LISTS MBWS_CURL_TARGET_FILES)
        vcpkg_replace_string("${MBWS_CURL_TARGET_FILE}"
            [[OpenSSL::SSL]] [[mbws-gmssl::ssl]] IGNORE_UNCHANGED)
        vcpkg_replace_string("${MBWS_CURL_TARGET_FILE}"
            [[OpenSSL::Crypto]] [[mbws-gmssl::crypto]] IGNORE_UNCHANGED)
    endforeach()
endif()

vcpkg_fixup_pkgconfig()
if("gmssl" IN_LIST FEATURES)
    set(MBWS_CURL_PC "${CURRENT_PACKAGES_DIR}/lib/pkgconfig/libcurl.pc")
    vcpkg_replace_string("${MBWS_CURL_PC}"
        [[openssl,]] [[]] IGNORE_UNCHANGED)
    vcpkg_replace_string("${MBWS_CURL_PC}"
        [[,openssl]] [[]] IGNORE_UNCHANGED)
    vcpkg_replace_string("${MBWS_CURL_PC}" [[ -lcurl ]]
        [[ -lcurl "${prefix}/lib/mbws-gmssl/libssl.a" "${prefix}/lib/mbws-gmssl/libcrypto.a" ]])
    if(NOT DEFINED VCPKG_BUILD_TYPE)
        set(MBWS_CURL_DEBUG_PC
            "${CURRENT_PACKAGES_DIR}/debug/lib/pkgconfig/libcurl.pc")
        vcpkg_replace_string("${MBWS_CURL_DEBUG_PC}"
            [[openssl,]] [[]] IGNORE_UNCHANGED)
        vcpkg_replace_string("${MBWS_CURL_DEBUG_PC}"
            [[,openssl]] [[]] IGNORE_UNCHANGED)
        vcpkg_replace_string("${MBWS_CURL_DEBUG_PC}" [[ -lcurl ]]
            [[ -lcurl "${prefix}/../lib/mbws-gmssl/libssl.a" "${prefix}/../lib/mbws-gmssl/libcrypto.a" ]])
    endif()
endif()
set(namespec "curl")
if(VCPKG_TARGET_IS_WINDOWS AND NOT VCPKG_TARGET_IS_MINGW)
    set(namespec "libcurl")
    vcpkg_replace_string("${CURRENT_PACKAGES_DIR}/lib/pkgconfig/libcurl.pc" " -lcurl" " -l${namespec}")
endif()
if(NOT DEFINED VCPKG_BUILD_TYPE)
    vcpkg_replace_string("${CURRENT_PACKAGES_DIR}/debug/lib/pkgconfig/libcurl.pc" " -lcurl" " -l${namespec}-d")
endif()

if ("tool" IN_LIST FEATURES)
    vcpkg_copy_tools(TOOL_NAMES curl AUTO_CLEAN)
endif()

vcpkg_replace_string("${CURRENT_PACKAGES_DIR}/bin/curl-config" "${CURRENT_PACKAGES_DIR}" "\${prefix}")
vcpkg_replace_string("${CURRENT_PACKAGES_DIR}/bin/curl-config" "${CURRENT_INSTALLED_DIR}" "\${prefix}" IGNORE_UNCHANGED)
vcpkg_replace_string("${CURRENT_PACKAGES_DIR}/bin/curl-config" "\nprefix='\${prefix}'" [=[prefix=$(CDPATH= cd -- "$(dirname -- "$0")"/../../.. && pwd -P)]=])
file(MAKE_DIRECTORY "${CURRENT_PACKAGES_DIR}/tools/${PORT}/bin")
file(RENAME "${CURRENT_PACKAGES_DIR}/bin/curl-config" "${CURRENT_PACKAGES_DIR}/tools/${PORT}/bin/curl-config")
if(EXISTS "${CURRENT_PACKAGES_DIR}/debug/bin/curl-config")
    vcpkg_replace_string("${CURRENT_PACKAGES_DIR}/debug/bin/curl-config" "${CURRENT_PACKAGES_DIR}" "\${prefix}")
    vcpkg_replace_string("${CURRENT_PACKAGES_DIR}/debug/bin/curl-config" "${CURRENT_INSTALLED_DIR}" "\${prefix}" IGNORE_UNCHANGED)
    vcpkg_replace_string("${CURRENT_PACKAGES_DIR}/debug/bin/curl-config" "\nprefix='\${prefix}/debug'" [=[prefix=$(CDPATH= cd -- "$(dirname -- "$0")"/../../../.. && pwd -P)]=])
    vcpkg_replace_string("${CURRENT_PACKAGES_DIR}/debug/bin/curl-config" "\nexec_prefix=\"\${prefix}\"" "\nexec_prefix=\"\${prefix}/debug\"")
    vcpkg_replace_string("${CURRENT_PACKAGES_DIR}/debug/bin/curl-config" "-lcurl" "-l${namespec}-d")
    vcpkg_replace_string("${CURRENT_PACKAGES_DIR}/debug/bin/curl-config" "curl." "curl-d.")
    file(MAKE_DIRECTORY "${CURRENT_PACKAGES_DIR}/tools/${PORT}/debug/bin")
    file(RENAME "${CURRENT_PACKAGES_DIR}/debug/bin/curl-config" "${CURRENT_PACKAGES_DIR}/tools/${PORT}/debug/bin/curl-config")
endif()

file(REMOVE_RECURSE "${CURRENT_PACKAGES_DIR}/debug/include")
file(REMOVE_RECURSE "${CURRENT_PACKAGES_DIR}/debug/share")
if(VCPKG_LIBRARY_LINKAGE STREQUAL "static" OR NOT VCPKG_TARGET_IS_WINDOWS)
    file(REMOVE_RECURSE "${CURRENT_PACKAGES_DIR}/bin")
    file(REMOVE_RECURSE "${CURRENT_PACKAGES_DIR}/debug/bin")
endif()

if(VCPKG_LIBRARY_LINKAGE STREQUAL "static")
    vcpkg_replace_string("${CURRENT_PACKAGES_DIR}/include/curl/curl.h"
        "#ifdef CURL_STATICLIB"
        "#if 1"
    )
endif()

file(INSTALL "${VCPKG_ROOT_DIR}/ports/curl/vcpkg-cmake-wrapper.cmake" DESTINATION "${CURRENT_PACKAGES_DIR}/share/${PORT}")
file(INSTALL "${VCPKG_ROOT_DIR}/ports/curl/usage" DESTINATION "${CURRENT_PACKAGES_DIR}/share/${PORT}")

file(READ "${SOURCE_PATH}/lib/curlx/inet_ntop.c" inet_ntop_c)
string(REGEX REPLACE "#i.*" "" inet_ntop_c "${inet_ntop_c}")
set(inet_ntop_copyright "${CURRENT_BUILDTREES_DIR}/inet_ntop.c and inet_pton.c Notice")
file(WRITE "${inet_ntop_copyright}" "${inet_ntop_c}")

vcpkg_install_copyright(
    FILE_LIST
        "${SOURCE_PATH}/COPYING"
        "${inet_ntop_copyright}"
)
