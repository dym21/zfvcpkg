if(TARGET mbws-gmssl::ssl)
  return()
endif()

include(CMakeFindDependencyMacro)
find_dependency(Threads)

get_filename_component(_MBWS_GMSSL_PREFIX
  "${CMAKE_CURRENT_LIST_DIR}/../.."
  ABSOLUTE
)

add_library(mbws-gmssl::crypto STATIC IMPORTED)
set_target_properties(mbws-gmssl::crypto PROPERTIES
  IMPORTED_CONFIGURATIONS Release
  IMPORTED_LOCATION_RELEASE
    "${_MBWS_GMSSL_PREFIX}/lib/mbws-gmssl/libcrypto.a"
  MAP_IMPORTED_CONFIG_DEBUG Release
  MAP_IMPORTED_CONFIG_MINSIZEREL Release
  MAP_IMPORTED_CONFIG_RELWITHDEBINFO Release
  INTERFACE_INCLUDE_DIRECTORIES
    "${_MBWS_GMSSL_PREFIX}/include/mbws-gmssl"
  INTERFACE_LINK_LIBRARIES "Threads::Threads;${CMAKE_DL_LIBS}"
)

add_library(mbws-gmssl::ssl STATIC IMPORTED)
set_target_properties(mbws-gmssl::ssl PROPERTIES
  IMPORTED_CONFIGURATIONS Release
  IMPORTED_LOCATION_RELEASE
    "${_MBWS_GMSSL_PREFIX}/lib/mbws-gmssl/libssl.a"
  MAP_IMPORTED_CONFIG_DEBUG Release
  MAP_IMPORTED_CONFIG_MINSIZEREL Release
  MAP_IMPORTED_CONFIG_RELWITHDEBINFO Release
  INTERFACE_INCLUDE_DIRECTORIES
    "${_MBWS_GMSSL_PREFIX}/include/mbws-gmssl"
  INTERFACE_LINK_LIBRARIES "mbws-gmssl::crypto;Threads::Threads;${CMAKE_DL_LIBS}"
)

set(mbws-gmssl_VERSION "2.5.0")
unset(_MBWS_GMSSL_PREFIX)
