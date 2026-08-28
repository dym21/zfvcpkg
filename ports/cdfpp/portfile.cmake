vcpkg_from_github(
    OUT_SOURCE_PATH SOURCE_PATH
    REPO SciQLop/CDFpp
    REF "v${VERSION}"
    SHA512 07ee1461e9f443c3fa2f353679ece93d0f1e60c6f19e0de564251e9c31037564f60439d57e2d2c8e3d02d675e1a43eb38a7823512b998f97f1d317ed48d464ca
    HEAD_REF main
)

vcpkg_replace_string(
    "${SOURCE_PATH}/include/cdfpp/cdf-io/common.hpp"
    "return { (magic.first >> 16) & 0xf, (magic.first >> 12) & 0xf };"
    "return { static_cast<uint8_t>((magic.first >> 16) & 0xf), static_cast<uint8_t>((magic.first >> 12) & 0xf) };"
)
vcpkg_replace_string(
    "${SOURCE_PATH}/include/cdfpp/cdf-io/loading/records-loading.hpp"
    "#include <functional>"
    "#include <functional>\n#include <limits>"
)
vcpkg_replace_string(
    "${SOURCE_PATH}/include/cdfpp/cdf-io/loading/records-loading.hpp"
    "parsing_context, [](const adr_t& adr) { return adr.ADRnext; } }"
    "parsing_context, [](const adr_t& adr) -> std::size_t {\n            return adr.ADRnext <= std::numeric_limits<std::size_t>::max()\n                ? static_cast<std::size_t>(adr.ADRnext) : 0;\n        } }"
)
vcpkg_replace_string(
    "${SOURCE_PATH}/include/cdfpp/cdf-io/loading/records-loading.hpp"
    "parsing_context, [](const vdr_t& vdr) { return vdr.VDRnext; } }"
    "parsing_context, [](const vdr_t& vdr) -> std::size_t {\n                return vdr.VDRnext <= std::numeric_limits<std::size_t>::max()\n                    ? static_cast<std::size_t>(vdr.VDRnext) : 0;\n            } }"
)
vcpkg_replace_string(
    "${SOURCE_PATH}/include/cdfpp/cdf-io/loading/records-loading.hpp"
    "[](const auto& adr) -> decltype(adr.ADRnext) { return 0; }"
    "[](const auto&) -> std::size_t { return 0; }"
)
vcpkg_replace_string(
    "${SOURCE_PATH}/include/cdfpp/cdf-io/loading/records-loading.hpp"
    "[](const auto& vdr) -> decltype(vdr.VDRnext) { return 0; }"
    "[](const auto&) -> std::size_t { return 0; }"
)
vcpkg_replace_string(
    "${SOURCE_PATH}/include/cdfpp/cdf-io/loading/records-loading.hpp"
    "[](const aedr_t& aedr) { return aedr.AEDRnext; }"
    "[](const aedr_t& aedr) -> std::size_t {\n            return aedr.AEDRnext <= std::numeric_limits<std::size_t>::max()\n                ? static_cast<std::size_t>(aedr.AEDRnext) : 0;\n        }"
)
vcpkg_replace_string(
    "${SOURCE_PATH}/include/cdfpp/cdf-io/loading/records-loading.hpp"
    "[](const auto& aedr) -> decltype(aedr.AEDRnext) { return 0; }"
    "[](const auto&) -> std::size_t { return 0; }"
)
vcpkg_replace_string(
    "${SOURCE_PATH}/include/cdfpp/cdf-io/loading/records-loading.hpp"
    "[](const vxr_t& vxr) { return vxr.VXRnext; }"
    "[](const vxr_t& vxr) -> std::size_t {\n            return vxr.VXRnext <= std::numeric_limits<std::size_t>::max()\n                ? static_cast<std::size_t>(vxr.VXRnext) : 0;\n        }"
)
vcpkg_replace_string(
    "${SOURCE_PATH}/include/cdfpp/cdf-io/loading/records-loading.hpp"
    "[]([[maybe_unused]] const auto& vxr) { return 0; }"
    "[](const auto&) -> std::size_t { return 0; }"
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
