#!/bin/bash -e

echo "Making Eden for MacOS"
export LIBVULKAN_PATH="/opt/homebrew/lib/libvulkan.1.dylib"

cd ./eden

# hook the updater to check my repo
echo "-- Applying updater patch..."
git apply ../patches/update.patch
# display changelog
git apply ../patches/changelog.patch
echo "   Done."

COUNT="$(git rev-list --count HEAD)"
APP_NAME="Eden-${COUNT}-MacOS-${TARGET}"
echo "-- Build Configuration:"
echo "   Target: ${TARGET}"
echo "   Count: ${COUNT}"
echo "   App Name: ${APP_NAME}"

echo "-- Starting build..."
mkdir -p build
cd build
cmake .. -GNinja \
    -DYUZU_USE_BUNDLED_QT=ON \
    -DYUZU_USE_BUNDLED_SIRIT=ON \
    -DYUZU_USE_BUNDLED_MOLTENVK=ON \
    -DYUZU_STATIC_BUILD=ON \
    -DYUZU_USE_CPM=ON \
    -DBUILD_TESTING=OFF \
    -DENABLE_QT_TRANSLATION=ON \
    -DENABLE_UPDATE_CHECKER=ON \
    -DENABLE_LTO=ON \
    -DUSE_DISCORD_PRESENCE=OFF \
    -DYUZU_CMD=OFF \
    -DYUZU_ROOM_STANDALONE=OFF \
    -DCMAKE_CXX_FLAGS="-w" \
    -DCMAKE_BUILD_TYPE=Release \
    -DCMAKE_C_COMPILER_LAUNCHER=sccache \
    -DCMAKE_CXX_COMPILER_LAUNCHER=sccache
ninja
echo "-- Build Completed."

echo "-- Build stats:"
sccache -s

# Bundle and code-sign eden.app
echo "-- Code-signing Eden.app..."
APP=./bin/eden.app
codesign --deep --force --verify --verbose --sign - "$APP"

# Pack for upload
echo "-- Packing build artifacts..."
mkdir -p artifacts
mkdir "$APP_NAME"
cp -a ./bin/. "$APP_NAME"
ZIP_NAME="$APP_NAME.zip"
7z a -tzip -mx=9 "$ZIP_NAME" "$APP_NAME"
mv -v "$ZIP_NAME" artifacts/

echo "=== ALL DONE! ==="
