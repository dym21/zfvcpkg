cmake_minimum_required(VERSION 3.20)
project(snowball LANGUAGES C)

if(NOT IS_DIRECTORY "${SNOWBALL_SOURCE_DIR}")
    message(FATAL_ERROR "SNOWBALL_SOURCE_DIR must name an extracted Snowball source tree")
endif()

file(GLOB snowball_algorithm_sources CONFIGURE_DEPENDS
    "${SNOWBALL_SOURCE_DIR}/src_c/stem_UTF_8_*.c")
if(NOT snowball_algorithm_sources)
    message(FATAL_ERROR "Snowball UTF-8 sources were not generated")
endif()

add_library(snowball
    "${SNOWBALL_SOURCE_DIR}/runtime/api.c"
    "${SNOWBALL_SOURCE_DIR}/runtime/utilities.c"
    "${SNOWBALL_SOURCE_DIR}/libstemmer/libstemmer_utf8.c"
    ${snowball_algorithm_sources}
)
add_library(snowball::snowball ALIAS snowball)
target_compile_features(snowball PRIVATE c_std_99)
target_include_directories(snowball
    PUBLIC
        $<BUILD_INTERFACE:${SNOWBALL_SOURCE_DIR}/include>
        $<INSTALL_INTERFACE:include>
    PRIVATE
        "${SNOWBALL_SOURCE_DIR}"
        "${SNOWBALL_SOURCE_DIR}/libstemmer"
        "${SNOWBALL_SOURCE_DIR}/src_c"
)

include(GNUInstallDirs)
install(TARGETS snowball EXPORT snowball-targets)
install(FILES "${SNOWBALL_SOURCE_DIR}/include/libstemmer.h"
        DESTINATION "${CMAKE_INSTALL_INCLUDEDIR}")
install(EXPORT snowball-targets
        FILE snowball-config.cmake
        NAMESPACE snowball::
        DESTINATION "${CMAKE_INSTALL_LIBDIR}/cmake/snowball")
