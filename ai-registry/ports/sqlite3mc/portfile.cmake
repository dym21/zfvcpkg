set(MBWS_ARCHIVE
  "${DOWNLOADS}/mbws/sqlite3mc-2.2.6-mbws.tar.gz"
)
set(MBWS_ARCHIVE_SHA512
  "2677f0737b20e58152a557b627d65df6fe204799ef31e021ea338c4138ba62645addbf86898331dee20c790b9714f6450347f426a6a093c6edacdd0aec98d8cc"
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
  SOURCE_PATH
  ARCHIVE "${MBWS_ARCHIVE}"
  PATCHES architecture-flags.patch
)
vcpkg_check_features(
  OUT_FEATURE_OPTIONS FEATURE_OPTIONS
  FEATURES tool SQLITE3MC_BUILD_SHELL
)
vcpkg_cmake_configure(
  SOURCE_PATH "${SOURCE_PATH}"
  OPTIONS
    -DSQLITE3MC_STATIC=ON
    -DSQLITE3MC_BUILD_SHELL=OFF
    ${FEATURE_OPTIONS}
)
vcpkg_cmake_install()
vcpkg_cmake_config_fixup(CONFIG_PATH lib/cmake/sqlite3mc)

if("tool" IN_LIST FEATURES)
  vcpkg_copy_tools(TOOL_NAMES sqlite3mc_shell AUTO_CLEAN)
endif()

file(REMOVE_RECURSE
  "${CURRENT_PACKAGES_DIR}/debug/include"
  "${CURRENT_PACKAGES_DIR}/debug/share"
)
vcpkg_install_copyright(FILE_LIST "${SOURCE_PATH}/LICENSE")
