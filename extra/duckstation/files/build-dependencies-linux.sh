#!/usr/bin/env bash

# SPDX-FileCopyrightText: 2019-2025 Connor McLaughlin <stenzek@gmail.com>
# SPDX-License-Identifier: CC-BY-NC-ND-4.0
#
# NOTE: In addition to the terms of CC-BY-NC-ND-4.0, you may not use this file to create
# packages or build recipes without explicit permission from the copyright holder.
#

set -e

if [ "$#" -lt 1 ]; then
    echo "Syntax: $0 [-skip-download] [-skip-cleanup] [-only-download] <output directory>"
    exit 1
fi

for arg in "$@"; do
	if [ "$arg" == "-skip-download" ]; then
		echo "Not downloading sources."
		SKIP_DOWNLOAD=true
		shift
	elif [ "$arg" == "-skip-cleanup" ]; then
		echo "Not removing build directory."
		SKIP_CLEANUP=true
		shift
	elif [ "$arg" == "-only-download" ]; then
		echo "Only downloading sources."
		ONLY_DOWNLOAD=true
		shift
	fi
done

SCRIPTDIR=$(realpath $(dirname "${BASH_SOURCE[0]}"))
NPROCS="$(getconf _NPROCESSORS_ONLN)"
INSTALLDIR="$1"
if [ "${INSTALLDIR:0:1}" != "/" ]; then
	INSTALLDIR="$PWD/$INSTALLDIR"
fi

source "$SCRIPTDIR/versions"

mkdir -p deps-build
cd deps-build

if [[ "$SKIP_DOWNLOAD" != true && ! -f "libbacktrace-$LIBBACKTRACE.tar.gz" ]]; then
	curl -C - -L \
		-O "https://github.com/nih-at/libzip/releases/download/v$LIBZIP/libzip-$LIBZIP.tar.gz" \
		-o "libbacktrace-$LIBBACKTRACE.tar.gz" "https://github.com/ianlancetaylor/libbacktrace/archive/$LIBBACKTRACE.tar.gz" \
		-o "cpuinfo-$CPUINFO_COMMIT.tar.gz" "https://github.com/stenzek/cpuinfo/archive/$CPUINFO_COMMIT.tar.gz" \
		-o "discord-rpc-$DISCORD_RPC.tar.gz" "https://github.com/stenzek/discord-rpc/archive/$DISCORD_RPC.tar.gz" \
		-o "plutosvg-$PLUTOSVG.tar.gz" "https://github.com/stenzek/plutosvg/archive/$PLUTOSVG.tar.gz" \
		-o "shaderc-$SHADERC_COMMIT.tar.gz" "https://github.com/stenzek/shaderc/archive/$SHADERC_COMMIT.tar.gz" \
		-o "soundtouch-$SOUNDTOUCH.tar.gz" "https://github.com/stenzek/soundtouch/archive/$SOUNDTOUCH.tar.gz"
fi

cat > SHASUMS <<EOF
$LIBZIP_GZ_HASH  libzip-$LIBZIP.tar.gz
$LIBBACKTRACE_GZ_HASH  libbacktrace-$LIBBACKTRACE.tar.gz
$CPUINFO_GZ_HASH  cpuinfo-$CPUINFO_COMMIT.tar.gz
$DISCORD_RPC_GZ_HASH  discord-rpc-$DISCORD_RPC.tar.gz
$PLUTOSVG_GZ_HASH  plutosvg-$PLUTOSVG.tar.gz
$SHADERC_GZ_HASH  shaderc-$SHADERC_COMMIT.tar.gz
$SOUNDTOUCH_GZ_HASH  soundtouch-$SOUNDTOUCH.tar.gz
EOF

shasum -a 256 --check SHASUMS

# Have to clone with git, because it does version detection.
if [[ "$SKIP_DOWNLOAD" != true && ! -d "SPIRV-Cross" ]]; then
	git clone https://github.com/KhronosGroup/SPIRV-Cross/ -b $SPIRV_CROSS_TAG --depth 1
	if [ "$(git --git-dir=SPIRV-Cross/.git rev-parse HEAD)" != "$SPIRV_CROSS_SHA" ]; then
		echo "SPIRV-Cross version mismatch, expected $SPIRV_CROSS_SHA, got $(git rev-parse HEAD)"
		exit 1
	fi
fi

# Only downloading sources?
if [ "$ONLY_DOWNLOAD" == true ]; then
	exit 0
fi

echo "Building libbacktrace"
rm -fr "libbacktrace-$LIBBACKTRACE"
tar xf "libbacktrace-$LIBBACKTRACE.tar.gz"
cd "libbacktrace-$LIBBACKTRACE"
./configure --prefix="$INSTALLDIR" --with-pic
make
make install
cd ..

echo "Building libzip"
rm -fr "libzip-$LIBZIP"
tar xf "libzip-$LIBZIP.tar.gz"
cd "libzip-$LIBZIP"
cmake -DCMAKE_BUILD_TYPE=Release -DCMAKE_PREFIX_PATH="$INSTALLDIR" -DCMAKE_INSTALL_PREFIX="$INSTALLDIR" -B build -G Ninja \
	-DENABLE_COMMONCRYPTO=OFF -DENABLE_GNUTLS=OFF -DENABLE_MBEDTLS=OFF -DENABLE_OPENSSL=OFF -DENABLE_WINDOWS_CRYPTO=OFF \
	-DENABLE_BZIP2=OFF -DENABLE_LZMA=OFF -DENABLE_ZSTD=ON -DBUILD_SHARED_LIBS=ON -DLIBZIP_DO_INSTALL=ON \
	-DBUILD_TOOLS=OFF -DBUILD_REGRESS=OFF -DBUILD_OSSFUZZ=OFF -DBUILD_EXAMPLES=OFF -DBUILD_DOC=OFF
