# PDFium from source - uses GN build system with vcpkg dependencies
set(ENV{DEPOT_TOOLS_WIN_TOOLCHAIN} "0")
set(ENV{vs2025_install} "C:\\Program Files\\Microsoft Visual Studio\\18\\Community")

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

# Create python3 symlink for GN
if(VCPKG_HOST_IS_WINDOWS)
    set(PYTHON3_EXE "${PYTHON3_PATH}/python3.exe")
    if(NOT EXISTS "${PYTHON3_EXE}")
        file(COPY_FILE "${PYTHON3}" "${PYTHON3_EXE}")
    endif()
endif()

set(VCPKG_KEEP_ENV_VARS PATH;DEPOT_TOOLS_WIN_TOOLCHAIN)

# Function to fetch git dependencies (only for build system, not libraries)
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

    set(DEST_FULL "${PF_SOURCE}/${PF_DESTINATION}")
    if(EXISTS "${DEST_FULL}/.git")
        message(STATUS "Updating ${PF_DESTINATION}...")
        vcpkg_execute_required_process(
            COMMAND "${GIT}" fetch --depth 1 origin "${PF_REF}"
            WORKING_DIRECTORY "${DEST_FULL}"
            LOGNAME "pdfium-fetch-${TARGET_TRIPLET}"
        )
        vcpkg_execute_required_process(
            COMMAND "${GIT}" checkout FETCH_HEAD
            WORKING_DIRECTORY "${DEST_FULL}"
            LOGNAME "pdfium-fetch-${TARGET_TRIPLET}"
        )
    else()
        message(STATUS "Cloning ${PF_DESTINATION}...")
        vcpkg_execute_required_process(
            COMMAND "${GIT}" clone --depth 1 "${PF_URL}" "${PF_DESTINATION}"
            WORKING_DIRECTORY "${PF_SOURCE}"
            LOGNAME "pdfium-clone-${TARGET_TRIPLET}"
        )
        vcpkg_execute_required_process(
            COMMAND "${GIT}" fetch --depth 1 origin "${PF_REF}"
            WORKING_DIRECTORY "${DEST_FULL}"
            LOGNAME "pdfium-fetch-${TARGET_TRIPLET}"
        )
        vcpkg_execute_required_process(
            COMMAND "${GIT}" checkout FETCH_HEAD
            WORKING_DIRECTORY "${DEST_FULL}"
            LOGNAME "pdfium-fetch-${TARGET_TRIPLET}"
        )
    endif()
endfunction()

# Get PDFium source
vcpkg_from_git(
    OUT_SOURCE_PATH SOURCE_PATH
    URL "https://pdfium.googlesource.com/pdfium.git"
    REF "2b675cf15ab4b68bf1ed4e0511ba2479e11f1605"
    HEAD_REF main
)

message(STATUS "Fetching PDFium build system dependencies...")

# Fetch only build system dependencies (not libraries - those come from vcpkg)
pdfium_fetch(
    DESTINATION build
    URL "https://chromium.googlesource.com/chromium/src/build.git"
    REF "88f75356c47fa999a96a4655852d0e3b5646623a"
    SOURCE "${SOURCE_PATH}"
)

# Fetch buildtools
pdfium_fetch(
    DESTINATION buildtools
    URL "https://chromium.googlesource.com/chromium/src/buildtools.git"
    REF "main"
    SOURCE "${SOURCE_PATH}"
)

# Fetch jinja2 (required by build)
pdfium_fetch(
    DESTINATION third_party/jinja2
    URL "https://chromium.googlesource.com/chromium/src/third_party/jinja2.git"
    REF "b41863e42637544c2941b574c7877d3e1f663e25"
    SOURCE "${SOURCE_PATH}"
)

# Fetch markupsafe (required by jinja2)
pdfium_fetch(
    DESTINATION third_party/markupsafe
    URL "https://chromium.googlesource.com/chromium/src/third_party/markupsafe.git"
    REF "8f45f5cfa0009d2a70589bcda0349b8cb2b72783"
    SOURCE "${SOURCE_PATH}"
)

# compiler-rt is not needed - use_llvm_libatomic=false in GN args

# Fetch test_fonts (required by testing/BUILD.gn)
pdfium_fetch(
    DESTINATION third_party/test_fonts
    URL "https://chromium.googlesource.com/chromium/src/third_party/test_fonts.git"
    REF "main"
    SOURCE "${SOURCE_PATH}"
)

# Create stub for tools/win/DebugVisualizers (required by abseil)
file(MAKE_DIRECTORY "${SOURCE_PATH}/tools/win/DebugVisualizers")
file(WRITE "${SOURCE_PATH}/tools/win/DebugVisualizers/BUILD.gn" [=[
config("absl") {
  visibility = [ "*" ]
}
]=])

# Fetch freetype (required for building)
pdfium_fetch(
    DESTINATION third_party/freetype/src
    URL "https://chromium.googlesource.com/chromium/src/third_party/freetype2.git"
    REF "d2612e1c3ff839595fbf67c8263a07d6bac3aaf5"
    SOURCE "${SOURCE_PATH}"
)

