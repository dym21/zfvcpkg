#
# Copyright 2020 The TensorFlow Authors. All Rights Reserved.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#      https://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

# 
# Modification by Park DongHa (luncliff@gmail.com).
# Snapshot from https://github.com/tensorflow/tensorflow/blob/v2.7.0/tensorflow/lite/tools/cmake/modules/fft2d/CMakeLists.txt
#
# - Change default value of the cache variablaes 
# - Add install of the build targets, header files
#
cmake_minimum_required(VERSION 3.22)
project(fft2d C)

set(FFT2D_SOURCE_DIR "${PROJECT_SOURCE_DIR}" CACHE PATH
  "Directory that contains the fft2d project"
)
if(NOT FFT2D_SOURCE_DIR)
  message(FATAL_ERROR "Must specify source directory")
endif()

# fft2d doesn't have a CMake project so define it here transcribed from
# sample2d/Makefile.

# A developer should link this library if they haven't provided their own
# implementation of these allocation methods.
add_library(fft2d_alloc
  "${FFT2D_SOURCE_DIR}/alloc.c"
  "${FFT2D_SOURCE_DIR}/alloc.h"
)
target_include_directories(fft2d_alloc PRIVATE "${FFT2D_SOURCE_DIR}")

# Requires implementation of fft2d_alloc.
add_library(fft2d_fft4f2d "${FFT2D_SOURCE_DIR}/fft4f2d.c")
target_include_directories(fft2d_fft4f2d PRIVATE "${FFT2D_SOURCE_DIR}")

add_library(fft2d_fftsg "${FFT2D_SOURCE_DIR}/fftsg.c")

# Requires implementation of fft2d_alloc.
add_library(fft2d_fftsg2d "${FFT2D_SOURCE_DIR}/fftsg2d.c")
target_link_libraries(fft2d_fftsg2d fft2d_fftsg)
target_include_directories(fft2d_fftsg2d PRIVATE "${FFT2D_SOURCE_DIR}")

# Requires implementation of fft2d_alloc.
add_library(fft2d_fftsg3d "${FFT2D_SOURCE_DIR}/fftsg3d.c")
target_link_libraries(fft2d_fftsg3d fft2d_fftsg)
target_include_directories(fft2d_fftsg3d PRIVATE "${FFT2D_SOURCE_DIR}")

add_library(fft2d_shrtdct "${FFT2D_SOURCE_DIR}/shrtdct.c")

add_library(fft2d ALIAS fft2d_fftsg2d)

include(GNUInstallDirs)
install(TARGETS fft2d_alloc fft2d_fft4f2d fft2d_fftsg fft2d_fftsg2d fft2d_fftsg3d fft2d_shrtdct
        EXPORT fft2d-config
        RUNTIME DESTINATION ${CMAKE_INSTALL_BINDIR}
        LIBRARY DESTINATION ${CMAKE_INSTALL_LIBDIR}
        ARCHIVE DESTINATION ${CMAKE_INSTALL_LIBDIR}
)
install(FILES  ${FFT2D_SOURCE_DIR}/alloc.h
        DESTINATION ${CMAKE_INSTALL_INCLUDEDIR}/fft2d
)

install(EXPORT fft2d-config
        DESTINATION ${CMAKE_INSTALL_DATAROOTDIR}/fft2d
)
