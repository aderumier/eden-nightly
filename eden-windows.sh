#!/bin/bash -e

echo "-- Building Eden for Windows..."

# merge PGO data
if [[ "${OPTIMIZE}" == "PGO" ]]; then
    cd pgo
    chmod +x ./merge.sh
    ./merge.sh 5 3 1
    cd ..
fi

cd ./eden
COUNT="$(git rev-list --count HEAD)"

if [[ "${OPTIMIZE}" == "PGO" ]]; then
    EXE_NAME="Eden-${COUNT}-Windows-${TOOLCHAIN}-PGO-${ARCH}"
else
    EXE_NAME="Eden-${COUNT}-Windows-${TOOLCHAIN}-${ARCH}"
fi

echo "-- Build Configuration:"
echo "   Toolchain: ${TOOLCHAIN}"
echo "   Optimization: $OPTIMIZE"
echo "   Architecture: ${ARCH}"
echo "   Count: ${COUNT}"
echo "   EXE Name: ${EXE_NAME}"

# hook the updater to check my repo
echo "-- Applying updater patch..."
patch -p1 < ../patches/update.patch
echo "   Done."

# Set Base CMake flags
declare -a BASE_CMAKE_FLAGS=(
    "-DBUILD_TESTING=OFF"
    "-DYUZU_USE_BUNDLED_QT=ON"
    "-DYUZU_STATIC_BUILD=ON"
    "-DYUZU_USE_BUNDLED_FFMPEG=ON"
    "-DENABLE_QT_TRANSLATION=ON"
    "-DENABLE_UPDATE_CHECKER=ON"
    "-DUSE_DISCORD_PRESENCE=ON"
    "-DYUZU_CMD=OFF"
    "-DYUZU_ROOM=ON"
    "-DYUZU_ROOM_STANDALONE=OFF"
    "-DCMAKE_BUILD_TYPE=Release"
)

# Set Extra CMake flags
declare -a EXTRA_CMAKE_FLAGS=()
case "${TOOLCHAIN}" in
    Clang)
        if [[ "${OPTIMIZE}" == "PGO" ]]; then
            EXTRA_CMAKE_FLAGS+=(
                "-DCMAKE_C_COMPILER=clang-cl"
                "-DCMAKE_CXX_COMPILER=clang-cl"
                "-DCMAKE_CXX_FLAGS=-Ofast -DNOMINMAX -fprofile-use=${GITHUB_WORKSPACE}/pgo/eden.profdata -Wno-backend-plugin -Wno-profile-instr-unprofiled -Wno-profile-instr-out-of-date"
                "-DCMAKE_C_FLAGS=-Ofast -DNOMINMAX -fprofile-use=${GITHUB_WORKSPACE}/pgo/eden.profdata -Wno-backend-plugin -Wno-profile-instr-unprofiled -Wno-profile-instr-out-of-date"
            )
        else
            EXTRA_CMAKE_FLAGS+=(
                "-DCMAKE_C_COMPILER=clang-cl"
                "-DCMAKE_CXX_COMPILER=clang-cl"
                "-DCMAKE_CXX_FLAGS=-Ofast -DNOMINMAX"
                "-DCMAKE_C_FLAGS=-Ofast -DNOMINMAX"
                "-DCMAKE_C_COMPILER_LAUNCHER=sccache"
                "-DCMAKE_CXX_COMPILER_LAUNCHER=sccache"
            )
        fi
    ;;
    MSYS2)
        case "$ARCH" in
            x86_64)
                ARCH_FLAGS="-march=x86-64-v3 -mtune=generic"
            ;;
            arm64)
                ARCH_FLAGS="-march=armv8-a -mtune=generic"
            ;;
        esac
        
        if [[ "${OPTIMIZE}" == "PGO" ]]; then
            EXTRA_CMAKE_FLAGS+=(
                "-DYUZU_DISABLE_LLVM=ON"
                "-DCMAKE_C_COMPILER=clang"
                "-DCMAKE_CXX_COMPILER=clang++"
                "-DCMAKE_CXX_FLAGS=${ARCH_FLAGS} -fuse-ld=lld -fprofile-use=${GITHUB_WORKSPACE}/pgo/eden.profdata -fprofile-correction -w"
                "-DCMAKE_C_FLAGS=${ARCH_FLAGS} -fuse-ld=lld -fprofile-use=${GITHUB_WORKSPACE}/pgo/eden.profdata -fprofile-correction -w"
            )
        else
            EXTRA_CMAKE_FLAGS+=(
                "-DYUZU_DISABLE_LLVM=ON"
                "-DCMAKE_CXX_FLAGS=${ARCH_FLAGS} -O3 -w"
                "-DCMAKE_C_FLAGS=${ARCH_FLAGS} -O3 -w"
                "-DCMAKE_C_COMPILER_LAUNCHER=sccache"
                "-DCMAKE_CXX_COMPILER_LAUNCHER=sccache"
            )
        fi
    ;;
    MSVC)
        EXTRA_CMAKE_FLAGS+=(
        "-DENABLE_LTO=OFF"
        "-DCMAKE_C_COMPILER_LAUNCHER=sccache"
        "-DCMAKE_CXX_COMPILER_LAUNCHER=sccache"
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
mkdir -p build
cd build
cmake .. -G Ninja "${BASE_CMAKE_FLAGS[@]}" "${EXTRA_CMAKE_FLAGS[@]}"
ninja
echo "-- Build Completed."

echo "-- Sccache stats:"
if [[ "${OPTIMIZE}" == "normal" ]]; then
    sccache -s
fi

# Delete un-needed debug files
echo "-- Cleaning up un-needed files..."
if [[ "${TOOLCHAIN}" == "MSYS2" ]]; then
    find ./bin -type f \( -name "*.dll" -o -name "*.exe" \) -exec strip -s {} +
else
    find bin -type f -name "*.pdb" -exec rm -fv {} +
    rm -rf ./bin/plugins
fi

# Pack for upload
echo "-- Packing build artifacts..."
cd bin
mv -v eden.exe "$EXE_NAME".exe
ZIP_NAME="$EXE_NAME.7z"
7z a -t7z -mx=9 "$ZIP_NAME" *
rm -v "$EXE_NAME".exe
echo "-- Packed into $ZIP_NAME"

echo "=== ALL DONE! ==="
