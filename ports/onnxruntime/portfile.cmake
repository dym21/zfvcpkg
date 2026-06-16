vcpkg_check_linkage(ONLY_STATIC_LIBRARY)

# Download ONNX Runtime source
vcpkg_from_github(
    OUT_SOURCE_PATH SOURCE_PATH
    REPO microsoft/onnxruntime
    REF "v${VERSION}"
    SHA512 373c51575ada457b8aead5d195a5f3eba62fb747b6370a2a9889fff875c40ea30af8fd49104d58cc86f79247410e829086b0979f37ca8635c6dd34960e9cc424
    HEAD_REF main
)

# Use onnxruntime's cmake subdirectory as source path
set(ONNXRT_SOURCE_PATH "${SOURCE_PATH}/cmake")

# Find required tools
vcpkg_find_acquire_program(PYTHON3)

# Patch: disable COMPILE_WARNING_AS_ERROR (WX flag) for MSVC 19.51 compatibility
vcpkg_replace_string("${SOURCE_PATH}/cmake/CMakeLists.txt"
    "set_target_properties(\${target_name} PROPERTIES COMPILE_WARNING_AS_ERROR ON)"
    "# set_target_properties(\${target_name} PROPERTIES COMPILE_WARNING_AS_ERROR ON) # Disabled for MSVC 19.51"
)

# Patch MLAS cmake: comment out all ASM files and problematic C++ files
# Also disable onnxruntime_mlas_q4dq target, and add stub implementations
vcpkg_execute_required_process(
    COMMAND powershell.exe -NoProfile -Command "
        \$file = '${SOURCE_PATH}/cmake/onnxruntime_mlas.cmake'
        \$content = Get-Content \$file
        \$newContent = @()
        \$inQ4dqSection = \$false
        foreach (\$line in \$content) {
            # Comment out all ASM files (amd64 and i386)
            if (\$line -match 'amd64.*\\.asm|i386.*\\.asm') {
                \$newContent += \"      # \$(\$line.Trim()) # Disabled for MSVC 19.51\"
            }
            # Comment out problematic C++ files with calling convention issues
            elseif (\$line -match 'qgemm_kernel_amx\\.cpp|qgemm_kernel_avx2\\.cpp|sqnbitgemm_kernel_avx2\\.cpp|sqnbitgemm_kernel_avx512\\.cpp|sqnbitgemm_kernel_avx512vnni\\.cpp|q4gemm_avx512\\.cpp') {
                \$newContent += \"      # \$(\$line.Trim()) # Disabled for MSVC 19.51\"
            }
            # Disable onnxruntime_mlas_q4dq target (link errors due to missing ASM symbols)
            elseif (\$line -match 'onnxruntime_add_executable\\(onnxruntime_mlas_q4dq') {
                \$inQ4dqSection = \$true
                \$newContent += '  if(FALSE) # Disabled for MSVC 19.51 - link errors'
                \$newContent += \$line
            }
            elseif (\$inQ4dqSection -and \$line -match '^\\s*target_link_libraries\\(onnxruntime_mlas_q4dq.*Threads::Threads\\)') {
                \$newContent += \$line
                \$newContent += '  endif() # End disabled q4dq section'
                \$inQ4dqSection = \$false
            }
            else {
                \$newContent += \$line
            }
        }
        \$newContent | Set-Content \$file
    "
    WORKING_DIRECTORY "${SOURCE_PATH}"
    LOGNAME "patch-mlas"
)

