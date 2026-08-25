cmake_minimum_required(VERSION 3.21)
project(libmspub VERSION 0.1.5 LANGUAGES CXX)

include(GNUInstallDirs)
include(CMakePackageConfigHelpers)

find_package(Iconv REQUIRED)
find_package(librevenge CONFIG REQUIRED)
find_package(ZLIB REQUIRED)

set(LIBMSPUB_SOURCES
    src/lib/ColorReference.cpp
    src/lib/Coordinate.cpp
    src/lib/Dash.cpp
    src/lib/Fill.cpp
    src/lib/MSPUBCollector.cpp
    src/lib/MSPUBDocument.cpp
    src/lib/MSPUBMetaData.cpp
    src/lib/MSPUBParser.cpp
    src/lib/MSPUBParser2k.cpp
    src/lib/MSPUBParser97.cpp
    src/lib/PolygonUtils.cpp
    src/lib/Shadow.cpp
    src/lib/ShapeGroupElement.cpp
    src/lib/VectorTransformation2D.cpp
    src/lib/libmspub_utils.cpp
)

add_library(mspub STATIC ${LIBMSPUB_SOURCES})
set_target_properties(mspub PROPERTIES
    CXX_STANDARD 11
    CXX_STANDARD_REQUIRED ON
    CXX_EXTENSIONS OFF
    EXPORT_NAME libmspub
)
target_compile_definitions(mspub PRIVATE
    LIBMSPUB_BUILD=1
    BOOST_ALL_NO_LIB
    _USE_MATH_DEFINES
)
target_include_directories(mspub PUBLIC
    $<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}/inc>
    $<INSTALL_INTERFACE:${CMAKE_INSTALL_INCLUDEDIR}>
)
target_include_directories(mspub PRIVATE "${CMAKE_CURRENT_SOURCE_DIR}/src/lib")
target_link_libraries(mspub PUBLIC
    Iconv::Iconv
    librevenge::librevenge
    librevenge::stream
    ZLIB::ZLIB
)

install(TARGETS mspub
    EXPORT libmspub-targets
    ARCHIVE DESTINATION "${CMAKE_INSTALL_LIBDIR}"
    LIBRARY DESTINATION "${CMAKE_INSTALL_LIBDIR}"
    RUNTIME DESTINATION "${CMAKE_INSTALL_BINDIR}"
)
install(DIRECTORY inc/libmspub DESTINATION "${CMAKE_INSTALL_INCLUDEDIR}")
install(EXPORT libmspub-targets
    FILE libmspub-targets.cmake
    NAMESPACE libmspub::
    DESTINATION "${CMAKE_INSTALL_LIBDIR}/cmake/libmspub"
)
configure_package_config_file(
    "${CMAKE_CURRENT_SOURCE_DIR}/libmspub-config.cmake.in"
    "${CMAKE_CURRENT_BINARY_DIR}/libmspub-config.cmake"
    INSTALL_DESTINATION "${CMAKE_INSTALL_LIBDIR}/cmake/libmspub"
)
write_basic_package_version_file(
    "${CMAKE_CURRENT_BINARY_DIR}/libmspub-config-version.cmake"
    VERSION "${PROJECT_VERSION}"
    COMPATIBILITY SameMajorVersion
)
install(FILES
    "${CMAKE_CURRENT_BINARY_DIR}/libmspub-config.cmake"
    "${CMAKE_CURRENT_BINARY_DIR}/libmspub-config-version.cmake"
    DESTINATION "${CMAKE_INSTALL_LIBDIR}/cmake/libmspub"
)
