vcpkg_from_github(
    OUT_SOURCE_PATH SOURCE_PATH
    REPO yanyiwu/cppjieba
    REF v5.6.7
    SHA512 8543acb8e39875509c8f0eef1e054d6c7fe028ace047f181d358d46373f5ff4f7c7c766c0df9c0eb30cad90d2044ac2d651a3013c4effaabd2e7ac302e23d977
    HEAD_REF master
)

file(INSTALL "${SOURCE_PATH}/include/"
     DESTINATION "${CURRENT_PACKAGES_DIR}/include")
file(INSTALL "${SOURCE_PATH}/dict/"
     DESTINATION "${CURRENT_PACKAGES_DIR}/share/${PORT}/dict")
file(INSTALL "${CMAKE_CURRENT_LIST_DIR}/cppjieba-config.cmake"
     DESTINATION "${CURRENT_PACKAGES_DIR}/share/${PORT}")
file(INSTALL "${CMAKE_CURRENT_LIST_DIR}/usage"
     DESTINATION "${CURRENT_PACKAGES_DIR}/share/${PORT}")
vcpkg_install_copyright(FILE_LIST "${SOURCE_PATH}/LICENSE")
