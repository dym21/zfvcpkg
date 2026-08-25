if(NOT TARGET rabitq::rabitq)
    add_library(rabitq::rabitq INTERFACE IMPORTED)
    get_filename_component(_rabitq_prefix "${CMAKE_CURRENT_LIST_DIR}/../.." ABSOLUTE)
    set_target_properties(rabitq::rabitq PROPERTIES
        INTERFACE_INCLUDE_DIRECTORIES "${_rabitq_prefix}/include"
    )
    unset(_rabitq_prefix)
endif()
