#!/bin/bash -e

echo "-- Building Linux Appimage..."

export APPIMAGE_EXTRACT_AND_RUN=1
export ARCH="$(uname -m)"

SHARUN="https://raw.githubusercontent.com/pkgforge-dev/Anylinux-AppImages/refs/heads/main/useful-tools/quick-sharun.sh"
URUNTIME="https://raw.githubusercontent.com/pkgforge-dev/Anylinux-AppImages/refs/heads/main/useful-tools/uruntime2appimage.sh"
PELF="https://github.com/xplshn/pelf/releases/latest/download/pelf_$ARCH"

# merge PGO data
if [[ "${OPTIMIZE}" == "PGO" ]]; then
    cd pgo
    chmod +x ./merge.sh
    ./merge.sh 5 3 1
    cd ..
fi

cd ./eden
COUNT="$(git rev-list --count HEAD)"
DATE="$(date +"%d_%m_%Y")"

echo "-- Build Configuration:"
echo "   Target: $TARGET"
echo "   Optimization: $OPTIMIZE"
echo "   Count: $COUNT"

# hook the updater to check my repo
echo "-- Applying updater patch..."
git apply ../patches/update.patch
echo "   Done."

# fix PGO caused error?
if [[ "${OPTIMIZE}" == "PGO" ]]; then
    echo "-- Applying PGO error patch..."
    git apply ../patches/opengl.patch
    echo "   Done."
fi

# Set Base CMake flags
declare -a BASE_CMAKE_FLAGS=(
    "-DYUZU_USE_BUNDLED_QT=OFF"
    "-DYUZU_USE_BUNDLED_FFMPEG=ON"
    "-DYUZU_USE_BUNDLED_SIRIT=ON"
    "-DYUZU_USE_CPM=ON"
    "-DBUILD_TESTING=OFF"
    "-DENABLE_LTO=ON"
    "-DENABLE_QT_TRANSLATION=ON"
    "-DENABLE_UPDATE_CHECKER=ON"
    "-DUSE_DISCORD_PRESENCE=ON"
    "-DYUZU_CMD=OFF"
    "-DYUZU_ROOM=ON"
    "-DYUZU_ROOM_STANDALONE=OFF"
    "-DCMAKE_SYSTEM_PROCESSOR=$(uname -m)"
    "-DCMAKE_BUILD_TYPE=Release"
    "-DCMAKE_EXE_LINKER_FLAGS=-Wl,--as-needed"
)