cmake --build build --parallel
ninja -C build install
cd ..

echo "Building shaderc"
rm -fr "shaderc-$SHADERC_COMMIT"
tar xf "shaderc-$SHADERC_COMMIT.tar.gz"
cd "shaderc-$SHADERC_COMMIT"
cmake -DCMAKE_BUILD_TYPE=Release -DCMAKE_PREFIX_PATH="$INSTALLDIR" -DCMAKE_INSTALL_PREFIX="$INSTALLDIR" -DSHADERC_SKIP_TESTS=ON -DSHADERC_SKIP_EXAMPLES=ON -DSHADERC_SKIP_COPYRIGHT_CHECK=ON -B build -G Ninja
cmake --build build --parallel
ninja -C build install
cd ..

echo "Building SPIRV-Cross"
cd SPIRV-Cross
rm -fr build
cmake -DCMAKE_BUILD_TYPE=Release -DCMAKE_PREFIX_PATH="$INSTALLDIR" -DCMAKE_INSTALL_PREFIX="$INSTALLDIR" -DSPIRV_CROSS_SHARED=ON -DSPIRV_CROSS_STATIC=OFF -DSPIRV_CROSS_CLI=OFF -DSPIRV_CROSS_ENABLE_TESTS=OFF -DSPIRV_CROSS_ENABLE_GLSL=ON -DSPIRV_CROSS_ENABLE_HLSL=OFF -DSPIRV_CROSS_ENABLE_MSL=OFF -DSPIRV_CROSS_ENABLE_CPP=OFF -DSPIRV_CROSS_ENABLE_REFLECT=OFF -DSPIRV_CROSS_ENABLE_C_API=ON -DSPIRV_CROSS_ENABLE_UTIL=ON -B build -G Ninja
cmake --build build --parallel
ninja -C build install
cd ..

echo "Building cpuinfo"
rm -fr "cpuinfo-$CPUINFO_COMMIT"
tar xf "cpuinfo-$CPUINFO_COMMIT.tar.gz"
cd "cpuinfo-$CPUINFO_COMMIT"
cmake -DCMAKE_BUILD_TYPE=Release -DCMAKE_PREFIX_PATH="$INSTALLDIR" -DCMAKE_INSTALL_PREFIX="$INSTALLDIR" -DCPUINFO_LIBRARY_TYPE=shared -DCPUINFO_RUNTIME_TYPE=shared -DCPUINFO_LOG_LEVEL=error -DCPUINFO_LOG_TO_STDIO=ON -DCPUINFO_BUILD_TOOLS=OFF -DCPUINFO_BUILD_UNIT_TESTS=OFF -DCPUINFO_BUILD_MOCK_TESTS=OFF -DCPUINFO_BUILD_BENCHMARKS=OFF -DUSE_SYSTEM_LIBS=ON -B build -G Ninja
cmake --build build --parallel
ninja -C build install
cd ..

echo "Building discord-rpc"
rm -fr "discord-rpc-$DISCORD_RPC"
tar xf "discord-rpc-$DISCORD_RPC.tar.gz"
cd "discord-rpc-$DISCORD_RPC"
cmake -DCMAKE_BUILD_TYPE=Release -DCMAKE_PREFIX_PATH="$INSTALLDIR" -DCMAKE_INSTALL_PREFIX="$INSTALLDIR" -DBUILD_SHARED_LIBS=ON -B build -G Ninja
cmake --build build --parallel
ninja -C build install
cd ..

echo "Building plutosvg"
rm -fr "plutosvg-$PLUTOSVG"
tar xf "plutosvg-$PLUTOSVG.tar.gz"
cd "plutosvg-$PLUTOSVG"
cmake -DCMAKE_BUILD_TYPE=Release -DCMAKE_PREFIX_PATH="$INSTALLDIR" -DCMAKE_INSTALL_PREFIX="$INSTALLDIR" -DBUILD_SHARED_LIBS=ON -DPLUTOSVG_ENABLE_FREETYPE=ON -DPLUTOSVG_BUILD_EXAMPLES=OFF -B build -G Ninja
cmake --build build --parallel
ninja -C build install
cd ..

echo "Building soundtouch"
rm -fr "soundtouch-$SOUNDTOUCH"
tar xf "soundtouch-$SOUNDTOUCH.tar.gz"
cd "soundtouch-$SOUNDTOUCH"
cmake -DCMAKE_BUILD_TYPE=Release -DCMAKE_PREFIX_PATH="$INSTALLDIR" -DCMAKE_INSTALL_PREFIX="$INSTALLDIR" -DCMAKE_INTERPROCEDURAL_OPTIMIZATION=ON -B build -G Ninja
cmake --build build --parallel
ninja -C build install
cd ..

if [ "$SKIP_CLEANUP" != true ]; then
	echo "Cleaning up"
	cd ..
	rm -fr deps-build
fi