# Generate LASTCHANGE files
message(STATUS "Generating build files...")
file(WRITE "${SOURCE_PATH}/build/util/LASTCHANGE" [=[
LASTCHANGE=2b675cf15ab4b68bf1ed4e0511ba2479e11f1605-
FILE_DIRECTORY=.
]=])
file(WRITE "${SOURCE_PATH}/build/util/LASTCHANGE.committime" "1717200000")
file(WRITE "${SOURCE_PATH}/build/util/LASTCHANGE.blink" [=[
LASTCHANGE=2b675cf15ab4b68bf1ed4e0511ba2479e11f1605-
FILE_DIRECTORY=.
]=])

# Write gclient_args.gni
file(WRITE "${SOURCE_PATH}/build/config/gclient_args.gni" "checkout_google_benchmark = false\n")
if(VCPKG_TARGET_IS_WINDOWS AND DEFINED ENV{WindowsSdkDir})
    string(REGEX REPLACE "[\\]\$" "" WindowsSdkDir "$ENV{WindowsSdkDir}")
    file(APPEND "${SOURCE_PATH}/build/config/gclient_args.gni" "windows_sdk_path = \"${WindowsSdkDir}\"\n")
endif()

# Create stub BUILD.gn files for vcpkg-managed dependencies
# These tell GN to use system libraries instead of bundled ones

# libjpeg_turbo stub
file(MAKE_DIRECTORY "${SOURCE_PATH}/third_party/libjpeg_turbo")
file(WRITE "${SOURCE_PATH}/third_party/libjpeg_turbo/BUILD.gn" [=[
config("libjpeg_config") {
  visibility = [ "*" ]
  include_dirs = [ "//third_party/libjpeg_turbo" ]
}

source_set("libjpeg") {
  public_configs = [ ":libjpeg_config" ]
  sources = []
}
]=])

# libpng stub
file(MAKE_DIRECTORY "${SOURCE_PATH}/third_party/libpng")
file(WRITE "${SOURCE_PATH}/third_party/libpng/BUILD.gn" [=[
import("//build/config/linux/pkg_config.gni")

pkg_config("system_libpng") {
  packages = [ "libpng" ]
}

source_set("libpng") {
  public_configs = [ ":system_libpng" ]
  sources = [ "png.h" ]
}
]=])

# zlib stub
file(MAKE_DIRECTORY "${SOURCE_PATH}/third_party/zlib")
file(WRITE "${SOURCE_PATH}/third_party/zlib/BUILD.gn" [=[
config("zlib_config") {
  visibility = [ "*" ]
  include_dirs = [ "//third_party/zlib" ]
}

source_set("zlib") {
  public_configs = [ ":zlib_config" ]
  sources = []
}
]=])

# freetype stub
file(MAKE_DIRECTORY "${SOURCE_PATH}/third_party/freetype")
file(WRITE "${SOURCE_PATH}/third_party/freetype/BUILD.gn" [=[
import("//build/config/linux/pkg_config.gni")

pkg_config("system_freetype") {
  packages = [ "freetype2" ]
}

source_set("freetype") {
  public_configs = [ ":system_freetype" ]
}
]=])

# ICU stub - use vcpkg headers
file(MAKE_DIRECTORY "${SOURCE_PATH}/third_party/icu")
file(WRITE "${SOURCE_PATH}/third_party/icu/BUILD.gn" [=[
config("icu_config") {
  visibility = [ "*" ]
  include_dirs = [
    "//third_party/icu/source/common",
    "//third_party/icu/source/i18n",
  ]
}

component("icuuc") {
  public_configs = [ ":icu_config" ]
  sources = []
}

component("icui18n") {
  public_configs = [ ":icu_config" ]
  sources = []
}
]=])

# Create ICU source directory structure with symlinks to vcpkg headers
file(MAKE_DIRECTORY "${SOURCE_PATH}/third_party/icu/source/common/unicode")
file(MAKE_DIRECTORY "${SOURCE_PATH}/third_party/icu/source/i18n/unicode")

# Copy ICU headers from vcpkg
file(GLOB ICU_HEADERS "${CURRENT_INSTALLED_DIR}/include/unicode/*.h")
foreach(ICU_HEADER ${ICU_HEADERS})
    get_filename_component(HEADER_NAME "${ICU_HEADER}" NAME)
    file(COPY_FILE "${ICU_HEADER}" "${SOURCE_PATH}/third_party/icu/source/common/unicode/${HEADER_NAME}")
endforeach()

# Copy zlib headers
file(GLOB ZLIB_HEADERS "${CURRENT_INSTALLED_DIR}/include/zlib*.h")
file(MAKE_DIRECTORY "${SOURCE_PATH}/third_party/zlib")
foreach(ZLIB_HEADER ${ZLIB_HEADERS})
    get_filename_component(HEADER_NAME "${ZLIB_HEADER}" NAME)
    file(COPY_FILE "${ZLIB_HEADER}" "${SOURCE_PATH}/third_party/zlib/${HEADER_NAME}")
endforeach()

