vcpkg_from_github(
    OUT_SOURCE_PATH SOURCE_PATH
    REPO SciQLop/CDFpp
    REF "v${VERSION}"
    SHA512 07ee1461e9f443c3fa2f353679ece93d0f1e60c6f19e0de564251e9c31037564f60439d57e2d2c8e3d02d675e1a43eb38a7823512b998f97f1d317ed48d464ca
    HEAD_REF main
)

file(INSTALL "${SOURCE_PATH}/include/cdfpp"
    DESTINATION "${CURRENT_PACKAGES_DIR}/include")
configure_file("${CURRENT_PORT_DIR}/cdfpp_config.h"
    "${CURRENT_PACKAGES_DIR}/include/cdfpp/cdfpp_config.h" COPYONLY)
configure_file("${CURRENT_PORT_DIR}/source_location"
    "${CURRENT_PACKAGES_DIR}/include/cdfpp/source_location" COPYONLY)
configure_file("${CURRENT_PORT_DIR}/cdfpp-config.cmake"
    "${CURRENT_PACKAGES_DIR}/share/cdfpp/cdfpp-config.cmake" COPYONLY)

vcpkg_install_copyright(FILE_LIST "${SOURCE_PATH}/COPYING")
