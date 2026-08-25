vcpkg_download_distfile(
    ARCHIVE
    URLS "https://download.savannah.gnu.org/releases/lzip/lzip-${VERSION}.tar.gz"
    FILENAME "lzip-${VERSION}.tar.gz"
    SHA512 df99d7c9ce932486aec64fe9f9c378a9f98300deac6f6065c9543006cf35daeb52b419316d4672c182acbd0c8105388267947dfc9267965697d521259d59a0ad
)

vcpkg_extract_source_archive(
    SOURCE_PATH
    ARCHIVE "${ARCHIVE}"
)

set(VCPKG_POLICY_EMPTY_INCLUDE_FOLDER enabled)
vcpkg_cmake_get_vars(cmake_vars_file)
include("${cmake_vars_file}")

set(tools_dir "${CURRENT_PACKAGES_DIR}/tools/${PORT}")
file(MAKE_DIRECTORY "${tools_dir}")

vcpkg_execute_build_process(
    COMMAND
        "${SOURCE_PATH}/configure"
        "--installdir=${tools_dir}"
        "CXX=${VCPKG_DETECTED_CMAKE_CXX_COMPILER}"
        "CXXFLAGS=${VCPKG_DETECTED_CMAKE_CXX_FLAGS} -O2"
    WORKING_DIRECTORY "${SOURCE_PATH}"
    LOGNAME "build-${TARGET_TRIPLET}"
)

vcpkg_install_copyright(FILE_LIST "${SOURCE_PATH}/COPYING")
