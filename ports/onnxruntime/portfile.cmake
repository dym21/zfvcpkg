vcpkg_check_linkage(ON_STATIC_LIBRARY)

# Download ONNX Runtime source
vcpkg_from_github(
    OUT_SOURCE_PATH SOURCE_PATH
    REPO microsoft/onnxruntime
    REF "v${VERSION}"
    SHA512 auto
    HEAD_REF main
)

# Apply patches for better CMake integration
vcpkg_apply_patches(
    SOURCE_PATH "${SOURCE_PATH}"
    PATCHES
        "${CMAKE_CURRENT_LIST_DIR}/fix-cmake.patch"
        "${CMAKE_CURRENT_LIST_DIR}/fix-cmake-cuda.patch"
)

# Configure build options
set(ENV{CMAKE_POSITION_INDEPENDENT_CODE} ON)

# CUDA support
set(USE_CUDA OFF)
if("cuda" IN_LIST FEATURES)
    set(USE_CUDA ON)
endif()

# TensorRT support
set(USE_TENSORRT OFF)
if("tensorrt" IN_LIST FEATURES)
    set(USE_TENSORRT ON)
endif()

# DirectML support (Windows only)
set(USE_DIRECTML OFF)
if("directml" IN_LIST FEATURES AND WIN32)
    set(USE_DIRECTML ON)
endif()

# Configure with CMake
vcpkg_cmake_configure(
    SOURCE_PATH "${SOURCE_PATH}"
    OPTIONS
        -Donnxruntime_BUILD_UNIT_TESTS=OFF
        -Donnxruntime_BUILD_SHARED_LIBS=OFF
        -Donnxruntime_ENABLE_CPUINFO=ON
        -Donnxruntime_USE_FULL_PROTOBUF=ON
        -Donnxruntime_USE_CUDA=${USE_CUDA}
        -Donnxruntime_USE_TENSORRT=${USE_TENSORRT}
        -Donnxruntime_USE_DIRECTML=${USE_DIRECTML}
        -Donnxruntime_DISABLE_RTTI=OFF
        -Donnxruntime_ENABLE_MICROSOFT_INTERNAL=OFF
        -DCMAKE_POSITION_INDEPENDENT_CODE=ON
        -DCMAKE_CXX_STANDARD=17
    MAYBE_UNUSED_VARIABLES
        onnxruntime_BUILD_UNIT_TESTS
        onnxruntime_BUILD_SHARED_LIBS
        onnxruntime_ENABLE_CPUINFO
        onnxruntime_USE_FULL_PROTOBUF
        onnxruntime_USE_CUDA
        onnxruntime_USE_TENSORRT
        onnxruntime_USE_DIRECTML
        onnxruntime_DISABLE_RTTI
        onnxruntime_ENABLE_MICROSOFT_INTERNAL
)

vcpkg_cmake_install()

# Copy licenses
vcpkg_install_copyright(FILE_LIST "${SOURCE_PATH}/LICENSE")

# Fix include paths if needed
if(EXISTS "${CURRENT_PACKAGES_DIR}/include/onnxruntime")
    file(GLOB_RECURSE HEADERS "${CURRENT_PACKAGES_DIR}/include/onnxruntime/*.h" "${CURRENT_PACKAGES_DIR}/include/onnxruntime/*.hpp")
    foreach(HEADER ${HEADERS})
        file(READ "${HEADER}" CONTENT)
        string(REPLACE "#include \"onnxruntime/" "#include \"onnxruntime/" CONTENT "${CONTENT}")
        file(WRITE "${HEADER}" "${CONTENT}")
    endforeach()
endif()

# Clean up debug symbols and unnecessary files
file(REMOVE_RECURSE 
    "${CURRENT_PACKAGES_DIR}/debug/share"
    "${CURRENT_PACKAGES_DIR}/debug/include"
    "${CURRENT_PACKAGES_DIR}/etc"
    "${CURRENT_PACKAGES_DIR}/onnxruntime"
)

# Create CMake config files
file(INSTALL "${CMAKE_CURRENT_LIST_DIR}/onnxruntime-config.cmake" 
     DESTINATION "${CURRENT_PACKAGES_DIR}/share/${PORT}")

# Create usage file
file(INSTALL "${CMAKE_CURRENT_LIST_DIR}/usage" 
     DESTINATION "${CURRENT_PACKAGES_DIR}/share/${PORT}" 
     RENAME usage.txt)
