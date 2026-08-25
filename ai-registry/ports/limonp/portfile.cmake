vcpkg_from_github(
    OUT_SOURCE_PATH SOURCE_PATH
    REPO yanyiwu/limonp
    REF v1.0.2
    SHA512 a56f749b86943283381ccfb01b3edfaf338dec4c34eb1bfdbe00e08b33bc36fa277bde3588e18d4752feedf534541a285d34a5b06041bd8c7b96930012e98814
    HEAD_REF master
)

vcpkg_cmake_configure(
    SOURCE_PATH "${SOURCE_PATH}"
    OPTIONS -DENABLE_UNIT_TESTS=OFF
)
vcpkg_cmake_install()
vcpkg_cmake_config_fixup(CONFIG_PATH lib/cmake/limonp)

file(REMOVE_RECURSE
    "${CURRENT_PACKAGES_DIR}/debug/include"
    "${CURRENT_PACKAGES_DIR}/debug/lib"
    "${CURRENT_PACKAGES_DIR}/debug/share"
    "${CURRENT_PACKAGES_DIR}/lib"
)

file(INSTALL "${CMAKE_CURRENT_LIST_DIR}/usage"
     DESTINATION "${CURRENT_PACKAGES_DIR}/share/${PORT}")
vcpkg_install_copyright(FILE_LIST "${SOURCE_PATH}/LICENSE")
