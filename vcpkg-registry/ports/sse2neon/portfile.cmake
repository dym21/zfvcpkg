vcpkg_from_github(
    OUT_SOURCE_PATH SOURCE_PATH
    REPO DLTcollab/sse2neon
    REF "v${VERSION}"
    SHA512 3266c3ddf82770c89508ffd52998247e2b2d97029e1c68314e60a8c58563f91240528a1ebaccd5f756f5a10b98094e9e4e88db2e000d12d04ac910db911df730
    HEAD_REF master
)

file(INSTALL "${SOURCE_PATH}/sse2neon.h"
    DESTINATION "${CURRENT_PACKAGES_DIR}/include"
)

file(REMOVE_RECURSE
    "${CURRENT_PACKAGES_DIR}/debug"
)

file(INSTALL "${SOURCE_PATH}/README.md"
    DESTINATION "${CURRENT_PACKAGES_DIR}/share/${PORT}"
)
vcpkg_install_copyright(FILE_LIST "${SOURCE_PATH}/LICENSE")
