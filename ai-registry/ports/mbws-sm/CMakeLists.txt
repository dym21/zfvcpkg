cmake_minimum_required(VERSION 3.20)

project(mbws_sm VERSION 1.0.0 LANGUAGES C)

include(CMakePackageConfigHelpers)
include(GNUInstallDirs)

set(CMAKE_POSITION_INDEPENDENT_CODE ON)

file(GLOB TOMMATH_SOURCES CONFIGURE_DEPENDS
    "${CMAKE_CURRENT_SOURCE_DIR}/libtommath/*.c")
add_library(tommath STATIC ${TOMMATH_SOURCES})
target_include_directories(tommath
    PUBLIC
        "$<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}/libtommath>"
        "$<INSTALL_INTERFACE:${CMAKE_INSTALL_INCLUDEDIR}/mbws-sm/tommath>"
)

file(GLOB_RECURSE TOMCRYPT_SOURCES CONFIGURE_DEPENDS
    "${CMAKE_CURRENT_SOURCE_DIR}/libtomcrypt/src/*.c")
list(FILTER TOMCRYPT_SOURCES EXCLUDE REGEX
    "/(aes_tab|twofish_tab|sha224|sha384|whirltab|sober128tab)\\.c$")
add_library(tomcrypt STATIC ${TOMCRYPT_SOURCES})
target_compile_definitions(tomcrypt PRIVATE LTC_SOURCE)
target_include_directories(tomcrypt
    PUBLIC
        "$<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}/libtomcrypt/src/headers>"
        "$<INSTALL_INTERFACE:${CMAKE_INSTALL_INCLUDEDIR}/mbws-sm/tomcrypt>"
)
target_link_libraries(tomcrypt PUBLIC tommath)

add_library(sm3 STATIC sm3/sm3.c)
target_include_directories(sm3
    PUBLIC
        "$<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}/sm3>"
        "$<INSTALL_INTERFACE:${CMAKE_INSTALL_INCLUDEDIR}/mbws-sm/sm3>"
)

add_library(kdf STATIC KDFLib/KDF.c)
target_include_directories(kdf
    PUBLIC
        "$<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}/KDFLib>"
        "$<INSTALL_INTERFACE:${CMAKE_INSTALL_INCLUDEDIR}/mbws-sm/kdf>"
)
target_link_libraries(kdf PUBLIC sm3 tomcrypt tommath)

add_library(sm2 STATIC sm2/sm2.c sm2/Zf_log.c)
target_include_directories(sm2
    PUBLIC
        "$<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}/sm2>"
        "$<INSTALL_INTERFACE:${CMAKE_INSTALL_INCLUDEDIR}/mbws-sm/sm2>"
    PRIVATE
        "${CMAKE_CURRENT_SOURCE_DIR}/sm2/include"
)
target_link_libraries(sm2 PUBLIC kdf sm3 tomcrypt tommath)

install(TARGETS tommath tomcrypt sm3 kdf sm2
    EXPORT mbws-sm-targets
    ARCHIVE DESTINATION "${CMAKE_INSTALL_LIBDIR}"
)
install(FILES
    libtommath/tommath.h
    libtommath/tommath_class.h
    libtommath/tommath_superclass.h
    DESTINATION "${CMAKE_INSTALL_INCLUDEDIR}/mbws-sm/tommath"
)
install(DIRECTORY libtomcrypt/src/headers/
    DESTINATION "${CMAKE_INSTALL_INCLUDEDIR}/mbws-sm/tomcrypt"
    FILES_MATCHING PATTERN "*.h"
)
install(FILES sm3/sm3.h
    DESTINATION "${CMAKE_INSTALL_INCLUDEDIR}/mbws-sm/sm3"
)
install(FILES KDFLib/KDF.h KDFLib/SM3.h
    DESTINATION "${CMAKE_INSTALL_INCLUDEDIR}/mbws-sm/kdf"
)
install(FILES sm2/SM2.h sm2/SM3.h sm2/KDF.h sm2/Zf_log.h
    DESTINATION "${CMAKE_INSTALL_INCLUDEDIR}/mbws-sm/sm2"
)

configure_package_config_file(
    "${CMAKE_CURRENT_SOURCE_DIR}/mbws-sm-config.cmake.in"
    "${CMAKE_CURRENT_BINARY_DIR}/mbws-sm-config.cmake"
    INSTALL_DESTINATION "${CMAKE_INSTALL_LIBDIR}/cmake/mbws-sm"
)
write_basic_package_version_file(
    "${CMAKE_CURRENT_BINARY_DIR}/mbws-sm-config-version.cmake"
    VERSION "${PROJECT_VERSION}"
    COMPATIBILITY SameMajorVersion
)
install(EXPORT mbws-sm-targets
    FILE mbws-sm-targets.cmake
    NAMESPACE mbws-sm::
    DESTINATION "${CMAKE_INSTALL_LIBDIR}/cmake/mbws-sm"
)
install(FILES
    "${CMAKE_CURRENT_BINARY_DIR}/mbws-sm-config.cmake"
    "${CMAKE_CURRENT_BINARY_DIR}/mbws-sm-config-version.cmake"
    DESTINATION "${CMAKE_INSTALL_LIBDIR}/cmake/mbws-sm"
)
