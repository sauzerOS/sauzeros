# Append the current directory to module path for WASI platform support
list(APPEND CMAKE_MODULE_PATH "${CMAKE_CURRENT_LIST_DIR}")

set(CMAKE_SYSTEM_NAME WASI)
set(CMAKE_SYSTEM_VERSION 1)
set(CMAKE_SYSTEM_PROCESSOR wasm32)
set(triple wasm32-wasip1)

# 1. Setup Prefix and Suffixes
if(WIN32)
    set(WASI_HOST_EXE_SUFFIX ".exe")
else()
    set(WASI_HOST_EXE_SUFFIX "")
endif()

if(NOT WASI_SDK_PREFIX)
    # Default to /usr if not provided via -D
    set(WASI_SDK_PREFIX "/usr")
endif()

# 2. Define Compilers
set(CMAKE_C_COMPILER ${WASI_SDK_PREFIX}/bin/clang${WASI_HOST_EXE_SUFFIX})
set(CMAKE_CXX_COMPILER ${WASI_SDK_PREFIX}/bin/clang++${WASI_HOST_EXE_SUFFIX})
set(CMAKE_ASM_COMPILER ${WASI_SDK_PREFIX}/bin/clang${WASI_HOST_EXE_SUFFIX})
set(CMAKE_AR ${WASI_SDK_PREFIX}/bin/llvm-ar${WASI_HOST_EXE_SUFFIX})
set(CMAKE_RANLIB ${WASI_SDK_PREFIX}/bin/llvm-ranlib${WASI_HOST_EXE_SUFFIX})

set(CMAKE_C_COMPILER_TARGET ${triple})
set(CMAKE_CXX_COMPILER_TARGET ${triple})
set(CMAKE_ASM_COMPILER_TARGET ${triple})

# 3. Force-Sanitize Flags (Prevents -march= leakage from host)
# We use CACHE FORCE so environment CFLAGS/CXXFLAGS are ignored
set(WASI_SYSROOT "${WASI_SDK_PREFIX}/share/wasi-sysroot")
set(WASI_FLAGS "-O3 --target=${triple} --sysroot=${WASI_SYSROOT} -msimd128 -mbulk-memory")

set(CMAKE_C_FLAGS "${WASI_FLAGS}" CACHE STRING "WASI C Flags" FORCE)
set(CMAKE_CXX_FLAGS "${WASI_FLAGS}" CACHE STRING "WASI CXX Flags" FORCE)
set(CMAKE_ASM_FLAGS "${WASI_FLAGS}" CACHE STRING "WASI ASM Flags" FORCE)

# 4. Root Path Modes
set(CMAKE_FIND_ROOT_PATH ${WASI_SYSROOT})
set(CMAKE_FIND_ROOT_PATH_MODE_PROGRAM NEVER)
set(CMAKE_FIND_ROOT_PATH_MODE_LIBRARY ONLY)
set(CMAKE_FIND_ROOT_PATH_MODE_INCLUDE ONLY)
set(CMAKE_FIND_ROOT_PATH_MODE_PACKAGE ONLY)
