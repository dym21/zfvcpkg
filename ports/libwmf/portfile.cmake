vcpkg_from_git(
    OUT_SOURCE_PATH SOURCE_PATH
    URL https://github.com/caolanm/libwmf.git
    REF 9e4737f2293c0d127bda92e5b01896df10571424
    FETCH_REF v0.2.13
    HEAD_REF master
    PATCHES
        0001-vcpkg-lib-names.patch
)

# MSVC lacks unistd.h; avoid it on Windows.
vcpkg_replace_string("${SOURCE_PATH}/src/extra/gd/gdft.c" "#ifndef MSWIN32" "#ifndef _WIN32")
vcpkg_replace_string("${SOURCE_PATH}/src/font.c" "#include <unistd.h>" "#ifndef _WIN32\n#include <unistd.h>\n#endif")
vcpkg_replace_string("${SOURCE_PATH}/src/ipa/ipa.c" "#include <unistd.h>" "#ifndef _WIN32\n#include <unistd.h>\n#endif")
vcpkg_replace_string("${SOURCE_PATH}/src/player.c" "#include <unistd.h>" "#ifndef _WIN32\n#include <unistd.h>\n#endif")

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

# Fix fontmap paths - fonts are installed to share/libwmf/libwmf/fonts but fontmap references share/libwmf/fonts
if(EXISTS "${CURRENT_PACKAGES_DIR}/share/${PORT}/libwmf/fonts/fontmap")
    # Create symlink to fix path reference
    file(CREATE_LINK "${CURRENT_PACKAGES_DIR}/share/${PORT}/libwmf/fonts" "${CURRENT_PACKAGES_DIR}/share/${PORT}/fonts" SYMBOLIC)
endif()

# Install usage file
file(INSTALL "${CMAKE_CURRENT_LIST_DIR}/usage" DESTINATION "${CURRENT_PACKAGES_DIR}/share/${PORT}")

# Handle copyright
vcpkg_install_copyright(FILE_LIST "${SOURCE_PATH}/COPYING")

# Fix pkgconfig files
vcpkg_fixup_pkgconfig()
