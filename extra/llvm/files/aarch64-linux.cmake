# aarch64-linux.cmake

set(CMAKE_SYSTEM_NAME Linux)
set(CMAKE_SYSTEM_PROCESSOR aarch64)

set(CMAKE_C_COMPILER aarch64-linux-gnu-gcc)
set(CMAKE_CXX_COMPILER aarch64-linux-gnu-g++)

set(CMAKE_SYSROOT /usr/aarch64-linux-gnu)
set(CMAKE_FIND_ROOT_PATH /usr/aarch64-linux-gnu)

# Force CMake to use the sysroot for compiler tests
set(CMAKE_SYSROOT_COMPILE /usr/aarch64-linux-gnu)

# NEVER look in host paths for libraries or headers
set(CMAKE_FIND_ROOT_PATH_MODE_PROGRAM NEVER)
set(CMAKE_FIND_ROOT_PATH_MODE_LIBRARY ONLY)
set(CMAKE_FIND_ROOT_PATH_MODE_INCLUDE ONLY)
set(CMAKE_FIND_ROOT_PATH_MODE_PACKAGE ONLY)

# Force the NATIVE build to use the host's actual native compiler
set(BUILD_SHARED_LIBS OFF)
set(LLVM_USE_HOST_TOOLS ON)

# Pass the sysroot explicitly to the compiler calls
set(CMAKE_C_FLAGS "--sysroot=/usr/aarch64-linux-gnu" CACHE STRING "" FORCE)
set(CMAKE_CXX_FLAGS "--sysroot=/usr/aarch64-linux-gnu" CACHE STRING "" FORCE)
set(CMAKE_CXX_IMPLICIT_INCLUDE_DIRECTORIES "")

set(Python3_EXECUTABLE "/usr/bin/python3" CACHE FILEPATH "" FORCE)
