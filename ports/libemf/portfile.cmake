# 下载libemf源码包
vcpkg_download_distfile(ARCHIVE
    URLS "https://sourceforge.net/projects/libemf/files/libemf/1.0.13/libemf-1.0.13.tar.gz/download"
    FILENAME "libemf-1.0.13.tar.gz"
    SHA512 0  # 需要计算实际的SHA512值
)

# 解压源码
vcpkg_extract_source_archive(
    SOURCE_PATH
    ARCHIVE "${ARCHIVE}"
)

# 检查是否需要构建工具
vcpkg_check_features(OUT_FEATURE_OPTIONS FEATURE_OPTIONS
    FEATURES
        tools BUILD_TOOLS
)

# 设置autotools环境变量
set(ENV{CC} "${VCPKG_DETECTED_CMAKE_C_COMPILER}")
set(ENV{CXX} "${VCPKG_DETECTED_CMAKE_CXX_COMPILER}")

# 根据链接类型设置autotools选项
if(VCPKG_LIBRARY_LINKAGE STREQUAL "static")
    set(SHARED_STATIC --disable-shared --enable-static)
else()
    set(SHARED_STATIC --enable-shared --disable-static)
endif()

# 使用autotools配置
vcpkg_configure_make(
    SOURCE_PATH "${SOURCE_PATH}"
    OPTIONS
        ${SHARED_STATIC}
        --enable-debug
        --enable-editing
        --prefix=${CURRENT_INSTALLED_DIR}
)

# 构建和安装
vcpkg_install_make()

# 安装使用说明文件
file(INSTALL "${CMAKE_CURRENT_LIST_DIR}/usage" DESTINATION "${CURRENT_PACKAGES_DIR}/share/${PORT}")

# 处理版权信息
vcpkg_install_copyright(FILE_LIST "${SOURCE_PATH}/COPYING")

# 修复pkg-config文件
vcpkg_fixup_pkgconfig()

# 清理调试版本中不需要的文件
file(REMOVE_RECURSE "${CURRENT_PACKAGES_DIR}/debug/include")
file(REMOVE_RECURSE "${CURRENT_PACKAGES_DIR}/debug/share")

# 如果构建了工具，复制到tools目录
if("tools" IN_LIST FEATURES)
    vcpkg_copy_tools(TOOL_NAMES emf2svg emf2eps DESTINATION "${CURRENT_PACKAGES_DIR}/tools" AUTO_CLEAN)
endif()
