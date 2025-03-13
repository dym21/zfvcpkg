vcpkg_check_linkage(ONLY_STATIC_LIBRARY)

vcpkg_from_github(
    OUT_SOURCE_PATH SOURCE_PATH
    REPO ArtifexSoftware/mupdf
    REF "${VERSION}"
    SHA512 6d053b140a34061fcf5eb30f23f87e51dd8e80be29a3e505c42312c11198491102a79c2ca290f13971d25b9a286354ad44bd825593c076373c18f58bbc7b950e
    HEAD_REF master
    PATCHES
        dont-generate-extract-3rd-party-things.patch
        fix-NAN-on-Win11.patch # https://github.com/ArtifexSoftware/mupdf/pull/54
		0001-fix-mingw-u64-error.patch
)

file(COPY "${CMAKE_CURRENT_LIST_DIR}/CMakeLists.txt" DESTINATION "${SOURCE_PATH}")

vcpkg_check_features(
    OUT_FEATURE_OPTIONS FEATURE_OPTIONS
    FEATURES
        ocr ENABLE_OCR
)

vcpkg_cmake_configure(
    SOURCE_PATH "${SOURCE_PATH}"
    DISABLE_PARALLEL_CONFIGURE
    OPTIONS
        -DBUILD_EXAMPLES=OFF
        ${FEATURE_OPTIONS}
)

vcpkg_cmake_install()

if(VCPKG_TARGET_ARCHITECTURE STREQUAL "x86" AND NOT VCPKG_TARGET_IS_MINGW)
	vcpkg_install_msbuild(
		SOURCE_PATH "${SOURCE_PATH}"
		PROJECT_SUBPATH "platform/win32/mupdf.sln"
		TARGET libresources
		RELEASE_CONFIGURATION "Release"
		DEBUG_CONFIGURATION "Debug"
		PLATFORM Win32
	)
endif()

file(COPY "${SOURCE_PATH}/include/mupdf" DESTINATION "${CURRENT_PACKAGES_DIR}/include")

vcpkg_copy_pdbs()

vcpkg_install_copyright(FILE_LIST "${SOURCE_PATH}/COPYING")
