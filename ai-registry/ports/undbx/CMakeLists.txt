cmake_minimum_required(VERSION 3.16)
project(undbx VERSION 0.21 LANGUAGES C)

include(CMakePackageConfigHelpers)

add_library(undbx
    dbxprogress.c
    dbxread.c
    dbxsys.c
    emlread.c
    undbx.c
)
add_library(undbx::undbx ALIAS undbx)
target_compile_features(undbx PRIVATE c_std_99)
target_include_directories(undbx
    PUBLIC
        "$<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}>"
        "$<INSTALL_INTERFACE:include>"
)

install(
    TARGETS undbx
    EXPORT undbx-targets
    ARCHIVE DESTINATION lib
    LIBRARY DESTINATION lib
    RUNTIME DESTINATION bin
    INCLUDES DESTINATION include
)
install(FILES extract_dbx.h DESTINATION include)
install(
    EXPORT undbx-targets
    FILE undbx-targets.cmake
    NAMESPACE undbx::
    DESTINATION share/undbx
)

configure_package_config_file(
    "${CMAKE_CURRENT_SOURCE_DIR}/undbx-config.cmake.in"
    "${CMAKE_CURRENT_BINARY_DIR}/undbx-config.cmake"
    INSTALL_DESTINATION share/undbx
)
write_basic_package_version_file(
    "${CMAKE_CURRENT_BINARY_DIR}/undbx-config-version.cmake"
    VERSION "${PROJECT_VERSION}"
    COMPATIBILITY SameMajorVersion
)
install(
    FILES
        "${CMAKE_CURRENT_BINARY_DIR}/undbx-config.cmake"
        "${CMAKE_CURRENT_BINARY_DIR}/undbx-config-version.cmake"
    DESTINATION share/undbx
)
