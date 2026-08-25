vcpkg_from_github(
    OUT_SOURCE_PATH SOURCE_PATH
    REPO google/compact_enc_det
    REF d127078cedef9c6642cbe592dacdd2292b50bb19
    SHA512 d37d551ca02d6c9b1f7aa6b285a62835a7be09fe86b9cd82ba50023609194dfc149d9330c6f4b1119f3d2b3bed4e23891fc96c753270f18a52d2cb3044f524f8
    HEAD_REF master
    PATCHES
        cmake-install.patch
)

vcpkg_cmake_configure(
    SOURCE_PATH "${SOURCE_PATH}"
    OPTIONS
        -DBUILD_TESTING=OFF
)

vcpkg_cmake_install()

vcpkg_cmake_config_fixup(
    PACKAGE_NAME compact-encoding-detection
    CONFIG_PATH lib/cmake/compact-encoding-detection
)

file(REMOVE_RECURSE "${CURRENT_PACKAGES_DIR}/debug/include")

vcpkg_copy_pdbs()
vcpkg_install_copyright(FILE_LIST "${SOURCE_PATH}/LICENSE")