# Set Extra CMake flags
declare -a EXTRA_CMAKE_FLAGS=()
case "$TARGET" in
    steamdeck)
        TARGET="Steamdeck"
        EXTRA_CMAKE_FLAGS+=(
            "-DYUZU_SYSTEM_PROFILE=steamdeck"
            "-DYUZU_USE_EXTERNAL_SDL2=ON"
        )
        
        if [[ "$OPTIMIZE" == "PGO" ]]; then
            EXTRA_CMAKE_FLAGS+=(
                "-DCMAKE_C_COMPILER=clang"
                "-DCMAKE_CXX_COMPILER=clang++"
                "-DCMAKE_C_FLAGS=-march=znver2 -mtune=znver2 -Ofast -pipe -flto=thin -fuse-ld=lld -fprofile-use=${GITHUB_WORKSPACE}/pgo/eden.profdata -fprofile-correction -w"
                "-DCMAKE_CXX_FLAGS=-march=znver2 -mtune=znver2 -Ofast -pipe -flto=thin -fuse-ld=lld -fprofile-use=${GITHUB_WORKSPACE}/pgo/eden.profdata -fprofile-correction -w"
            )
        else
            EXTRA_CMAKE_FLAGS+=(
                "-DCMAKE_C_COMPILER=gcc"
                "-DCMAKE_CXX_COMPILER=g++"
                "-DCMAKE_C_COMPILER_LAUNCHER=sccache"
                "-DCMAKE_CXX_COMPILER_LAUNCHER=sccache"
                "-DCMAKE_C_FLAGS=-march=znver2 -mtune=znver2 -Ofast -pipe -flto=auto -fuse-ld=mold -w"
                "-DCMAKE_CXX_FLAGS=-march=znver2 -mtune=znver2 -Ofast -pipe -flto=auto -fuse-ld=mold -w"
            )
        fi
    ;;
    rog)
        TARGET="ROG_ALLY"
        EXTRA_CMAKE_FLAGS+=(
            "-DYUZU_SYSTEM_PROFILE=steamdeck"
            "-DYUZU_USE_EXTERNAL_SDL2=ON"
        )

        if [[ "$OPTIMIZE" == "PGO" ]]; then
            EXTRA_CMAKE_FLAGS+=(
                "-DCMAKE_C_COMPILER=clang"
                "-DCMAKE_CXX_COMPILER=clang++"
                "-DCMAKE_C_FLAGS=-march=znver4 -mtune=znver4 -Ofast -pipe -flto=thin -fuse-ld=lld -fprofile-use=${GITHUB_WORKSPACE}/pgo/eden.profdata -fprofile-correction -w"
                "-DCMAKE_CXX_FLAGS=-march=znver4 -mtune=znver4 -Ofast -pipe -flto=thin -fuse-ld=lld -fprofile-use=${GITHUB_WORKSPACE}/pgo/eden.profdata -fprofile-correction -w"
            )
        else
            EXTRA_CMAKE_FLAGS+=(
                "-DCMAKE_C_COMPILER=gcc"
                "-DCMAKE_CXX_COMPILER=g++"
                "-DCMAKE_C_COMPILER_LAUNCHER=sccache"
                "-DCMAKE_CXX_COMPILER_LAUNCHER=sccache"
                "-DCMAKE_C_FLAGS=-march=znver4 -mtune=znver4 -Ofast -pipe -flto=auto -fuse-ld=mold -w"
                "-DCMAKE_CXX_FLAGS=-march=znver4 -mtune=znver4 -Ofast -pipe -flto=auto -fuse-ld=mold -w"
            )
        fi
    ;;
    common)
        TARGET="Common"
        EXTRA_CMAKE_FLAGS+=(
            "-DYUZU_USE_EXTERNAL_SDL2=OFF"
            "-DYUZU_USE_BUNDLED_SDL2=ON"
        )

        if [[ "$OPTIMIZE" == "PGO" ]]; then
            EXTRA_CMAKE_FLAGS+=(
                "-DCMAKE_C_COMPILER=clang"
                "-DCMAKE_CXX_COMPILER=clang++"
                "-DCMAKE_C_FLAGS=-march=x86-64-v3 -Ofast -pipe -flto=thin -fuse-ld=lld -fprofile-use=${GITHUB_WORKSPACE}/pgo/eden.profdata -fprofile-correction -w"
                "-DCMAKE_CXX_FLAGS=-march=x86-64-v3 -Ofast -pipe -flto=thin -fuse-ld=lld -fprofile-use=${GITHUB_WORKSPACE}/pgo/eden.profdata -fprofile-correction -w"
            )
        else
            EXTRA_CMAKE_FLAGS+=(
                "-DCMAKE_C_COMPILER=gcc"
                "-DCMAKE_CXX_COMPILER=g++"
                "-DCMAKE_C_COMPILER_LAUNCHER=sccache"
                "-DCMAKE_CXX_COMPILER_LAUNCHER=sccache"
                "-DCMAKE_C_FLAGS=-march=x86-64-v3 -Ofast -pipe -flto=auto -fuse-ld=mold -w"
                "-DCMAKE_CXX_FLAGS=-march=x86-64-v3 -Ofast -pipe -flto=auto -fuse-ld=mold -w"
            )
        fi
    ;;
    legacy)
        TARGET="Legacy"
        EXTRA_CMAKE_FLAGS+=(
            "-DYUZU_USE_EXTERNAL_SDL2=OFF"
            "-DYUZU_USE_BUNDLED_SDL2=ON"
        )

        if [[ "$OPTIMIZE" == "PGO" ]]; then
            EXTRA_CMAKE_FLAGS+=(
                "-DCMAKE_C_COMPILER=clang"
                "-DCMAKE_CXX_COMPILER=clang++"
                "-DCMAKE_C_FLAGS=-march=x86-64 -mtune=generic -O2 -pipe -flto=thin -fuse-ld=lld -fprofile-use=${GITHUB_WORKSPACE}/pgo/eden.profdata -fprofile-correction -w"
                "-DCMAKE_CXX_FLAGS=-march=x86-64 -mtune=generic -O2 -pipe -flto=thin -fuse-ld=lld -fprofile-use=${GITHUB_WORKSPACE}/pgo/eden.profdata -fprofile-correction -w"
            )
        else
            EXTRA_CMAKE_FLAGS+=(
                "-DCMAKE_C_COMPILER=gcc"
                "-DCMAKE_CXX_COMPILER=g++"
                "-DCMAKE_C_COMPILER_LAUNCHER=sccache"
                "-DCMAKE_CXX_COMPILER_LAUNCHER=sccache"
                "-DCMAKE_C_FLAGS=-march=x86-64 -mtune=generic -O2 -pipe -flto=auto -fuse-ld=mold -w"
                "-DCMAKE_CXX_FLAGS=-march=x86-64 -mtune=generic -O2 -pipe -flto=auto -fuse-ld=mold -w"
            )
        fi
    ;;
    aarch64)
        TARGET="Linux"
        EXTRA_CMAKE_FLAGS+=(
            "-DYUZU_USE_EXTERNAL_SDL2=OFF"
            "-DYUZU_USE_BUNDLED_SDL2=ON"
            "-DCMAKE_C_COMPILER=gcc"
            "-DCMAKE_CXX_COMPILER=g++"
            "-DCMAKE_C_COMPILER_LAUNCHER=sccache"
            "-DCMAKE_CXX_COMPILER_LAUNCHER=sccache"
            "-DCMAKE_CXX_FLAGS=-march=armv8-a -mtune=generic -Ofast -pipe -flto=auto -fuse-ld=mold -w"
            "-DCMAKE_C_FLAGS=-march=armv8-a -mtune=generic -Ofast -pipe -flto=auto -fuse-ld=mold -w"
        )
    ;;
