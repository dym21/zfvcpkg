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
        fix-cmake.patch # .framework install, external library workarounds(abseil-cpp, eigen3)
        fix-cmake-cuda.patch
        fix-missing-cstdint.patch
        fix-cmake-mlas.patch
)

find_program(PROTOC NAMES protoc PATHS "${CURRENT_HOST_INSTALLED_DIR}/tools/protobuf" REQUIRED NO_DEFAULT_PATH NO_CMAKE_PATH)
message(STATUS "Using protoc: ${PROTOC}")

find_program(FLATC NAMES flatc PATHS "${CURRENT_HOST_INSTALLED_DIR}/tools/flatbuffers" REQUIRED NO_DEFAULT_PATH NO_CMAKE_PATH)
message(STATUS "Using flatc: ${FLATC}")

vcpkg_find_acquire_program(PYTHON3)
get_filename_component(PYTHON_PATH "${PYTHON3}" PATH)
message(STATUS "Using python3: ${PYTHON3}")

vcpkg_execute_required_process(
    COMMAND "${PYTHON3}" onnxruntime/core/flatbuffers/schema/compile_schema.py --flatc "${FLATC}"
    LOGNAME compile_schema_core
    WORKING_DIRECTORY "${SOURCE_PATH}"
)
vcpkg_execute_required_process(
    COMMAND "${PYTHON3}" onnxruntime/lora/adapter_format/compile_schema.py --flatc "${FLATC}"
    LOGNAME compile_schema_lora
    WORKING_DIRECTORY "${SOURCE_PATH}"
)

vcpkg_check_features(OUT_FEATURE_OPTIONS FEATURE_OPTIONS
    FEATURES
        python    onnxruntime_ENABLE_PYTHON
        training  onnxruntime_ENABLE_TRAINING
        training  onnxruntime_ENABLE_TRAINING_APIS
        cuda      onnxruntime_USE_CUDA
        cuda      onnxruntime_USE_CUDA_NHWC_OPS
        openvino  onnxruntime_USE_OPENVINO
        tensorrt  onnxruntime_USE_TENSORRT
        tensorrt  onnxruntime_USE_TENSORRT_BUILTIN_PARSER
        directml  onnxruntime_USE_DML
        directml  onnxruntime_USE_CUSTOM_DIRECTML
        winml     onnxruntime_USE_WINML
        coreml    onnxruntime_USE_COREML
        mimalloc  onnxruntime_USE_MIMALLOC
        valgrind  onnxruntime_USE_VALGRIND
        xnnpack   onnxruntime_USE_XNNPACK
        kleidiai  onnxruntime_USE_KLEIDIAI
        nnapi     onnxruntime_USE_NNAPI_BUILTIN
        azure     onnxruntime_USE_AZURE
        test      onnxruntime_BUILD_UNIT_TESTS
        test      onnxruntime_BUILD_BENCHMARKS
        test      onnxruntime_RUN_ONNX_TESTS
        framework onnxruntime_BUILD_APPLE_FRAMEWORK
        framework onnxruntime_BUILD_OBJC
        nccl      onnxruntime_USE_NCCL
    INVERTED_FEATURES
        cuda      onnxruntime_USE_MEMORY_EFFICIENT_ATTENTION
)

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
