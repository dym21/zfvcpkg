vcpkg_check_linkage(ONLY_STATIC_LIBRARY)
set(VCPKG_BUILD_TYPE release)
set(VCPKG_POLICY_MISMATCHED_NUMBER_OF_BINARIES enabled)

if(NOT VCPKG_TARGET_IS_LINUX)
  message(FATAL_ERROR "mbws-gmssl only supports Linux targets")
endif()

set(MBWS_ARCHIVE
  "${DOWNLOADS}/mbws/mbws-gmssl-2.5.0.tar.gz"
)
set(MBWS_ARCHIVE_SHA512
  "608ea5ed4da8d0168fcfa2145bd08dda121b674ab88a168ef62e228f74d6b60e25df88f2476c58ab3bb1f0ac01d76a5c8908022e6ed761a9ee2f28a4a44d7f7f"
)
if(NOT EXISTS "${MBWS_ARCHIVE}")
  message(FATAL_ERROR "Missing MBWS source cache: ${MBWS_ARCHIVE}")
endif()
file(SHA512 "${MBWS_ARCHIVE}" MBWS_ARCHIVE_ACTUAL_SHA512)
if(NOT MBWS_ARCHIVE_ACTUAL_SHA512 STREQUAL MBWS_ARCHIVE_SHA512)
  message(FATAL_ERROR "SHA512 mismatch for ${MBWS_ARCHIVE}")
endif()
vcpkg_extract_source_archive(
  SOURCE_PATH
  ARCHIVE "${MBWS_ARCHIVE}"
  PATCHES
    reject-unimplemented-sm2-share-key.patch
    enable-gmtls-exporter.patch
    fix-ssl-accept-return.patch
    declare-log-helper.patch
    fix-modern-c-types.patch
)

find_program(MBWS_MAKE NAMES make gmake REQUIRED)
vcpkg_find_acquire_program(PERL)
set(MBWS_CONFIGURE_FLAGS)
if(VCPKG_TARGET_ARCHITECTURE STREQUAL "x64")
  set(MBWS_CONFIGURE_TARGET linux-x86_64)
  set(MBWS_TOOLCHAIN_ROOT
    "/opt/zftoolchain/x86_64-zftoolchain-linux-gnu-x86_64")
  set(MBWS_TOOLCHAIN_NAME x86_64-zftoolchain-linux-gnu)
elseif(VCPKG_TARGET_ARCHITECTURE STREQUAL "aarch64")
  set(MBWS_CONFIGURE_TARGET linux-aarch64)
  set(MBWS_TOOLCHAIN_ROOT
    "/opt/zftoolchain/aarch64-zftoolchain-linux-gnu-x86_64")
  set(MBWS_TOOLCHAIN_NAME aarch64-zftoolchain-linux-gnu)
elseif(VCPKG_TARGET_ARCHITECTURE STREQUAL "mips64")
  set(MBWS_CONFIGURE_TARGET linux64-mips64)
  set(MBWS_TOOLCHAIN_ROOT
    "/opt/zftoolchain/mips64el-zftoolchain-linux-gnu-x86_64")
  set(MBWS_TOOLCHAIN_NAME mips64el-zftoolchain-linux-gnu)
  list(APPEND MBWS_CONFIGURE_FLAGS -DL_ENDIAN -march=mips64)
elseif(VCPKG_TARGET_ARCHITECTURE STREQUAL "loongarch64")
  set(MBWS_CONFIGURE_TARGET linux-generic64)
  list(APPEND MBWS_CONFIGURE_FLAGS -DL_ENDIAN)
  if(TARGET_TRIPLET MATCHES "oldworld$")
    set(MBWS_TOOLCHAIN_ROOT
      "/opt/zftoolchain/loongarch64-zftoolchain-linux-gnu-oldworld-x86_64")
    set(MBWS_TOOLCHAIN_NAME loongarch64-linux-gnu)
  elseif(TARGET_TRIPLET MATCHES "newworld$")
    set(MBWS_TOOLCHAIN_ROOT
      "/opt/zftoolchain/loongarch64-zftoolchain-linux-gnu-newworld-x86_64")
    set(MBWS_TOOLCHAIN_NAME loongarch64-zftoolchain-linux-gnu)
  else()
    message(FATAL_ERROR "Unknown LoongArch ABI triplet: ${TARGET_TRIPLET}")
  endif()
