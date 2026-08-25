vcpkg_download_distfile(
    ARCHIVE
    URLS "https://github.com/p7zip-project/p7zip/archive/refs/tags/v17.05.tar.gz"
    FILENAME "p7zip-v17.05.tar.gz"
    SHA512 97a7cfd15287998eb049c320548477be496c4ddf6b45c833c42adca4ab88719b07a442ae2e71cf2dc3b30a0777a3acab0a1a30f01fd85bacffa3fa9bd22c3f7d
)

vcpkg_extract_source_archive(
    SOURCE_PATH
    ARCHIVE "${ARCHIVE}"
)

set(VCPKG_POLICY_EMPTY_INCLUDE_FOLDER enabled)

vcpkg_cmake_get_vars(cmake_vars_file)
include("${cmake_vars_file}")

configure_file(
    "${SOURCE_PATH}/makefile.linux_any_cpu"
    "${SOURCE_PATH}/makefile.machine"
    COPYONLY
)
vcpkg_replace_string(
    "${SOURCE_PATH}/makefile.machine"
    "CXX=g++"
    "CXX=${VCPKG_DETECTED_CMAKE_CXX_COMPILER}"
)
vcpkg_replace_string(
    "${SOURCE_PATH}/makefile.machine"
    "CC=gcc"
    "CC=${VCPKG_DETECTED_CMAKE_C_COMPILER}"
)

find_program(MAKE_EXECUTABLE NAMES make gmake REQUIRED)
vcpkg_execute_build_process(
    COMMAND "${MAKE_EXECUTABLE}" "-j${VCPKG_CONCURRENCY}" 7z
    NO_PARALLEL_COMMAND "${MAKE_EXECUTABLE}" -j1 7z
    WORKING_DIRECTORY "${SOURCE_PATH}"
    LOGNAME "build-${TARGET_TRIPLET}"
)

set(TOOLS_DIR "${CURRENT_PACKAGES_DIR}/tools/${PORT}")
file(INSTALL
    "${SOURCE_PATH}/bin/7z"
    "${SOURCE_PATH}/bin/7z.so"
    DESTINATION "${TOOLS_DIR}"
    USE_SOURCE_PERMISSIONS
)
if(EXISTS "${SOURCE_PATH}/bin/Codecs")
    file(COPY "${SOURCE_PATH}/bin/Codecs" DESTINATION "${TOOLS_DIR}")
endif()

vcpkg_install_copyright(FILE_LIST "${SOURCE_PATH}/DOC/License.txt")
