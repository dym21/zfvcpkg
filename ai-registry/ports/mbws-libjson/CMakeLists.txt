cmake_minimum_required(VERSION 3.20)

project(mbws_libjson LANGUAGES CXX)

if(NOT IS_DIRECTORY "${MBWS_SOURCE_DIR}")
  message(FATAL_ERROR "Missing MBWS libjson source: ${MBWS_SOURCE_DIR}")
endif()

file(GLOB LIBJSON_SOURCES CONFIGURE_DEPENDS
  "${MBWS_SOURCE_DIR}/_internal/Source/*.cpp"
)
list(FILTER LIBJSON_SOURCES EXCLUDE REGEX "/\\._")

add_library(mbws_libjson STATIC ${LIBJSON_SOURCES})
set_target_properties(mbws_libjson PROPERTIES
  EXPORT_NAME libjson
  OUTPUT_NAME json
  POSITION_INDEPENDENT_CODE ON
)
target_compile_features(mbws_libjson PUBLIC cxx_std_11)
target_compile_options(mbws_libjson PRIVATE
  "$<$<COMPILE_LANG_AND_ID:CXX,GNU>:-std=gnu++11>"
)
target_include_directories(mbws_libjson
  PUBLIC
    "$<BUILD_INTERFACE:${MBWS_SOURCE_DIR}>"
    "$<INSTALL_INTERFACE:include/libjson>"
)

install(TARGETS mbws_libjson
  EXPORT mbws-libjson-targets
  ARCHIVE DESTINATION lib
)
install(DIRECTORY "${MBWS_SOURCE_DIR}/"
  DESTINATION include/libjson
  FILES_MATCHING
  PATTERN "*.h"
  PATTERN "._*" EXCLUDE
  PATTERN "Getting Started" EXCLUDE
  PATTERN "build_linux" EXCLUDE
  PATTERN "buid_windows" EXCLUDE
  PATTERN "TestSuite*" EXCLUDE
)
install(EXPORT mbws-libjson-targets
  FILE mbws-libjson-targets.cmake
  NAMESPACE mbws::
  DESTINATION share/mbws-libjson
)
install(FILES "${CMAKE_CURRENT_SOURCE_DIR}/mbws-libjson-config.cmake"
  DESTINATION share/mbws-libjson
)
