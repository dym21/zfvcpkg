vcpkg_from_github(
    OUT_SOURCE_PATH SOURCE_PATH
    REPO k2-fsa/sherpa-ncnn
    REF v${VERSION} 
    SHA512 96d0bc707480124f02762275d44d6314118b500f56c9968f3abe2bc037498f98991ddfd3f0ccb432e627af1295bdeb2e5f0b7cab24ff3a6c8892c10399734ac3
    HEAD_REF master
	PATCHES
		0001-fix-3party-locale.patch
		0001-fix-gcc14-mingw-stdint.patch
)

# Fix kaldi-native-fbank missing <cstdint> include on GCC 15 / LoongArch
vcpkg_replace_string(
    "${SOURCE_PATH}/cmake/kaldi-native-fbank.cmake"
    "    FetchContent_Populate(kaldi_native_fbank)"
    "    FetchContent_Populate(kaldi_native_fbank)\n\n    # GCC 15 no longer transitively includes <cstdint> from <memory>\n    file(READ \"\${kaldi_native_fbank_SOURCE_DIR}/kaldi-native-fbank/csrc/rfft.h\" _rfft_h)\n    string(REPLACE \"#include <memory>\" \"#include <memory>\\n#include <cstdint>\" _rfft_h \"\${_rfft_h}\")\n    file(WRITE \"\${kaldi_native_fbank_SOURCE_DIR}/kaldi-native-fbank/csrc/rfft.h\" \"\${_rfft_h}\")"
)

string(COMPARE EQUAL "${VCPKG_LIBRARY_LINKAGE}" "dynamic" BUILD_SHARED)

vcpkg_configure_cmake(
    SOURCE_PATH ${SOURCE_PATH}
    OPTIONS
		-DBUILD_SHARED_LIBS=${BUILD_SHARED}
		-DNCNN_OPENMP=OFF
		-DSHERPA_NCNN_ENABLE_BINARY=OFF
		-DSHERPA_NCNN_ENABLE_PORTAUDIO=OFF
)

vcpkg_install_cmake()

FILE(GLOB SHERPA_C_HEADS "${SOURCE_PATH}/sherpa-ncnn/csrc/*.h")
FILE(INSTALL ${SHERPA_C_HEADS} DESTINATION "${CURRENT_PACKAGES_DIR}/include/${PORT}/csrc")

file(REMOVE_RECURSE "${CURRENT_PACKAGES_DIR}/bin")
file(REMOVE_RECURSE "${CURRENT_PACKAGES_DIR}/debug/bin")
file(REMOVE_RECURSE "${CURRENT_PACKAGES_DIR}/debug/include")
vcpkg_copy_pdbs()
