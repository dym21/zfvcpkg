if(TARGET mbws::sigar)
  return()
endif()

get_filename_component(_MBWS_SIGAR_PREFIX
  "${CMAKE_CURRENT_LIST_DIR}/../.."
  ABSOLUTE
)
add_library(mbws::sigar STATIC IMPORTED)
set_target_properties(mbws::sigar PROPERTIES
  IMPORTED_CONFIGURATIONS "Debug;Release"
  IMPORTED_LOCATION_DEBUG "${_MBWS_SIGAR_PREFIX}/debug/lib/libsigar.a"
  IMPORTED_LOCATION_RELEASE "${_MBWS_SIGAR_PREFIX}/lib/libsigar.a"
  MAP_IMPORTED_CONFIG_MINSIZEREL Release
  MAP_IMPORTED_CONFIG_RELWITHDEBINFO Release
  INTERFACE_INCLUDE_DIRECTORIES "${_MBWS_SIGAR_PREFIX}/include"
)
unset(_MBWS_SIGAR_PREFIX)