else()
  message(FATAL_ERROR
    "Unsupported mbws-gmssl architecture: ${VCPKG_TARGET_ARCHITECTURE}")
endif()
set(MBWS_CROSS_PREFIX
  "${MBWS_TOOLCHAIN_ROOT}/bin/${MBWS_TOOLCHAIN_NAME}-")
foreach(MBWS_TOOL IN ITEMS gcc ar ranlib)
  if(NOT EXISTS "${MBWS_CROSS_PREFIX}${MBWS_TOOL}")
    message(FATAL_ERROR "Missing cross tool: ${MBWS_CROSS_PREFIX}${MBWS_TOOL}")
  endif()
endforeach()

# GmSSL and the regular vcpkg OpenSSL deliberately coexist. Keep this build
# outside vcpkg_configure_make so its injected OpenSSL include path cannot
# leak into GmSSL's source tree.
set(MBWS_BUILD_DIR "${CURRENT_BUILDTREES_DIR}/${TARGET_TRIPLET}-rel")
file(REMOVE_RECURSE "${MBWS_BUILD_DIR}")
file(MAKE_DIRECTORY "${MBWS_BUILD_DIR}")
set(MBWS_CLEAN_ENV
  "${CMAKE_COMMAND}" -E env
  --unset=CPATH
  --unset=C_INCLUDE_PATH
  --unset=CPLUS_INCLUDE_PATH
  --unset=CPPFLAGS
  --unset=CC
  --unset=AR
  --unset=RANLIB
)
vcpkg_execute_required_process(
  COMMAND
    ${MBWS_CLEAN_ENV}
    "${PERL}" "${SOURCE_PATH}/Configure"
    "${MBWS_CONFIGURE_TARGET}"
    no-shared
    no-asm
    no-unit-test
    no-fuzz
    no-zlib
    -fPIC
    ${MBWS_CONFIGURE_FLAGS}
    "--cross-compile-prefix=${MBWS_CROSS_PREFIX}"
    "--prefix=${CURRENT_PACKAGES_DIR}"
    --openssldir=/etc/ssl
    --libdir=lib
  WORKING_DIRECTORY "${MBWS_BUILD_DIR}"
  LOGNAME "configure-${TARGET_TRIPLET}-rel"
)
vcpkg_execute_build_process(
  COMMAND ${MBWS_CLEAN_ENV} "${MBWS_MAKE}" -j30 build_libs
  WORKING_DIRECTORY "${MBWS_BUILD_DIR}"
  LOGNAME "build-${TARGET_TRIPLET}-rel"
)
vcpkg_execute_build_process(
  COMMAND ${MBWS_CLEAN_ENV} "${MBWS_MAKE}" install_dev
  WORKING_DIRECTORY "${MBWS_BUILD_DIR}"
  LOGNAME "install-${TARGET_TRIPLET}-rel"
)

file(MAKE_DIRECTORY "${CURRENT_PACKAGES_DIR}/lib/mbws-gmssl")
foreach(MBWS_LIBRARY IN ITEMS ssl crypto)
  file(RENAME
    "${CURRENT_PACKAGES_DIR}/lib/lib${MBWS_LIBRARY}.a"
    "${CURRENT_PACKAGES_DIR}/lib/mbws-gmssl/lib${MBWS_LIBRARY}.a"
  )
endforeach()

file(MAKE_DIRECTORY "${CURRENT_PACKAGES_DIR}/include/mbws-gmssl")
file(RENAME
  "${CURRENT_PACKAGES_DIR}/include/openssl"
  "${CURRENT_PACKAGES_DIR}/include/mbws-gmssl/openssl"
)
file(REMOVE_RECURSE
  "${CURRENT_PACKAGES_DIR}/lib/pkgconfig"
)

file(INSTALL
  "${CURRENT_PORT_DIR}/mbws-gmssl-config.cmake"
  "${CURRENT_PORT_DIR}/usage"
  DESTINATION "${CURRENT_PACKAGES_DIR}/share/mbws-gmssl"
)
vcpkg_install_copyright(FILE_LIST "${SOURCE_PATH}/LICENSE")