# Copy libjpeg headers
file(GLOB JPEG_HEADERS "${CURRENT_INSTALLED_DIR}/include/jpeg*.h" "${CURRENT_INSTALLED_DIR}/include/j*.h" "${CURRENT_INSTALLED_DIR}/include/turbojpeg*.h")
file(MAKE_DIRECTORY "${SOURCE_PATH}/third_party/libjpeg_turbo")
foreach(JPEG_HEADER ${JPEG_HEADERS})
    get_filename_component(HEADER_NAME "${JPEG_HEADER}" NAME)
    file(COPY_FILE "${JPEG_HEADER}" "${SOURCE_PATH}/third_party/libjpeg_turbo/${HEADER_NAME}")
endforeach()

# Copy libpng headers
file(GLOB PNG_HEADERS "${CURRENT_INSTALLED_DIR}/include/libpng*.h" "${CURRENT_INSTALLED_DIR}/include/png*.h")
file(MAKE_DIRECTORY "${SOURCE_PATH}/third_party/libpng")
foreach(PNG_HEADER ${PNG_HEADERS})
    get_filename_component(HEADER_NAME "${PNG_HEADER}" NAME)
    file(COPY_FILE "${PNG_HEADER}" "${SOURCE_PATH}/third_party/libpng/${HEADER_NAME}")
endforeach()

# Copy openjpeg headers
file(GLOB OPJ_HEADERS "${CURRENT_INSTALLED_DIR}/include/openjpeg*.h")
file(MAKE_DIRECTORY "${SOURCE_PATH}/third_party/openjpeg")
foreach(OPJ_HEADER ${OPJ_HEADERS})
    get_filename_component(HEADER_NAME "${OPJ_HEADER}" NAME)
    file(COPY_FILE "${OPJ_HEADER}" "${SOURCE_PATH}/third_party/openjpeg/${HEADER_NAME}")
endforeach()

# openjpeg stub
file(MAKE_DIRECTORY "${SOURCE_PATH}/third_party/openjpeg")
file(WRITE "${SOURCE_PATH}/third_party/openjpeg/BUILD.gn" [=[
import("//build/config/linux/pkg_config.gni")

pkg_config("system_openjpeg") {
  packages = [ "libopenjp2" ]
}

source_set("openjpeg") {
  public_configs = [ ":system_openjpeg" ]
}
]=])

# Set GN arguments
if(VCPKG_LIBRARY_LINKAGE STREQUAL "dynamic")
    set(is_component_build true)
else()
    set(is_component_build false)
endif()

# Get vcpkg installed directory for library paths
set(VCPKG_LIB_DIR "${CURRENT_INSTALLED_DIR}/lib")
set(VCPKG_DEBUG_LIB_DIR "${CURRENT_INSTALLED_DIR}/debug/lib")
set(VCPKG_INCLUDE_DIR "${CURRENT_INSTALLED_DIR}/include")

string(JOIN " " OPTIONS
    "is_component_build=${is_component_build}"
    "target_cpu=\"${VCPKG_TARGET_ARCHITECTURE}\""
    "pdf_is_standalone=true"
    "pdf_is_complete_lib=true"
    "is_clang=false"
    "use_custom_libcxx=false"
    "use_sysroot=false"
    "pdf_use_skia=false"
    "pdf_enable_xfa=false"
    "pdf_enable_v8=false"
    "pdf_use_harfbuzz=false"
    "treat_warnings_as_errors=false"
    "use_system_freetype=true"
    "use_system_libjpeg=true"
    "use_system_libpng=true"
    "use_system_zlib=true"
    "use_system_icu=true"
    "use_system_openjpeg=true"
    "use_llvm_libatomic=false"
)

# Add include and lib paths for vcpkg dependencies
if(VCPKG_TARGET_IS_WINDOWS)
    # Convert paths for GN (use forward slashes)
    string(REPLACE "\\" "/" VCPKG_INCLUDE_DIR_GN "${VCPKG_INCLUDE_DIR}")
    string(REPLACE "\\" "/" VCPKG_LIB_DIR_GN "${VCPKG_LIB_DIR}")
    string(REPLACE "\\" "/" VCPKG_DEBUG_LIB_DIR_GN "${VCPKG_DEBUG_LIB_DIR}")
endif()

message(STATUS "Configuring PDFium with GN...")

vcpkg_gn_configure(
    SOURCE_PATH "${SOURCE_PATH}"
    OPTIONS "${OPTIONS}"
    OPTIONS_DEBUG "is_debug=true enable_iterator_debugging=true"
    OPTIONS_RELEASE "is_debug=false enable_iterator_debugging=false"
)

message(STATUS "Building PDFium...")

vcpkg_gn_install(
    SOURCE_PATH "${SOURCE_PATH}"
    TARGETS :pdfium
)

# Install headers
file(INSTALL "${SOURCE_PATH}/public/" DESTINATION "${CURRENT_PACKAGES_DIR}/include/pdfium" FILES_MATCHING PATTERN "*.h")

vcpkg_copy_pdbs()

# Install license
file(INSTALL "${SOURCE_PATH}/LICENSE" DESTINATION "${CURRENT_PACKAGES_DIR}/share/${PORT}" RENAME copyright)
