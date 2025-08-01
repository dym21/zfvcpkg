vcpkg_from_github(
    OUT_SOURCE_PATH SOURCE_PATH
    REPO k2-fsa/sherpa-onnx
    REF v${VERSION} 
    SHA512 f1c1c344c9677223801a1e797625c9043928df990b6ab57e1d94e34dd5d0170af6b53a189cf9f486438a4963bfdd6d6b9a25d03d549b279c427c6ca2bc8994dc
    HEAD_REF master
	PATCHES
		0001-gix-locale-package.patch
		0002-gix-onnxruntime-include-error.patch
		0003-gix-gcc13-log10-error.patch
)

string(COMPARE EQUAL "${VCPKG_LIBRARY_LINKAGE}" "dynamic" BUILD_SHARED)


vcpkg_configure_cmake(
    SOURCE_PATH ${SOURCE_PATH}
    OPTIONS
		-DBUILD_SHARED_LIBS=${BUILD_SHARED}
		-DSHERPA_ONNX_ENABLE_WEBSOCKET=OFF
		-DSHERPA_ONNX_ENABLE_BINARY=OFF
)
vcpkg_install_cmake()
vcpkg_copy_pdbs()
vcpkg_host_path_list(APPEND ENV{PKG_CONFIG_PATH} "${CURRENT_PACKAGES_DIR}")
vcpkg_fixup_pkgconfig()
file(REMOVE_RECURSE "${CURRENT_PACKAGES_DIR}/debug/include")
file(REMOVE_RECURSE "${CURRENT_PACKAGES_DIR}/debug/share")