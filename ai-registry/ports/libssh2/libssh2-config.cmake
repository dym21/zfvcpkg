include(CMakeFindDependencyMacro)

find_dependency(mbws-gmssl CONFIG)
find_dependency(ZLIB CONFIG)

include("${CMAKE_CURRENT_LIST_DIR}/Libssh2Config.cmake")

if(TARGET Libssh2::libssh2_static AND
   NOT TARGET libssh2::libssh2_static)
    add_library(libssh2::libssh2_static INTERFACE IMPORTED)
    set_target_properties(libssh2::libssh2_static PROPERTIES
        INTERFACE_LINK_LIBRARIES Libssh2::libssh2_static)
endif()

if(TARGET Libssh2::libssh2_static AND NOT TARGET libssh2::libssh2)
    add_library(libssh2::libssh2 INTERFACE IMPORTED)
    set_target_properties(libssh2::libssh2 PROPERTIES
        INTERFACE_LINK_LIBRARIES Libssh2::libssh2_static)
endif()

set(libssh2_VERSION "1.11.0")
set(libssh2_FOUND TRUE)
