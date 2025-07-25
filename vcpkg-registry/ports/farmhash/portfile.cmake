#Requires a compiler which understands '__builtin_unreachable': 
vcpkg_check_linkage(ONLY_STATIC_LIBRARY) 

vcpkg_download_distfile(WIN_PR_PATCH
    URLS "https://github.com/google/farmhash/pull/40.diff"
    FILENAME farmhash-pr-40.patch
    SHA512 265f5c15c17da2b88c82e6016a181abe73d2d94492cdb0cba892acf67a9d40815d54fa81e07351254fe2a39aea143b125924db0e7df14aac84a7469a78612cbd
)

vcpkg_from_github(
    OUT_SOURCE_PATH SOURCE_PATH
    REPO google/farmhash
    REF 0d859a811870d10f53a594927d0d0b97573ad06d
    SHA512 7bc14931e488464c1cedbc17551fb90a8cec494d0e0860db9df8efff09000fd8d91e01060dd5c5149b1104ac4ac8bf7eb57e5b156b05ef42636938edad1518f1
    HEAD_REF master
    PATCHES ${WIN_PR_PATCH}
)
file(COPY "${CMAKE_CURRENT_LIST_DIR}/CMakeLists.txt" DESTINATION "${SOURCE_PATH}")

vcpkg_cmake_configure(SOURCE_PATH "${SOURCE_PATH}")
vcpkg_cmake_install()
vcpkg_cmake_config_fixup(CONFIG_PATH share/${PORT})
vcpkg_copy_pdbs()

file(REMOVE_RECURSE "${CURRENT_PACKAGES_DIR}/debug/include"
                    "${CURRENT_PACKAGES_DIR}/debug/share"
)

vcpkg_install_copyright(FILE_LIST "${SOURCE_PATH}/COPYING")
