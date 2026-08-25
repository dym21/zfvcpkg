cmake_minimum_required(VERSION 3.21)
project(librevenge VERSION 0.0.6 LANGUAGES CXX)

include(GNUInstallDirs)
include(CMakePackageConfigHelpers)

find_package(ZLIB REQUIRED)

add_library(revenge STATIC
    src/lib/RVNGBinaryData.cpp
    src/lib/RVNGMemoryStream.cpp
    src/lib/RVNGProperty.cpp
    src/lib/RVNGPropertyList.cpp
    src/lib/RVNGPropertyListVector.cpp
    src/lib/RVNGString.cpp
    src/lib/RVNGStringVector.cpp
    src/lib/RVNGSVGDrawingGenerator.cpp
)
set_target_properties(revenge PROPERTIES
    CXX_STANDARD 11
    CXX_STANDARD_REQUIRED ON
    CXX_EXTENSIONS OFF
    EXPORT_NAME librevenge
)
target_compile_definitions(revenge PRIVATE
    LIBREVENGE_BUILD
    BOOST_ERROR_CODE_HEADER_ONLY
)
target_include_directories(revenge PUBLIC
    $<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}/inc>
    $<INSTALL_INTERFACE:${CMAKE_INSTALL_INCLUDEDIR}>
)
target_link_libraries(revenge PUBLIC ZLIB::ZLIB)

add_library(revenge_stream STATIC
    src/lib/RVNGOLEStream.cpp
    src/lib/RVNGStreamImplementation.cpp
    src/lib/RVNGZipStream.cpp
)
set_target_properties(revenge_stream PROPERTIES
    CXX_STANDARD 11
    CXX_STANDARD_REQUIRED ON
    CXX_EXTENSIONS OFF
    EXPORT_NAME stream
)
target_compile_definitions(revenge_stream PRIVATE LIBREVENGE_STREAM_BUILD)
target_include_directories(revenge_stream PUBLIC
    $<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}/inc>
    $<INSTALL_INTERFACE:${CMAKE_INSTALL_INCLUDEDIR}>
)
target_link_libraries(revenge_stream PUBLIC revenge ZLIB::ZLIB)

install(TARGETS revenge revenge_stream
    EXPORT librevenge-targets
    ARCHIVE DESTINATION "${CMAKE_INSTALL_LIBDIR}"
    LIBRARY DESTINATION "${CMAKE_INSTALL_LIBDIR}"
    RUNTIME DESTINATION "${CMAKE_INSTALL_BINDIR}"
)
install(DIRECTORY inc/librevenge inc/librevenge-stream
    DESTINATION "${CMAKE_INSTALL_INCLUDEDIR}"
)
install(EXPORT librevenge-targets
    FILE librevenge-targets.cmake
    NAMESPACE librevenge::
    DESTINATION "${CMAKE_INSTALL_LIBDIR}/cmake/librevenge"
)
configure_package_config_file(
    "${CMAKE_CURRENT_SOURCE_DIR}/librevenge-config.cmake.in"
    "${CMAKE_CURRENT_BINARY_DIR}/librevenge-config.cmake"
    INSTALL_DESTINATION "${CMAKE_INSTALL_LIBDIR}/cmake/librevenge"
)
write_basic_package_version_file(
    "${CMAKE_CURRENT_BINARY_DIR}/librevenge-config-version.cmake"
    VERSION "${PROJECT_VERSION}"
    COMPATIBILITY SameMajorVersion
)
install(FILES
    "${CMAKE_CURRENT_BINARY_DIR}/librevenge-config.cmake"
    "${CMAKE_CURRENT_BINARY_DIR}/librevenge-config-version.cmake"
    DESTINATION "${CMAKE_INSTALL_LIBDIR}/cmake/librevenge"
)
