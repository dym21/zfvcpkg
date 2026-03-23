# ONNX Runtime CMake configuration file
#
# This file is used by find_package(ONNXRuntime)

include(CMakeFindDependencyMacro)

# Find required dependencies
find_dependency(Protobuf REQUIRED)
find_dependency(flatbuffers REQUIRED)
find_dependency(absl REQUIRED)
find_dependency(Eigen3 REQUIRED)
find_dependency(nlohmann_json REQUIRED)

# Create imported target
if(NOT TARGET onnxruntime::onnxruntime)
    add_library(onnxruntime::onnxruntime STATIC IMPORTED)
    
    set_target_properties(onnxruntime::onnxruntime PROPERTIES
        IMPORTED_LOCATION "${_IMPORT_PREFIX}/lib/onnxruntime.lib"
        IMPORTED_LOCATION_DEBUG "${_IMPORT_PREFIX}/debug/lib/onnxruntime.lib"
        IMPORTED_LOCATION_RELEASE "${_IMPORT_PREFIX}/lib/onnxruntime.lib"
        INTERFACE_INCLUDE_DIRECTORIES "${_IMPORT_PREFIX}/include"
        INTERFACE_COMPILE_DEFINITIONS "ONNXRUNTIME_STATIC"
    )
endif()

# Set version
set(ONNXRUNTIME_VERSION "@VERSION@")
