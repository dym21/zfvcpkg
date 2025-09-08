# libemf vcpkg Port

这是为libemf 1.0.13创建的vcpkg port文件。

## 文件结构

```
ports/libemf/
├── vcpkg.json              # 包定义文件
├── portfile.cmake          # 构建脚本
├── usage                   # 使用说明
├── CMakeLists.txt          # CMake构建文件（备用）
├── libemf-config.cmake.in  # CMake配置文件模板
└── README.md              # 本文档
```

## 功能特性

- **静态库构建**：默认构建静态库 `libEMF.a`
- **头文件安装**：安装 `libEMF/emf.h` 等头文件
- **工具支持**：包含 `printemf` 工具
- **跨平台支持**：支持Linux、Windows等平台
- **autotools构建**：使用原生autotools构建系统

## 安装方法

```bash
# 安装基本库
vcpkg install libemf

# 安装带工具的版本
vcpkg install libemf[tools]
```

## 使用方法

### CMake项目
```cmake
find_package(libemf REQUIRED)
target_link_libraries(your_target PRIVATE libemf::libemf)
```

### 直接链接
```cmake
target_link_libraries(your_target PRIVATE ${VCPKG_INSTALLED_DIR}/lib/libEMF.a)
target_include_directories(your_target PRIVATE ${VCPKG_INSTALLED_DIR}/include)
```

## 构建配置

- **版本**：1.0.13
- **许可证**：LGPL-2.1
- **构建系统**：autotools
- **默认选项**：
  - `--enable-static`：构建静态库
  - `--disable-shared`：不构建动态库
  - `--enable-debug`：启用调试功能
  - `--enable-editing`：启用编辑功能

## 测试状态

✅ 在x64-linux平台上测试通过
✅ 成功构建静态库
✅ 成功安装头文件
✅ 成功安装工具

## 注意事项

1. libemf主要用于Windows EMF文件格式支持
2. 建议使用静态链接以获得更好的兼容性
3. 工具功能需要额外的依赖（如libpng）
4. 该库在非Windows平台上主要用于读取EMF文件

## 依赖关系

- **构建依赖**：vcpkg-cmake, vcpkg-cmake-config
- **可选依赖**：libpng（用于工具功能）
