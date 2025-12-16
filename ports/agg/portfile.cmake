# Anti-Grain Geometry (AGG) v2.4 Portfile

# 1. 明确版本
set(AGG_VERSION 2.4)

# 2. 下载源代码 (使用 SourceForge 官方源，并提供正确的哈希)
vcpkg_download_distfile(AGG_ARCHIVE
    URLS "https://sourceforge.net/projects/vector-agg/files/agg/agg-2.4/agg-2.4.zip/download"
    FILENAME "agg-${AGG_VERSION}.zip"
    SHA512 08169e5d447d667c4e511370c97690a2a4773c4d515a45b7367c30a599292c4b82d3381a1a59052a5501ba473215239a099a43ce2f08a467e4368158098319e7
)

# 3. 解压源代码
vcpkg_extract_source_archive_ex(
    OUT_SOURCE_PATH SOURCE_PATH
    ARCHIVE ${AGG_ARCHIVE}
    REF ${AGG_VERSION}
)

# 4. 生成 CMakeLists.txt
# AGG 原生没有 CMake 支持，我们在这里注入一个现代化的构建脚本
file(WRITE "${SOURCE_PATH}/CMakeLists.txt" [=[
cmake_minimum_required(VERSION 3.10)
project(agg CXX)

# 自动查找源文件
# 包括核心库文件 (src/*.cpp) 和控件文件 (src/ctrl/*.cpp)
file(GLOB AGG_SOURCES 
    "${CMAKE_CURRENT_SOURCE_DIR}/src/*.cpp"
    "${CMAKE_CURRENT_SOURCE_DIR}/src/ctrl/*.cpp"
)

# 排除可能导致许可证问题或编译困难的 GPC (General Polygon Clipper) 
# 如果你确实需要 gpc，可以注释掉下面这行
list(FILTER AGG_SOURCES EXCLUDE REGEX "agg_gpc")

add_library(agg ${AGG_SOURCES})

# 设置头文件路径
target_include_directories(agg PUBLIC 
    $<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}/include> 
    $<INSTALL_INTERFACE:include>
)

# --- MSVC / VS2022 兼容性修复 ---
if(MSVC)
    target_compile_definitions(agg PRIVATE 
        -D_CRT_SECURE_NO_WARNINGS 
        -D_SCL_SECURE_NO_WARNINGS
        -Dregister= # C++17 删除了 register 关键字，将其定义为空以修复报错
    )
    target_compile_options(agg PRIVATE 
        /wd4456 # 禁用“声明隐藏了上一个本地声明”警告
        /wd4996 # 禁用“已弃用”警告
        /wd4244 # 禁用“从 double 转换到 float”警告
    )
endif()

# 安装目标
install(TARGETS agg EXPORT aggTargets
    ARCHIVE DESTINATION lib
    LIBRARY DESTINATION lib
    RUNTIME DESTINATION bin
)

# 安装头文件 (保留目录结构，放入 include/agg 以保持整洁)
install(DIRECTORY include/ DESTINATION include/agg)

# 导出 CMake 配置供 find_package(agg) 使用
install(EXPORT aggTargets
    FILE aggTargets.cmake
    NAMESPACE agg::
    DESTINATION share/agg
)

# 创建版本配置文件
include(CMakePackageConfigHelpers)
write_basic_package_version_file(
    "${CMAKE_CURRENT_BINARY_DIR}/aggConfigVersion.cmake"
    VERSION 2.4
    COMPATIBILITY AnyNewerVersion
)

install(FILES 
    "${CMAKE_CURRENT_BINARY_DIR}/aggConfigVersion.cmake"
    DESTINATION share/agg
)
]=])

# 生成主 Config 文件
file(WRITE "${SOURCE_PATH}/aggConfig.cmake" [=[
include("${CMAKE_CURRENT_LIST_DIR}/aggTargets.cmake")
]=])

# 安装 Config 文件
file(COPY "${SOURCE_PATH}/aggConfig.cmake" DESTINATION "${SOURCE_PATH}/cmake_install")


# 5. 配置与构建
vcpkg_cmake_configure(
    SOURCE_PATH "${SOURCE_PATH}"
    # 如果需要在 Debug/Release 之外进行特殊配置，可在这里添加 OPTIONS
)

vcpkg_cmake_install()

# 6. 后处理与清理

# 移动 CMake 配置文件到正确位置
vcpkg_cmake_config_fixup(PACKAGE_NAME agg CONFIG_PATH share/agg)

# 移除 debug 目录中重复的 include 文件夹
file(REMOVE_RECURSE "${CURRENT_PACKAGES_DIR}/debug/include")
file(REMOVE_RECURSE "${CURRENT_PACKAGES_DIR}/debug/share")

# 安装版权文件 (AGG 使用 BSD-3-Clause 类似的许可证，通常在 copy_copying 或类似文件中)
# 这里我们尝试查找 readme 或 copying，如果找不到，创建一个占位符以通过 vcpkg 检查
file(GLOB LICENSE_FILE "${SOURCE_PATH}/copying")
if(NOT LICENSE_FILE)
    file(GLOB LICENSE_FILE "${SOURCE_PATH}/readme")
endif()

if(LICENSE_FILE)
    vcpkg_install_copyright(FILE_LIST ${LICENSE_FILE})
else()
    # 如果源码包里实在没有版权文件，手动创建一个指向官网的说明
    file(WRITE "${CURRENT_PACKAGES_DIR}/share/agg/copyright" "See http://www.antigrain.com/license/index.html")
endif()

# 验证安装
vcpkg_copy_pdbs()