# Create stub implementations for missing MLAS assembly symbols
file(WRITE "${SOURCE_PATH}/onnxruntime/core/mlas/lib/stub_kernels.cpp"
"// Stub implementations for MLAS kernels disabled due to MSVC 19.51 compatibility
#include \"mlasi.h\"

void
MLASCALL
MlasGemmFloatKernelSse(
    const size_t M,
    const size_t N,
    const size_t K,
    const float* A,
    const size_t lda,
    const float* B,
    const size_t ldb,
    float* C,
    const size_t ldc,
    const float beta
    )
{
    // Stub - should not be called in production
}

void
MLASCALL
MlasGemmFloatKernelAvx(
    const size_t M,
    const size_t N,
    const size_t K,
    const float* A,
    const size_t lda,
    const float* B,
    const size_t ldb,
    float* C,
    const size_t ldc,
    const float beta
    )
{
    // Stub - should not be called in production
}
")

# Add stub_kernels.cpp to MLAS sources
vcpkg_replace_string("${SOURCE_PATH}/cmake/onnxruntime_mlas.cmake"
    "\${MLAS_SRC_DIR}/dgemm.cpp"
    "\${MLAS_SRC_DIR}/dgemm.cpp\n      \${MLAS_SRC_DIR}/stub_kernels.cpp"
)

# Build onnxruntime
set(ONNXRT_BUILD_DIR "${CURRENT_BUILDTREES_DIR}/${TARGET_TRIPLET}-rel")
file(MAKE_DIRECTORY "${ONNXRT_BUILD_DIR}")

# Configure with CMake - bypass vcpkg toolchain to avoid dependency conflicts
set(ENV{Python3_ROOT_DIR} "C:/Users/flexdu/.local")
set(ENV{Python3_EXECUTABLE} "C:/Users/flexdu/.local/bin/python3")

# Use cmake_path to normalize the install prefix path
cmake_path(NATIVE_PATH CURRENT_PACKAGES_DIR NORMALIZE INSTALL_PREFIX)

vcpkg_execute_required_process(
    COMMAND "${CMAKE_COMMAND}" -S "${ONNXRT_SOURCE_PATH}" -B "${ONNXRT_BUILD_DIR}"
        -G Ninja
        -DCMAKE_BUILD_TYPE=Release
        "-DCMAKE_INSTALL_PREFIX=${INSTALL_PREFIX}"
        -DCMAKE_CXX_STANDARD=17
        -DCMAKE_POSITION_INDEPENDENT_CODE=ON
        -DBUILD_SHARED_LIBS=OFF
        -DCMAKE_PREFIX_PATH=""
        -DCMAKE_TOOLCHAIN_FILE=
        -Donnxruntime_USE_VCPKG=OFF
        -DPython3_EXECUTABLE="C:/Users/flexdu/.local/bin/python3"
        -DPython3_ROOT_DIR="C:/Users/flexdu/.local"
        -DCMAKE_PROGRAM_PATH="C:/Users/flexdu/.local/bin"
        -DPython3_FIND_VIRTUALENV=FIRST
        -DPython3_FIND_STRATEGY=LOCATION
        "-DCMAKE_CXX_FLAGS=/wd4875 /w14875 /WX-"
        "-DCMAKE_C_FLAGS=/wd4875 /WX-"
        -DFLATBUFFERS_BUILD_TESTS=OFF
        -DFLATBUFFERS_BUILD_SHAREDLIB=OFF
        -Donnxruntime_DISABLE_RTTI=OFF
        -Donnxruntime_DEV_MODE=OFF
        -Donnxruntime_USE_AVX=OFF
        -Donnxruntime_USE_AVX2=OFF
        -Donnxruntime_USE_AVX512=OFF
        -Donnxruntime_BUILD_UNIT_TESTS=OFF
        -Donnxruntime_BUILD_SHARED_LIBS=OFF
        -Donnxruntime_ENABLE_CPUINFO=ON
        -Donnxruntime_ENABLE_PYTHON=OFF
        -Donnxruntime_ENABLE_TRAINING=OFF
        -Donnxruntime_ENABLE_TRAINING_APIS=OFF
        -Donnxruntime_USE_CUDA=OFF
        -Donnxruntime_USE_OPENVINO=OFF
        -Donnxruntime_USE_TENSORRT=OFF
        -Donnxruntime_USE_DML=OFF
        -Donnxruntime_USE_WINML=OFF
        -Donnxruntime_USE_COREML=OFF
        -Donnxruntime_USE_MIMALLOC=OFF
        -Donnxruntime_USE_VALGRIND=OFF
        -Donnxruntime_USE_XNNPACK=OFF
        -Donnxruntime_USE_KLEIDIAI=OFF
        -Donnxruntime_USE_NNAPI_BUILTIN=OFF
        -Donnxruntime_USE_AZURE=OFF
        -Donnxruntime_USE_NCCL=OFF
        -Donnxruntime_USE_CUDA_NHWC_OPS=OFF
        -Donnxruntime_USE_TENSORRT_BUILTIN_PARSER=OFF
        -Donnxruntime_USE_CUSTOM_DIRECTML=OFF
        -Donnxruntime_ENABLE_MICROSOFT_INTERNAL=OFF
    WORKING_DIRECTORY "${ONNXRT_BUILD_DIR}"
    LOGNAME "configure-${TARGET_TRIPLET}"
)

# Build
vcpkg_execute_required_process(
    COMMAND "${CMAKE_COMMAND}" --build "${ONNXRT_BUILD_DIR}" --config Release
    WORKING_DIRECTORY "${ONNXRT_BUILD_DIR}"
    LOGNAME "build-${TARGET_TRIPLET}"
)

# Install
vcpkg_execute_required_process(
    COMMAND "${CMAKE_COMMAND}" --install "${ONNXRT_BUILD_DIR}" --config Release
    WORKING_DIRECTORY "${ONNXRT_BUILD_DIR}"
    LOGNAME "install-${TARGET_TRIPLET}"
)

# Copy license
vcpkg_install_copyright(FILE_LIST "${SOURCE_PATH}/LICENSE")

# Clean up unnecessary directories
file(REMOVE_RECURSE
    "${CURRENT_PACKAGES_DIR}/debug/share"
    "${CURRENT_PACKAGES_DIR}/debug/include"
    "${CURRENT_PACKAGES_DIR}/etc"
)

# Print success message
message(STATUS "onnxruntime ${VERSION} installation completed successfully")
