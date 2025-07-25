if(VCPKG_TARGET_IS_WINDOWS)
    vcpkg_check_linkage(ONLY_STATIC_LIBRARY)
endif()

vcpkg_from_github(
    OUT_SOURCE_PATH SOURCE_PATH
    REPO NVIDIA/cutlass
    REF v${VERSION}
    SHA512 f9bc493a80e959b21d3adbe85987d375c052f6095be9e13b871f890a6ead093bfb68712eae206fd8fc3f0a2ac06d96760ffec7939869b0e12c4c37788184cc21
    HEAD_REF main
)

vcpkg_find_acquire_program(PYTHON3)
get_filename_component(PYTHON_PATH "${PYTHON3}" PATH)
vcpkg_add_to_path(PREPEND "${PYTHON_PATH}")

vcpkg_check_features(OUT_FEATURE_OPTIONS FEATURE_OPTIONS
    FEATURES
        tests   CUTLASS_ENABLE_TESTS
        tests   CUTLASS_ENABLE_GTEST_UNIT_TESTS
        tests   CUTLASS_INSTALL_TESTS
        tests   CUTLASS_TEST_UNIT_ENABLE_WARNINGS
        samples CUTLASS_ENABLE_EXAMPLES
        tools   CUTLASS_ENABLE_TOOLS
        tools   CUTLASS_ENABLE_LIBRARY
)

vcpkg_cmake_configure(
    SOURCE_PATH "${SOURCE_PATH}"
    OPTIONS
        ${FEATURE_OPTIONS}
        -DCUTLASS_REVISION:STRING=v${VERSION}
        -DCUTLASS_ENABLE_HEADERS_ONLY=ON
        -DCUTLASS_ENABLE_PERFORMANCE=OFF
        -DCUTLASS_LIBRARY_OPERATIONS:STRING=all
        -DCUTLASS_LIBRARY_KERNELS:STRING=all
        -DCUTLASS_ENABLE_CUBLAS=ON
        -DCUTLASS_ENABLE_CUDNN=ON
        -DCUTLASS_ENABLE_PROFILER=OFF
        -DPython3_EXECUTABLE:FILEPATH=${PYTHON3}
    MAYBE_UNUSED_VARIABLES
        CUTLASS_LIBRARY_OPERATIONS
)
vcpkg_cmake_install()
vcpkg_cmake_config_fixup(CONFIG_PATH "lib/cmake/NvidiaCutlass" PACKAGE_NAME "NvidiaCutlass")

file(REMOVE_RECURSE
    "${CURRENT_PACKAGES_DIR}/debug"
    "${CURRENT_PACKAGES_DIR}/test"
    "${CURRENT_PACKAGES_DIR}/lib"
)
vcpkg_install_copyright(FILE_LIST "${SOURCE_PATH}/LICENSE.txt")
