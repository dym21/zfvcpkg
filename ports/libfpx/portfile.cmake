vcpkg_from_github(
    OUT_SOURCE_PATH SOURCE_PATH
    REPO ImageMagick/libfpx
    REF master
    SHA512
        568a8328208da64ee425217b3c63da662763c9dd8047e7b0af97b69d8735b2ae850be536daf5343af0d8d26f554e2567c0113880c3a0a454e91cba75c14b9061
	PATCHES	
		0001-fix_msvc_error.patch
)


set(VCPKG_POLICY_SKIP_COPYRIGHT_CHECK enabled)



file(COPY "${CURRENT_PORT_DIR}/configure" DESTINATION "${SOURCE_PATH}")
file(COPY "${CURRENT_PORT_DIR}/configure.ac" DESTINATION "${SOURCE_PATH}")

vcpkg_configure_make(
    SOURCE_PATH ${SOURCE_PATH}
    AUTOCONFIG
)

file(COPY "${SOURCE_PATH}/fpxlib.h" DESTINATION "${CURRENT_BUILDTREES_DIR}/${TARGET_TRIPLET}-rel")
file(COPY "${SOURCE_PATH}/fpxlib.h" DESTINATION "${CURRENT_BUILDTREES_DIR}/${TARGET_TRIPLET}-dbg")

vcpkg_build_make()

vcpkg_install_make()

file(COPY "${CURRENT_PORT_DIR}/fpxlib.h" DESTINATION "${CURRENT_PACKAGES_DIR}/include")