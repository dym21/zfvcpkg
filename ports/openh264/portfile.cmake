vcpkg_from_github(
    OUT_SOURCE_PATH SOURCE_PATH
    REPO cisco/openh264
    REF v${VERSION}
    SHA512 26a03acde7153a6b40b99f00641772433a244c72a3cc4bca6d903cf3b770174d028369a2fb73b2f0774e1124db0e269758eed6d88975347a815e0366c820d247
    PATCHES
        fix-mips64-support.patch
        001-add-bsds-to-meson.patch
)

set(cxx_link_libraries "")
if(VCPKG_LIBRARY_LINKAGE STREQUAL "static")
    block(PROPAGATE cxx_link_libraries)
        vcpkg_list(APPEND VCPKG_CMAKE_CONFIGURE_OPTIONS "-DVCPKG_DEFAULT_VARS_TO_CHECK=CMAKE_C_IMPLICIT_LINK_LIBRARIES;CMAKE_CXX_IMPLICIT_LINK_LIBRARIES")
        vcpkg_cmake_get_vars(cmake_vars_file)
        include("${cmake_vars_file}")
        
        # 1. 从 CXX 库中移除 C 库（避免重复）
        list(REMOVE_ITEM VCPKG_DETECTED_CMAKE_CXX_IMPLICIT_LINK_LIBRARIES ${VCPKG_DETECTED_CMAKE_C_IMPLICIT_LINK_LIBRARIES})

        # 2. 【关键修正】先过滤掉绝对路径（只保留逻辑库名），再统一添加前缀
        # 这一步只保留不包含 "/" 的项（即排除 /usr/lib/libm.so 这种，只留 m, stdc++ 这种）
        list(FILTER VCPKG_DETECTED_CMAKE_CXX_IMPLICIT_LINK_LIBRARIES INCLUDE REGEX "^[^/]+$")
        
        # 3. 统一添加 -l 前缀 (只做这一次！)
        # 注意：这里加了一个检查，防止已经是 -l 开头的库被重复添加
        list(TRANSFORM VCPKG_DETECTED_CMAKE_CXX_IMPLICIT_LINK_LIBRARIES REPLACE "^([^-].*)" "-l\\1")

        # 4. 手动追加 stdc++ 和 m (以防探测遗漏，且 list(REMOVE_ITEM) 会自动去重，所以不用担心重复)
        # 注意：因为前面已经加了 -l，这里手动追加时也要带 -l
        if(NOT "-lstdc++" IN_LIST VCPKG_DETECTED_CMAKE_CXX_IMPLICIT_LINK_LIBRARIES)
             list(APPEND VCPKG_DETECTED_CMAKE_CXX_IMPLICIT_LINK_LIBRARIES "-lstdc++")
        endif()
        if(NOT "-lm" IN_LIST VCPKG_DETECTED_CMAKE_CXX_IMPLICIT_LINK_LIBRARIES)
             list(APPEND VCPKG_DETECTED_CMAKE_CXX_IMPLICIT_LINK_LIBRARIES "-lm")
        endif()

        string(JOIN " " cxx_link_libraries ${VCPKG_DETECTED_CMAKE_CXX_IMPLICIT_LINK_LIBRARIES})
    endblock()
endif()


vcpkg_list(SET additional_binaries)
if((VCPKG_TARGET_ARCHITECTURE STREQUAL "x86" OR VCPKG_TARGET_ARCHITECTURE STREQUAL "x64"))
    vcpkg_find_acquire_program(NASM)
    vcpkg_list(APPEND additional_binaries "nasm = ['${NASM}']")
elseif(VCPKG_TARGET_IS_WINDOWS)
    vcpkg_find_acquire_program(GASPREPROCESSOR)
    list(JOIN GASPREPROCESSOR "','" gaspreprocessor)
    vcpkg_list(APPEND additional_binaries "gas-preprocessor.pl = ['${gaspreprocessor}']")
endif()

vcpkg_configure_meson(
    SOURCE_PATH "${SOURCE_PATH}"
    OPTIONS
        -Dtests=disabled
    ADDITIONAL_BINARIES
        ${additional_binaries}
)
vcpkg_install_meson()
vcpkg_copy_pdbs()
vcpkg_fixup_pkgconfig()

message(STATUS "cxx_link_libraries: ${cxx_link_libraries}")

if(cxx_link_libraries)
    vcpkg_replace_string("${CURRENT_PACKAGES_DIR}/lib/pkgconfig/openh264.pc"
        "(Libs:[^\r\n]*)"
        "\\1 ${cxx_link_libraries}"
        REGEX
    )
    if(NOT VCPKG_BUILD_TYPE)
        vcpkg_replace_string("${CURRENT_PACKAGES_DIR}/debug/lib/pkgconfig/openh264.pc"
            "(Libs:[^\r\n]*)"
            "\\1 ${cxx_link_libraries}"
            REGEX
        )
    endif()
endif()

vcpkg_install_copyright(FILE_LIST "${SOURCE_PATH}/LICENSE")
