include(CMakeFindDependencyMacro)
find_dependency(limonp CONFIG)

if(NOT TARGET cppjieba)
    add_library(cppjieba INTERFACE IMPORTED)
    get_filename_component(_cppjieba_prefix "${CMAKE_CURRENT_LIST_DIR}/../.." ABSOLUTE)
    set_target_properties(cppjieba PROPERTIES
        INTERFACE_INCLUDE_DIRECTORIES "${_cppjieba_prefix}/include"
        INTERFACE_LINK_LIBRARIES "limonp::limonp"
    )
    unset(_cppjieba_prefix)
endif()

if(NOT TARGET cppjieba::cppjieba)
    add_library(cppjieba::cppjieba ALIAS cppjieba)
endif()
