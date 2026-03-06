vcpkg_download_distfile(ARCHIVE
	URLS "https://github.com/libyal/libbfio/releases/download/20240414/libbfio-alpha-20240414.tar.gz"
	FILENAME "libbfio-alpha-20240414.tar.gz"
	SHA512 56c7caa77f0f8b81ea54bdc5579c2fe4fe1cb1660701f0c5bf6d95817cd7dd3992f3451fe2fbd49b7aa29a59f6023af053f612c749b0519dd4b7e61d2d7059bc
)

vcpkg_extract_source_archive_ex(
	OUT_SOURCE_PATH SOURCE_PATH
	ARCHIVE ${ARCHIVE}
)

 if (VCPKG_TARGET_IS_WINDOWS)

	set(MSBUILD_OPTIONS "")
	set(MSBUILD_OPTIONS_DEBUG "")
	set(MSBUILD_OPTIONS_RELEASE "")

	if(VCPKG_CRT_LINKAGE STREQUAL "static")
		list(APPEND MSBUILD_OPTIONS_RELEASE "/p:RuntimeLibrary=MultiThreaded")
		list(APPEND MSBUILD_OPTIONS_DEBUG "/p:RuntimeLibrary=MultiThreadedDebug")
	endif()
     vcpkg_execute_required_process(
         COMMAND devenv.exe libbfio.sln /Upgrade
         WORKING_DIRECTORY ${SOURCE_PATH}/msvscpp
         LOGNAME upgrade-libbfio-${TARGET_TRIPLET}
     )

     vcpkg_install_msbuild(
         SOURCE_PATH "${SOURCE_PATH}"
         PROJECT_SUBPATH "msvscpp/libbfio.sln"
		 RELEASE_CONFIGURATION "Release"
		 DEBUG_CONFIGURATION "vsdebug"
		 OPTIONS ${MSBUILD_OPTIONS}
		 OPTIONS_RELEASE ${MSBUILD_OPTIONS_RELEASE}
		 OPTIONS_DEBUG ${MSBUILD_OPTIONS_DEBUG}
     )

     file(INSTALL
         ${SOURCE_PATH}/include/
         DESTINATION ${CURRENT_PACKAGES_DIR}/include
         FILES_MATCHING PATTERN "*.h"
     )

 else()
	 vcpkg_configure_make(
		 SOURCE_PATH "${SOURCE_PATH}"
		 COPY_SOURCE
	 )
	 vcpkg_install_make()
	 vcpkg_fixup_pkgconfig()
 endif()

file(REMOVE_RECURSE "${CURRENT_PACKAGES_DIR}/debug/share")
file(INSTALL "${SOURCE_PATH}/COPYING.LESSER" DESTINATION "${CURRENT_PACKAGES_DIR}/share/${PORT}" RENAME copyright)
