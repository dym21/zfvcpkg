vcpkg_from_github(
    OUT_SOURCE_PATH SOURCE_PATH
    REPO ZungBang/undbx
    REF 7fd247ff4684f934b6006d7915e5803c896e3807
    SHA512 610a1080b6180cd4e395314fca19a6c46f1cb37b82b813d5d941e2245424d441ac82273ac130e0dfa53114744afed408e5b1a3071d73a54f4fcdb3539e4bad64
    PATCHES
        add-extract-api.patch
)

file(COPY "${CMAKE_CURRENT_LIST_DIR}/CMakeLists.txt" DESTINATION "${SOURCE_PATH}")
file(COPY "${CMAKE_CURRENT_LIST_DIR}/extract_dbx.h" DESTINATION "${SOURCE_PATH}")
file(COPY "${CMAKE_CURRENT_LIST_DIR}/undbx-config.cmake.in" DESTINATION "${SOURCE_PATH}")

vcpkg_cmake_configure(SOURCE_PATH "${SOURCE_PATH}")
vcpkg_cmake_install()

file(REMOVE_RECURSE
    "${CURRENT_PACKAGES_DIR}/debug/include"
    "${CURRENT_PACKAGES_DIR}/debug/share"
)
vcpkg_install_copyright(FILE_LIST "${SOURCE_PATH}/COPYING")
