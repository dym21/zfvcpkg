vcpkg_from_git(
    OUT_SOURCE_PATH SOURCE_PATH
    URL https://github.com/caolanm/libwmf.git
    REF 9e4737f2293c0d127bda92e5b01896df10571424
    FETCH_REF v0.2.13
    HEAD_REF master
)

# Configure based on library linkage
if(VCPKG_LIBRARY_LINKAGE STREQUAL "static")
    set(SHARED_STATIC --disable-shared --enable-static)
else()
    set(SHARED_STATIC --enable-shared --disable-static)
endif()

# Set up environment variables for pkg-config to find dependencies
set(ENV{PKG_CONFIG_PATH} "${CURRENT_INSTALLED_DIR}/lib/pkgconfig${VCPKG_HOST_PATH_SEPARATOR}${CURRENT_INSTALLED_DIR}/debug/lib/pkgconfig")

# Create freetype2 directory for libwmf compatibility
if(NOT EXISTS "${CURRENT_INSTALLED_DIR}/include/freetype2")
    if(VCPKG_TARGET_IS_WINDOWS)
        # On Windows, copy the freetype directory instead of linking
        file(COPY "${CURRENT_INSTALLED_DIR}/include/freetype/" DESTINATION "${CURRENT_INSTALLED_DIR}/include/freetype2/")
    else()
        file(CREATE_LINK "${CURRENT_INSTALLED_DIR}/include/freetype" "${CURRENT_INSTALLED_DIR}/include/freetype2" SYMBOLIC)
    endif()
endif()

# # Set up environment variables for dependencies
# if(VCPKG_TARGET_IS_WINDOWS)
#     # Windows-specific library names and paths
#     set(ENV{FREETYPE_CFLAGS} "-I${CURRENT_INSTALLED_DIR}/include -I${CURRENT_INSTALLED_DIR}/include/freetype2")
#     set(ENV{FREETYPE_LIBS} "-L${CURRENT_INSTALLED_DIR}/lib -lfreetype")
#     set(ENV{PNG_CFLAGS} "-I${CURRENT_INSTALLED_DIR}/include")
#     set(ENV{PNG_LIBS} "-L${CURRENT_INSTALLED_DIR}/lib -llibpng16")
#     set(ENV{ZLIB_CFLAGS} "-I${CURRENT_INSTALLED_DIR}/include")
#     set(ENV{ZLIB_LIBS} "-L${CURRENT_INSTALLED_DIR}/lib -lzlib")
#     # Generic autotools flags to aid detection
#     set(ENV{CPPFLAGS} "-I${CURRENT_INSTALLED_DIR}/include -I${CURRENT_INSTALLED_DIR}/include/freetype2")
#     set(ENV{LDFLAGS} "-L${CURRENT_INSTALLED_DIR}/lib")
#     set(ENV{LIBS} "-lzlib -llibpng16 -lfreetype")
# else()
#     # Unix-style flags
#     set(ENV{FREETYPE_CFLAGS} "-I${CURRENT_INSTALLED_DIR}/include -I${CURRENT_INSTALLED_DIR}/include/freetype2")
#     set(ENV{FREETYPE_LIBS} "-L${CURRENT_INSTALLED_DIR}/lib -lfreetype")
#     set(ENV{PNG_CFLAGS} "-I${CURRENT_INSTALLED_DIR}/include")
#     set(ENV{PNG_LIBS} "-L${CURRENT_INSTALLED_DIR}/lib -lpng16")
#     set(ENV{ZLIB_CFLAGS} "-I${CURRENT_INSTALLED_DIR}/include")
#     set(ENV{ZLIB_LIBS} "-L${CURRENT_INSTALLED_DIR}/lib -lzlib")
#     # Generic autotools flags to aid detection
#     set(ENV{CPPFLAGS} "-I${CURRENT_INSTALLED_DIR}/include -I${CURRENT_INSTALLED_DIR}/include/freetype2")
#     set(ENV{LDFLAGS} "-L${CURRENT_INSTALLED_DIR}/lib")
#     set(ENV{LIBS} "-lzlib -lpng16 -lfreetype")
# endif()

# libwmf uses autotools for configuration
vcpkg_configure_make(
    SOURCE_PATH "${SOURCE_PATH}"
    AUTOCONFIG
    OPTIONS
        ${SHARED_STATIC}
        --without-x
        --enable-heavy
    CONFIGURE_ENVIRONMENT_VARIABLES
        FREETYPE_CFLAGS FREETYPE_LIBS
        PNG_CFLAGS PNG_LIBS
        ZLIB_CFLAGS ZLIB_LIBS
        CPPFLAGS LDFLAGS LIBS
)

vcpkg_install_make()

# Fix absolute paths in libwmf-config scripts
if(EXISTS "${CURRENT_PACKAGES_DIR}/tools/${PORT}/bin/libwmf-config")
    vcpkg_replace_string("${CURRENT_PACKAGES_DIR}/tools/${PORT}/bin/libwmf-config" "${CURRENT_INSTALLED_DIR}" [[$(cd "$(dirname "$0")/../../.."; pwd -P)]])
endif()
if(EXISTS "${CURRENT_PACKAGES_DIR}/tools/${PORT}/debug/bin/libwmf-config")
    vcpkg_replace_string("${CURRENT_PACKAGES_DIR}/tools/${PORT}/debug/bin/libwmf-config" "${CURRENT_INSTALLED_DIR}" [[$(cd "$(dirname "$0")/../../../.."; pwd -P)]])
endif()

# Remove debug includes and unnecessary files
file(REMOVE_RECURSE "${CURRENT_PACKAGES_DIR}/debug/include")
file(REMOVE_RECURSE "${CURRENT_PACKAGES_DIR}/debug/share")

# Install usage file
file(INSTALL "${CMAKE_CURRENT_LIST_DIR}/usage" DESTINATION "${CURRENT_PACKAGES_DIR}/share/${PORT}")

# Handle copyright
vcpkg_install_copyright(FILE_LIST "${SOURCE_PATH}/COPYING")

# Fix pkgconfig files
vcpkg_fixup_pkgconfig()
