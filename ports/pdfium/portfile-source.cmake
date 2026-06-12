# PDFium 从源码编译版本
# 注意：需要能够访问 googlesource.com，且构建时间较长（1-2小时）
# 使用方法：将此文件重命名为 portfile.cmake 替换预编译版本

# PDFium uses GN build system from Chromium
set(ENV{DEPOT_TOOLS_WIN_TOOLCHAIN} 0)

# Find required tools
vcpkg_find_acquire_program(PYTHON3)
get_filename_component(PYTHON3_PATH "${PYTHON3}" DIRECTORY)
vcpkg_find_acquire_program(GN)
get_filename_component(GN_PATH "${GN}" DIRECTORY)
vcpkg_find_acquire_program(NINJA)
get_filename_component(NINJA_PATH "${NINJA}" DIRECTORY)

vcpkg_add_to_path(PREPEND "${PYTHON3_PATH}")
vcpkg_add_to_path(PREPEND "${GN_PATH}")
vcpkg_add_to_path(PREPEND "${NINJA_PATH}")

set(VCPKG_KEEP_ENV_VARS PATH;DEPOT_TOOLS_WIN_TOOLCHAIN)

# Function to fetch git dependencies
function(pdfium_fetch)
    set(oneValueArgs DESTINATION URL REF SOURCE)
    cmake_parse_arguments(PF "" "${oneValueArgs}" "" ${ARGN})

    if(NOT DEFINED PF_DESTINATION)
        message(FATAL_ERROR "DESTINATION must be specified.")
    endif()
    if(NOT DEFINED PF_URL)
        message(FATAL_ERROR "URL must be specified.")
    endif()
    if(NOT DEFINED PF_REF)
        message(FATAL_ERROR "REF must be specified.")
    endif()

    if(EXISTS "${PF_SOURCE}/${PF_DESTINATION}")
        vcpkg_execute_required_process(
            COMMAND "${GIT}" reset --hard
            WORKING_DIRECTORY "${PF_SOURCE}/${PF_DESTINATION}"
            LOGNAME "pdfium-fetch-${TARGET_TRIPLET}"
        )
    else()
        vcpkg_execute_required_process(
            COMMAND "${GIT}" clone --depth 1 "${PF_URL}" "${PF_DESTINATION}"
            WORKING_DIRECTORY "${PF_SOURCE}"
            LOGNAME "pdfium-fetch-${TARGET_TRIPLET}"
        )
        vcpkg_execute_required_process(
            COMMAND "${GIT}" fetch --depth 1 origin "${PF_REF}"
            WORKING_DIRECTORY "${PF_SOURCE}/${PF_DESTINATION}"
            LOGNAME "pdfium-fetch-${TARGET_TRIPLET}"
        )
        vcpkg_execute_required_process(
            COMMAND "${GIT}" checkout FETCH_HEAD
            WORKING_DIRECTORY "${PF_SOURCE}/${PF_DESTINATION}"
            LOGNAME "pdfium-fetch-${TARGET_TRIPLET}"
        )
    endif()
endfunction()

# Get PDFium source - 使用 chromium/6723 分支
vcpkg_from_git(
    OUT_SOURCE_PATH SOURCE_PATH
    URL "https://pdfium.googlesource.com/pdfium.git"
    REF "chromium/6723"
    HEAD_REF main
)

message(STATUS "Fetching PDFium dependencies...")

# Fetch Chromium build system
pdfium_fetch(
    DESTINATION build
    URL "https://chromium.googlesource.com/chromium/src/build.git"
    REF "main"
    SOURCE "${SOURCE_PATH}"
)

# Fetch zlib
pdfium_fetch(
    DESTINATION third_party/zlib
    URL "https://chromium.googlesource.com/chromium/src/third_party/zlib.git"
    REF "main"
    SOURCE "${SOURCE_PATH}"
)

# Fetch ICU
pdfium_fetch(
    DESTINATION third_party/icu
    URL "https://chromium.googlesource.com/chromium/deps/icu.git"
    REF "main"
    SOURCE "${SOURCE_PATH}"
)

# Fetch abseil-cpp
pdfium_fetch(
    DESTINATION third_party/abseil-cpp
    URL "https://chromium.googlesource.com/chromium/src/third_party/abseil-cpp.git"
    REF "main"
    SOURCE "${SOURCE_PATH}"
)

# Fetch jinja2 (required by build)
pdfium_fetch(
    DESTINATION third_party/jinja2
    URL "https://chromium.googlesource.com/chromium/src/third_party/jinja2.git"
    REF "main"
    SOURCE "${SOURCE_PATH}"
)

# Fetch markupsafe (required by jinja2)
pdfium_fetch(
    DESTINATION third_party/markupsafe
    URL "https://chromium.googlesource.com/chromium/src/third_party/markupsafe.git"
    REF "main"
    SOURCE "${SOURCE_PATH}"
)

# Generate LASTCHANGE file
vcpkg_execute_required_process(
    COMMAND "${PYTHON3}" build/util/lastchange.py -o build/util/LASTCHANGE
    WORKING_DIRECTORY "${SOURCE_PATH}"
    LOGNAME "pdfium-lastchange-${TARGET_TRIPLET}"
)

# Write gclient_args.gni
file(WRITE "${SOURCE_PATH}/build/config/gclient_args.gni" "checkout_google_benchmark = false\n")
if(VCPKG_TARGET_IS_WINDOWS AND DEFINED ENV{WindowsSdkDir})
    string(REGEX REPLACE "[\\]\$" "" WindowsSdkDir "$ENV{WindowsSdkDir}")
    file(APPEND "${SOURCE_PATH}/build/config/gclient_args.gni" "windows_sdk_path = \"${WindowsSdkDir}\"\n")
endif()

# Set GN arguments
if(VCPKG_LIBRARY_LINKAGE STREQUAL "dynamic")
    set(is_component_build true)
else()
    set(is_component_build false)
endif()

string(JOIN " " OPTIONS
    "is_component_build=${is_component_build}"
    "target_cpu=\"${VCPKG_TARGET_ARCHITECTURE}\""
    "pdf_is_standalone=true"
    "is_clang=false"
    "use_custom_libcxx=false"
    "use_sysroot=false"
    "pdf_use_skia=false"
    "pdf_enable_xfa=false"
    "pdf_enable_v8=false"
    "pdf_use_harfbuzz=false"
    "treat_warnings_as_errors=false"
    "icu_use_data_file=false"
)

message(STATUS "Generating PDFium build files...")

vcpkg_gn_configure(
    SOURCE_PATH "${SOURCE_PATH}"
    OPTIONS "${OPTIONS}"
    OPTIONS_DEBUG "is_debug=true enable_iterator_debugging=true"
    OPTIONS_RELEASE "is_debug=false enable_iterator_debugging=false"
)

message(STATUS "Building PDFium (this may take 1-2 hours)...")

vcpkg_gn_install(
    SOURCE_PATH "${SOURCE_PATH}"
    TARGETS :pdfium
)

# Install headers
file(INSTALL "${SOURCE_PATH}/public" DESTINATION "${CURRENT_PACKAGES_DIR}/include" FILES_MATCHING PATTERN "*.h")
if(EXISTS "${CURRENT_PACKAGES_DIR}/include/public")
    file(RENAME "${CURRENT_PACKAGES_DIR}/include/public" "${CURRENT_PACKAGES_DIR}/include/pdfium")
endif()

vcpkg_copy_pdbs()

# Install license
file(INSTALL "${SOURCE_PATH}/LICENSE" DESTINATION "${CURRENT_PACKAGES_DIR}/share/${PORT}" RENAME copyright)
