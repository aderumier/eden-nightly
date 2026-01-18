#!/bin/sh
set -ex

case "$TARGET" in
  FreeBSD)
    pkg install -y autoconf bash boost-libs catch2 ccache cmake ffmpeg gcc gmake git glslang libfmt libzip nasm\
                ninja openssl opus pkgconf pcre2 qt6-base qt6ct qt6-tools qt6-translations qt6-wayland sdl2 unzip vulkan-tools vulkan-loader wget zip zstd
    ;;
  Solaris)
    pkg install git cmake developer/gcc-14 developer/build/ninja developer/build/gnu-make developer/build/autoconf \
                qt6 libzip libusb-1 zlib compress/zstd unzip pkg-config nasm mesa library/libdrm

    # build ccache from source
    git clone --depth 1 --branch v4.0 https://github.com/ccache/ccache.git
    cd ccache
    cmake -B build \
      -DCMAKE_BUILD_TYPE=Release \
      -DCMAKE_INSTALL_PREFIX=/usr/local \
      -DENABLE_TESTING=OFF \
      -DCMAKE_C_FLAGS="-w" \
      -DCMAKE_CXX_FLAGS="-w" \
      -G Ninja
    cmake --build build
    sudo cmake --install build
    cd ..
    rm -rf ccache
    export PATH="/usr/local/bin:$PATH"

    # build glslang from source
    git clone --depth 1 https://github.com/KhronosGroup/glslang.git
    cd glslang
    cmake -B build \
      -DCMAKE_BUILD_TYPE=Release \
      -DCMAKE_INSTALL_PREFIX=/usr/local \
      -DENABLE_OPT=OFF \
      -DCMAKE_C_COMPILER_LAUNCHER=ccache \
      -DCMAKE_CXX_COMPILER_LAUNCHER=ccache \
      -G Ninja
    cmake --build build
    sudo cmake --install build
    cd ..
    rm -rf glslang
    ;;
esac
