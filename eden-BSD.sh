#!/usr/bin/env bash

set -ex

export ARCH="amd64"

cd ./eden
git config --global --add safe.directory .
COUNT="$(git rev-list --count HEAD)"

declare -a EXTRA_CMAKE_FLAGS=()
if [ "$TARGET" = "Solaris" ]; then
    git apply ../patches/solaris.patch
    
    export PKG_CONFIG_PATH=/usr/lib/64/pkgconfig:/usr/lib/pkgconfig
    export PATH="/usr/local/bin:$PATH"

    EXTRA_CMAKE_FLAGS+=(
      "-DYUZU_USE_EXTERNAL_SDL2=ON"
      "-DENABLE_QT=OFF"
      "-DYUZU_CMD=ON"
      "-DCMAKE_C_COMPILER=gcc"
      "-DCMAKE_CXX_COMPILER=g++"
      "-DCMAKE_C_FLAGS=-pthreads -DBOOST_DISABLE_WIN32 -w"
      "-DCMAKE_CXX_FLAGS=-pthreads -DBOOST_DISABLE_WIN32 -w"
    )
elif [ "$TARGET" = "FreeBSD" ]; then
    # hook the updater to check my repo
    git apply ../patches/update.patch
    # display changelog
    git apply ../patches/changelog.patch

    EXTRA_CMAKE_FLAGS+=(
      "-DENABLE_LTO=ON"
      "-DYUZU_CMD=OFF"
      "-DYUZU_USE_BUNDLED_QT=OFF"
      "-DYUZU_USE_BUNDLED_SDL2=ON"
      "-DENABLE_QT_TRANSLATION=ON"
      "-DENABLE_UPDATE_CHECKER=ON"
      "-DCMAKE_CXX_FLAGS=-march=x86-64-v3 -mtune=generic -O3 -pipe"
      "-DCMAKE_C_FLAGS=-march=x86-64-v3 -mtune=generic -O3 -pipe"
    )
fi

mkdir -p build
cd build
cmake .. -GNinja \
    -DBUILD_TESTING=OFF \
    -DYUZU_USE_BUNDLED_SIRIT=ON \
    -DYUZU_USE_BUNDLED_OPENSSL=ON \
    -DYUZU_USE_CPM=ON \
    -DUSE_DISCORD_PRESENCE=OFF \
    -DYUZU_ROOM_STANDALONE=OFF \
    -DCMAKE_BUILD_TYPE=Release \
    -DCMAKE_SYSTEM_PROCESSOR="$ARCH" \
    -DCMAKE_C_COMPILER_LAUNCHER=ccache \
    -DCMAKE_CXX_COMPILER_LAUNCHER=ccache \
    "${EXTRA_CMAKE_FLAGS[@]}"
ninja

ccache -s

# Create base pkg dir
PKG_NAME="Eden-${COUNT}-${TARGET}-${ARCH}"
DESTDIR="${PKG_NAME}" ninja install
PKG_DIR="${PKG_NAME}/usr/local"

if [ -f "${PKG_DIR}/bin/eden" ]; then
    EDEN_PATH="${PKG_DIR}/bin/eden"
    
    # Copy all linked libs
    ldd "$EDEN_PATH" | awk '/=>/ {print $3}' | while read -r lib; do
      case "$lib" in
        /lib*|/usr/lib*) ;;  # Skip system libs
        *)
          if echo "$lib" | grep -q '^/usr/local/lib/qt6/'; then
            mkdir -p "${PKG_DIR}/lib/qt6"
            cp "$lib" "${PKG_DIR}/lib/qt6/"
          else
            mkdir -p "${PKG_DIR}/lib/"
            cp "$lib" "${PKG_DIR}/lib/"
          fi
          ;;
      esac
    done

    # Copy Qt6 plugins
    QT6_PLUGINS="/usr/local/lib/qt6/plugins"
    QT6_PLUGIN_SUBDIRS="
    imageformats
    iconengines
    platforms
    platformthemes
    platforminputcontexts
    styles
    xcbglintegrations
    wayland-decoration-client
    wayland-graphics-integration-client
    wayland-graphics-integration
    wayland-shell-integration
    "

    for sub in $QT6_PLUGIN_SUBDIRS; do
      if [ -d "${QT6_PLUGINS}/${sub}" ]; then
        mkdir -p "${PKG_DIR}/lib/qt6/plugins/${sub}"
        cp -r "${QT6_PLUGINS}/${sub}"/* "${PKG_DIR}/lib/qt6/plugins/${sub}/"
      fi
    done

    # Strip binaries
    strip "$EDEN_PATH"
    find "${PKG_DIR}/lib" -type f -name '*.so*' -exec strip {} \;

  # Create a launcher for the pack
  cp -v ../../launch.sh "${PKG_NAME}"
  chmod +x "${PKG_NAME}/launch.sh"

fi

# Pack for upload
tar -czf "${PKG_NAME}.tar.gz" "${PKG_NAME}"
mkdir -p artifacts
mv "${PKG_NAME}.tar.gz" artifacts

echo "Build completed successfully."
