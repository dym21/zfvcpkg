set(MBWS_ARCHIVE
  "${DOWNLOADS}/mbws/mbws-libjson-7.6.1.tar.gz"
)
set(MBWS_ARCHIVE_SHA512
  "51b4d9c995ab81db7cfaa1055e971e86369d86be2701a808f5ee0d68de79997bbdc66d0fce108fec2f83e4532ef857dacb1cd7ed5924d43c8e4ad21e6a1a12dd"
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
)

vcpkg_cmake_configure(
  SOURCE_PATH "${CURRENT_PORT_DIR}"
  OPTIONS "-DMBWS_SOURCE_DIR=${MBWS_SOURCE_DIR}"
)
vcpkg_cmake_install()
vcpkg_cmake_config_fixup(CONFIG_PATH share/mbws-libjson)

file(REMOVE_RECURSE
  "${CURRENT_PACKAGES_DIR}/debug/include"
  "${CURRENT_PACKAGES_DIR}/debug/share"
)
vcpkg_install_copyright(FILE_LIST "${MBWS_SOURCE_DIR}/License.txt")
