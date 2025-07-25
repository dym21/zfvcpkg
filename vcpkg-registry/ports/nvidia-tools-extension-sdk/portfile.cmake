vcpkg_check_linkage(ONLY_STATIC_LIBRARY)

vcpkg_from_github(
    OUT_SOURCE_PATH SOURCE_PATH
    REPO NVIDIA/NVTX
    REF v3.1.0
    SHA512 132542f7d8adb5df0fcb34dccb1d354075be382efdf1f685f30cb9aa6c53f445b0837cb9c7db06376fe9c06894ad8988b6275305528efe9cdc35f9ad16a10fd0
    HEAD_REF release-v3
)

file(INSTALL "${SOURCE_PATH}/c/include/nvtx3" DESTINATION "${CURRENT_PACKAGES_DIR}/include")

file(REMOVE_RECURSE
    "${CURRENT_PACKAGES_DIR}/debug"
    "${CURRENT_PACKAGES_DIR}/lib"
)
file(INSTALL "${SOURCE_PATH}/c/README.md" DESTINATION "${CURRENT_PACKAGES_DIR}/share/${PORT}")

vcpkg_install_copyright(FILE_LIST "${SOURCE_PATH}/LICENSE.txt")
