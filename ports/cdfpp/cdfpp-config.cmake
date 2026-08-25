include(CMakeFindDependencyMacro)

find_dependency(fmt CONFIG REQUIRED)
find_dependency(libdeflate CONFIG REQUIRED)

if(NOT TARGET cdfpp::cdfpp)
    get_filename_component(_CDFPP_PREFIX "${CMAKE_CURRENT_LIST_DIR}/../.." ABSOLUTE)

    if(TARGET libdeflate::libdeflate_static)
        set(_CDFPP_LIBDEFLATE_TARGET libdeflate::libdeflate_static)
    elseif(TARGET libdeflate::libdeflate_shared)
        set(_CDFPP_LIBDEFLATE_TARGET libdeflate::libdeflate_shared)
    else()
        message(FATAL_ERROR "cdfpp requires a libdeflate CMake target")
    endif()

    add_library(cdfpp::cdfpp INTERFACE IMPORTED)
    set_target_properties(cdfpp::cdfpp PROPERTIES
        INTERFACE_COMPILE_DEFINITIONS "CDFPP_NO_SIMD"
        INTERFACE_COMPILE_FEATURES "cxx_std_20"
        INTERFACE_INCLUDE_DIRECTORIES "${_CDFPP_PREFIX}/include;${_CDFPP_PREFIX}/include/cdfpp"
        INTERFACE_LINK_LIBRARIES "fmt::fmt;${_CDFPP_LIBDEFLATE_TARGET}"
    )

    unset(_CDFPP_LIBDEFLATE_TARGET)
    unset(_CDFPP_PREFIX)
endif()
