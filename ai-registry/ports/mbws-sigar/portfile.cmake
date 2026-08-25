set(MBWS_ARCHIVE
  "${DOWNLOADS}/mbws/mbws-sigar-1.6.2.tar.gz"
)
set(MBWS_ARCHIVE_SHA512
  "2575256e000563eeefb3ff3ce7e793e5f0806d30ceb207d279f25916d2e8087100f1d33af3bb797457f788ef5a99998c8ece5703383fd6feb0acd88ac14959b1"
)
if(NOT EXISTS "${MBWS_ARCHIVE}")
  message(FATAL_ERROR
    "Missing MBWS source cache: ${MBWS_ARCHIVE}"
  )
endif()
file(SHA512 "${MBWS_ARCHIVE}" MBWS_ARCHIVE_ACTUAL_SHA512)
if(NOT MBWS_ARCHIVE_ACTUAL_SHA512 STREQUAL MBWS_ARCHIVE_SHA512)
  message(FATAL_ERROR "SHA512 mismatch for ${MBWS_ARCHIVE}")
endif()
vcpkg_extract_source_archive(
  MBWS_SOURCE_DIR
  ARCHIVE "${MBWS_ARCHIVE}"
  PATCHES
    portable-terminal-api.patch
    avoid-device-macro-shadowing.patch
    optional-system-rpc.patch
)

vcpkg_cmake_configure(
  SOURCE_PATH "${MBWS_SOURCE_DIR}"
  OPTIONS
    -DBUILD_SHARED_LIBS=OFF
    -DBUILD_TESTING=OFF
)
vcpkg_cmake_install()

file(REMOVE_RECURSE
  "${CURRENT_PACKAGES_DIR}/debug/include"
  "${CURRENT_PACKAGES_DIR}/debug/share"
)
file(INSTALL "${CURRENT_PORT_DIR}/mbws-sigar-config.cmake"
  DESTINATION "${CURRENT_PACKAGES_DIR}/share/mbws-sigar"
)
vcpkg_install_copyright(
  FILE_LIST
    "${MBWS_SOURCE_DIR}/LICENSE"
    "${MBWS_SOURCE_DIR}/NOTICE"
)