esac

echo "-- Base CMake flags:"
for flag in "${BASE_CMAKE_FLAGS[@]}"; do
    echo "   $flag"
done

echo "-- Extra CMake Flags:"
for flag in "${EXTRA_CMAKE_FLAGS[@]}"; do
    echo "   $flag"
done

echo "-- Starting build..."
mkdir build
cd build
cmake .. -G Ninja "${BASE_CMAKE_FLAGS[@]}" "${EXTRA_CMAKE_FLAGS[@]}"
ninja
echo "-- Build Completed."

if [[ "$OPTIMIZE" == "Normal" ]]; then
    echo "-- Sccache stats:"
    sccache -s
fi

# Use sharun to generate AppDir
echo "-- Generating AppDir..."
cd ..
export ICON="$PWD"/dist/dev.eden_emu.eden.svg
export DESKTOP="$PWD"/dist/dev.eden_emu.eden.desktop
export OPTIMIZE_LAUNCH=1
export DEPLOY_OPENGL=1
export DEPLOY_VULKAN=1
export DEPLOY_QT=1
export OUTNAME="Eden-${COUNT}-${TARGET}-${OPTIMIZE}-${ARCH}.AppImage"

wget -q --retry-connrefused --tries=30 "$SHARUN" -O ./quick-sharun
chmod +x ./quick-sharun
./quick-sharun ./build/bin/eden
echo 'QT_QPA_PLATFORM=xcb' >> AppDir/.env

# Change desktop entry name to 'Eden Nightly'
sed -i 's|Name=Eden|Name=Eden Nightly|' ./AppDir/*.desktop

# Use uruntime to make appimage
echo "-- Creating AppImage..."
wget -q --retry-connrefused --tries=30 "$URUNTIME" -O ./uruntime2appimage
chmod +x ./uruntime2appimage
./uruntime2appimage

mkdir -p appimage
mv -v "${OUTNAME}" appimage/
echo "-- AppImage created: appimage/${OUTNAME}"

# Use pelf to make appbundle
echo "-- Creating AppBundle..."
wget -q --retry-connrefused --tries=30 "$PELF" -O ./pelf
chmod +x ./pelf

APPBUNDLE="Eden-${COUNT}-${TARGET}-${OPTIMIZE}-${ARCH}.dwfs.AppBundle"
ln -sfv ./AppDir/eden.svg ./AppDir/.DirIcon.svg
cp -v ../io.github.eden_emu.Eden.appdata.xml ./AppDir
./pelf --add-appdir ./AppDir --appbundle-id="Eden-${DATE}-Escary" --compression "-C zstd:level=22 -S26 -B6" --output-to "$APPBUNDLE"

mkdir -p appbundle
mv -v "${APPBUNDLE}"* appbundle/
echo "-- AppBundle created: appbundle/${APPBUNDLE}"

echo "=== ALL DONE! ==="
