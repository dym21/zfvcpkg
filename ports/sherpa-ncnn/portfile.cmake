vcpkg_from_github(
    OUT_SOURCE_PATH SOURCE_PATH
    REPO dym21/sherpa-ncnn
    REF 64384245932f4c8adaf5dc7cc60c40cb5c148dc2
    SHA512 58a93cdb4131b36d0b18cad43b098705c34ee6ceac2910afde2aec4d58aef663abc24fdc6d05b165cd0cff32cff70c220558911cf6c4bf71dc3d0f76338de299
    HEAD_REF master
)

# The nested OpenFST FetchContent logic invokes sed for non-Windows targets.
# When cross-compiling OHOS on Windows, provide the host MSYS implementation.
if(VCPKG_HOST_IS_WINDOWS)
    vcpkg_acquire_msys(MSYS_ROOT PACKAGES sed)
    vcpkg_add_to_path(PREPEND "${MSYS_ROOT}/usr/bin")
endif()

# Keep sherpa-ncnn's nested CMake dependencies in vcpkg's shared download
# cache. Copying them into the top-level source directory makes both the
# direct FetchContent calls and their nested dependencies work offline.
set(SHERPA_NCNN_CACHED_ARCHIVES
    kaldi-native-fbank-1.22.3.tar.gz
    kissfft-febd4caeed32e33ad8b2e0bb5ea77542c40f18ec.zip
    kaldifst-1.7.17.tar.gz
    openfst-sherpa-onnx-2024-06-19.tar.gz
)
foreach(ARCHIVE IN LISTS SHERPA_NCNN_CACHED_ARCHIVES)
    set(CACHED_ARCHIVE "${DOWNLOADS}/${ARCHIVE}")
    if(NOT EXISTS "${CACHED_ARCHIVE}")
        message(FATAL_ERROR "Missing offline sherpa-ncnn dependency: ${CACHED_ARCHIVE}")
    endif()
    file(COPY "${CACHED_ARCHIVE}" DESTINATION "${SOURCE_PATH}")
endforeach()

# Fix kaldi-native-fbank missing <cstdint> include on GCC 15 / LoongArch
vcpkg_replace_string(
    "${SOURCE_PATH}/cmake/kaldi-native-fbank.cmake"
    "    FetchContent_Populate(kaldi_native_fbank)"
    "    FetchContent_Populate(kaldi_native_fbank)\n\n    # GCC 15 no longer transitively includes <cstdint> from <memory>\n    file(READ \"\${kaldi_native_fbank_SOURCE_DIR}/kaldi-native-fbank/csrc/rfft.h\" _rfft_h)\n    string(REPLACE \"#include <memory>\" \"#include <memory>\\n#include <cstdint>\" _rfft_h \"\${_rfft_h}\")\n    file(WRITE \"\${kaldi_native_fbank_SOURCE_DIR}/kaldi-native-fbank/csrc/rfft.h\" \"\${_rfft_h}\")"
)

# Fix missing <cstdint> includes on GCC 15 (transitive includes no longer available)
file(GLOB SHERPA_NCNN_HEADERS "${SOURCE_PATH}/sherpa-ncnn/csrc/*.h")
foreach(HEADER IN LISTS SHERPA_NCNN_HEADERS)
    file(READ "${HEADER}" _header_content)
    if(NOT _header_content MATCHES "#include <cstdint>")
        string(FIND "${_header_content}" "#include" _first_include)
        if(NOT _first_include EQUAL -1)
            string(SUBSTRING "${_header_content}" 0 ${_first_include} _header_prefix)
            string(SUBSTRING "${_header_content}" ${_first_include} -1 _header_suffix)
            string(CONCAT _header_content
                "${_header_prefix}" "#include <cstdint>\n" "${_header_suffix}")
            file(WRITE "${HEADER}" "${_header_content}")
        endif()
    endif()
endforeach()

# The system ncnn package used by the OHOS build does not expose sherpa's
# private NativeResourceManager/rawfile API. Disable only those optional
# instantiations for OHOS; Windows and Linux retain the upstream sources.
if(VCPKG_TARGET_IS_OHOS)
    foreach(_resource_source IN ITEMS
        offline-recognizer-impl.cc
        offline-recognizer.cc
        offline-sense-voice-model.cc
    )
        vcpkg_replace_string(
            "${SOURCE_PATH}/sherpa-ncnn/csrc/${_resource_source}"
            "#if __OHOS__" "#if 0"
        )
    endforeach()
endif()

# Use the ncnn package declared by this port instead of building sherpa-ncnn's
# private FetchContent copy.  Mixing the private CPU-only ncnn headers with a
# consumer linked to ncnn[vulkan] changes ncnn::Option (and therefore
# sherpa_ncnn::ModelConfig) layout across the static-library boundary.
vcpkg_replace_string(
    "${SOURCE_PATH}/CMakeLists.txt"
    "include(ncnn)"
    "find_package(ncnn CONFIG REQUIRED)"
)

string(COMPARE EQUAL "${VCPKG_LIBRARY_LINKAGE}" "dynamic" BUILD_SHARED)

vcpkg_configure_cmake(
    SOURCE_PATH ${SOURCE_PATH}
    OPTIONS
		-DBUILD_SHARED_LIBS=${BUILD_SHARED}
		-DNCNN_OPENMP=OFF
		-DSHERPA_NCNN_ENABLE_BINARY=OFF
		-DSHERPA_NCNN_ENABLE_PORTAUDIO=OFF
		-DSHERPA_NCNN_ENABLE_GENERATE_INT8_SCALE_TABLE=OFF
)

vcpkg_install_cmake()

FILE(GLOB SHERPA_C_HEADS "${SOURCE_PATH}/sherpa-ncnn/csrc/*.h")
FILE(INSTALL ${SHERPA_C_HEADS} DESTINATION "${CURRENT_PACKAGES_DIR}/include/${PORT}/csrc")

file(REMOVE_RECURSE "${CURRENT_PACKAGES_DIR}/bin")
file(REMOVE_RECURSE "${CURRENT_PACKAGES_DIR}/debug/bin")
file(REMOVE_RECURSE "${CURRENT_PACKAGES_DIR}/debug/include")
vcpkg_copy_pdbs()
