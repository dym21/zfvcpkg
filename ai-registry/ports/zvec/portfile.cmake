vcpkg_check_linkage(ONLY_DYNAMIC_LIBRARY)

# The packed Windows Debug DLL exceeds MSVC's 65535 object/member limit.
# Ship the production Release library and map all consumer configurations to it.
set(VCPKG_BUILD_TYPE release)
set(VCPKG_POLICY_MISMATCHED_NUMBER_OF_BINARIES enabled)

if(DEFINED ENV{SOURCE_PATH})
    set(SOURCE_PATH "$ENV{SOURCE_PATH}")
else()
    vcpkg_from_git(
        OUT_SOURCE_PATH SOURCE_PATH
        URL https://github.com/alibaba/zvec.git
        REF d25f3a45523bb11fece05f88ca373216c3fc5f78
        PATCHES
            cmake4-lz4.patch
            vcpkg-add-library.patch
            vcpkg-fix-apply-patch-once.patch
            arrow-msbuild-trackfileaccess.patch
    )

    function(zvec_fetch_submodule relative_path url ref)
        vcpkg_from_git(
            OUT_SOURCE_PATH submodule_source
            URL "${url}"
            REF "${ref}"
        )
        file(REMOVE_RECURSE "${SOURCE_PATH}/${relative_path}")
        get_filename_component(parent "${SOURCE_PATH}/${relative_path}" DIRECTORY)
        file(MAKE_DIRECTORY "${parent}")
        file(RENAME "${submodule_source}" "${SOURCE_PATH}/${relative_path}")
    endfunction()

    zvec_fetch_submodule(thirdparty/FastPFOR/FastPFOR-0.4.0 https://github.com/fast-pack/FastPFOR.git 2be1f976935b8ff9296b029f574d7f964be9d35d)
    zvec_fetch_submodule(thirdparty/RaBitQ-Library/RaBitQ-Library-0.1 https://github.com/VectorDB-NTU/RaBitQ-Library.git 858b0d6c480766d0e4f08fc5e02f34b53d698fad)
    zvec_fetch_submodule(thirdparty/antlr/antlr4 https://github.com/antlr/antlr4.git 7a3f40bc341ddfb463d6e0aa1a6265064d020cb6)
    zvec_fetch_submodule(thirdparty/arrow/apache-arrow-21.0.0 https://github.com/apache/arrow.git ee4d09ebef61c663c1efbfa4c18e518a03b798be)
    vcpkg_apply_patches(
        SOURCE_PATH "${SOURCE_PATH}/thirdparty/arrow/apache-arrow-21.0.0"
        PATCHES "${CMAKE_CURRENT_LIST_DIR}/arrow-ep-cmake-vs-globals.patch"
    )
    zvec_fetch_submodule(thirdparty/cppjieba/cppjieba-5.6.7 https://github.com/yanyiwu/cppjieba.git b3602bef7d1f67521a61788a74fb5801a0e62cd3)
    zvec_fetch_submodule(thirdparty/gflags/gflags-2.2.2 https://github.com/gflags/gflags.git e171aa2d15ed9eb17054558e0b3a6a413bb01067)
    zvec_fetch_submodule(thirdparty/glog/glog-0.5.0 https://github.com/google/glog.git 8f9ccfe770add9e4c64e9b25c102658e3c763b73)
    zvec_fetch_submodule(thirdparty/googletest/googletest-1.10.0 https://github.com/google/googletest.git 703bd9caab50b139428cea1aaff9974ebee5742e)
    zvec_fetch_submodule(thirdparty/limonp/limonp-v1.0.2 https://github.com/yanyiwu/limonp.git 9d74077dfcdf8073536c97a00bb79d7a3c3fdaba)
    zvec_fetch_submodule(thirdparty/lz4/lz4-1.9.4 https://github.com/lz4/lz4.git 5ff839680134437dbf4678f3d0c7b371d84f4964)
    zvec_fetch_submodule(thirdparty/magic_enum/magic_enum-0.9.7 https://github.com/Neargye/magic_enum.git 83ab7f4f578bd00e1026a7cd9f7baa4f1a62cbeb)
    zvec_fetch_submodule(thirdparty/protobuf/protobuf-3.21.12 https://github.com/protocolbuffers/protobuf.git f0dc78d7e6e331b8c6bb2d5283e06aa26883ca7c)
    zvec_fetch_submodule(thirdparty/rocksdb/rocksdb-8.1.1 https://github.com/facebook/rocksdb.git 6a436150417120a3f9732d65a2a5c2b8d19b60fc)
    zvec_fetch_submodule(thirdparty/snowball/snowball-3.1.1 https://github.com/snowballstem/snowball.git cd195b51e948a902a4312f023f4a14392516a543)
    zvec_fetch_submodule(thirdparty/sparsehash/sparsehash-2.0.4 https://github.com/sparsehash/sparsehash.git f93c0c69e959c1c77611d0ba8d107aa971338811)
    zvec_fetch_submodule(thirdparty/utf8proc/utf8proc-2.11.3 https://github.com/JuliaStrings/utf8proc.git e5e799221b45bbb90f5fdc5c69b6b8dfbf017e78)
    zvec_fetch_submodule(thirdparty/yaml-cpp/yaml-cpp-0.6.3 https://github.com/jbeder/yaml-cpp.git 9a3624205e8774953ef18f57067b3426c1c5ada6)
endif()

vcpkg_find_acquire_program(GIT)
get_filename_component(git_dir "${GIT}" DIRECTORY)
vcpkg_add_to_path("${git_dir}")

vcpkg_find_acquire_program(PERL)
get_filename_component(perl_dir "${PERL}" DIRECTORY)
vcpkg_add_to_path("${perl_dir}")

find_program(ZVEC_MAKE NAMES make gmake
    HINTS
        "C:/msys64_new/mingw32/bin"
        "C:/msys64/mingw64/bin"
        "C:/msys64/usr/bin")
if(NOT ZVEC_MAKE)
    message(FATAL_ERROR "Zvec requires GNU make to generate Snowball sources")
endif()
get_filename_component(make_dir "${ZVEC_MAKE}" DIRECTORY)
vcpkg_add_to_path("${make_dir}")

# Arrow's bundled dependencies are fetched via CMake's internal curl/schannel, which
# cannot complete TLS handshakes to GitHub/Apache in this environment. Download them
# once with system curl using --ssl-no-revoke from the Alibaba OSS mirror and point
# Arrow at the local files.
find_program(ZVEC_CURL NAMES curl)
if(NOT ZVEC_CURL)
    message(FATAL_ERROR "curl is required to download Arrow's bundled dependencies")
endif()

function(zvec_download_arrow_dep filename sha256 envvar)
    set(url "https://zvec-bj.oss-cn-beijing.aliyuncs.com/thirdparty/${filename}")
    set(filepath "${CURRENT_BUILDTREES_DIR}/zvec-arrow-${filename}")
    if(NOT EXISTS "${filepath}")
        message(STATUS "Downloading ${filename} for Arrow from OSS mirror...")
        execute_process(
            COMMAND "${ZVEC_CURL}" --ssl-no-revoke --location --output "${filepath}" "${url}"
            RESULT_VARIABLE result
        )
        if(NOT result EQUAL 0)
            message(FATAL_ERROR "Failed to download ${filename} for Arrow (curl exit ${result})")
        endif()
    endif()
    file(SHA256 "${filepath}" actual_sha256)
    if(NOT actual_sha256 STREQUAL "${sha256}")
        message(FATAL_ERROR "${filename} SHA256 mismatch: expected ${sha256}, got ${actual_sha256}")
    endif()
    file(TO_CMAKE_PATH "${filepath}" filepath_cmake)
    set(ENV{${envvar}} "file://${filepath_cmake}")
    message(STATUS "Using local ${filename} for Arrow: ${filepath_cmake}")
endfunction()

zvec_download_arrow_dep(
    "boost-1.88.0-cmake.tar.gz"
    "dcea50f40ba1ecfc448fdf886c0165cf3e525fef2c9e3e080b9804e8117b9694"
    "ARROW_BOOST_URL")
zvec_download_arrow_dep(
    "rapidjson-232389d4f1012dddec4ef84861face2d2ba85709.tar.gz"
    "b9290a9a6d444c8e049bd589ab804e0ccf2b05dc5984a19ed5ae75d090064806"
    "ARROW_RAPIDJSON_URL")
zvec_download_arrow_dep(
    "re2-2022-06-01.tar.gz"
    "f89c61410a072e5cbcf8c27e3a778da7d6fd2f2b5b1445cd4f4508bee946ab0f"
    "ARROW_RE2_URL")
zvec_download_arrow_dep(
    "thrift-0.22.0.tar.gz"
    "794a0e455787960d9f27ab92c38e34da27e8deeda7a5db0e59dc64a00df8a1e5"
    "ARROW_THRIFT_URL")
zvec_download_arrow_dep(
    "utf8proc-2.10.0.tar.gz"
    "6f4f1b639daa6dca9f80bc5db1233e9cbaa31a67790887106160b33ef743f136"
    "ARROW_UTF8PROC_URL")
zvec_download_arrow_dep(
    "xsimd-13.0.0.tar.gz"
    "8bdbbad0c3e7afa38d88d0d484d70a1671a1d8aefff03f4223ab2eb6a41110a3"
    "ARROW_XSIMD_URL")
zvec_download_arrow_dep(
    "zlib-1.3.1.tar.gz"
    "9a93b2b7dfdac77ceba5a558a580e74667dd6fede4585b91eefb60f03b72df23"
    "ARROW_ZLIB_URL")

vcpkg_cmake_configure(
    SOURCE_PATH "${SOURCE_PATH}"
    OPTIONS
        -DBUILD_ZVEC_SHARED=ON
        -DBUILD_ZVEC_AILEGO_SHARED=OFF
        -DBUILD_ZVEC_CORE_SHARED=OFF
        -DBUILD_PYTHON_BINDINGS=OFF
        -DBUILD_C_BINDINGS=OFF
        -DBUILD_TOOLS=OFF
        -DBUILD_EXAMPLES=OFF
        -DUSE_OSS_MIRROR=OFF
)

vcpkg_cmake_build(TARGET zvec_shared)

file(INSTALL "${CURRENT_BUILDTREES_DIR}/${TARGET_TRIPLET}-rel/bin/zvec.dll"
     DESTINATION "${CURRENT_PACKAGES_DIR}/bin")
file(INSTALL "${CURRENT_BUILDTREES_DIR}/${TARGET_TRIPLET}-rel/lib/zvec_shared.lib"
     DESTINATION "${CURRENT_PACKAGES_DIR}/lib")

file(INSTALL "${SOURCE_PATH}/src/include/zvec"
     DESTINATION "${CURRENT_PACKAGES_DIR}/include"
     FILES_MATCHING PATTERN "*.h" PATTERN "*.hpp" PATTERN "*.hxx")

configure_file("${CMAKE_CURRENT_LIST_DIR}/ZvecConfig.cmake.in"
               "${CURRENT_PACKAGES_DIR}/share/zvec/ZvecConfig.cmake" @ONLY)
file(INSTALL "${CMAKE_CURRENT_LIST_DIR}/usage"
     DESTINATION "${CURRENT_PACKAGES_DIR}/share/${PORT}")
vcpkg_install_copyright(FILE_LIST "${SOURCE_PATH}/LICENSE")
