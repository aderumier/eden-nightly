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
    "-DDYNARMIC_TESTS=OFF"
    "-DYUZU_TESTS=OFF"
    "-DYUZU_USE_BUNDLED_QT=OFF"
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
    clang)
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
    msys2)
        if [[ "${OPTIMIZE}" == "PGO" ]]; then
            EXTRA_CMAKE_FLAGS+=(
                "-DYUZU_STATIC_BUILD=ON"
                "-DYUZU_DISABLE_LLVM=ON"
                "-DQt6_DIR=D:/a/_temp/msys64/MINGW64/qt6-static/lib/cmake/Qt6"
                "-DCMAKE_C_COMPILER=clang"
                "-DCMAKE_CXX_COMPILER=clang++"
                "-DCMAKE_CXX_FLAGS=-march=x86-64-v3 -mtune=generic -fuse-ld=lld -fprofile-use=${GITHUB_WORKSPACE}/pgo/eden.profdata -fprofile-correction -w"
                "-DCMAKE_C_FLAGS=-march=x86-64-v3 -mtune=generic -fuse-ld=lld -fprofile-use=${GITHUB_WORKSPACE}/pgo/eden.profdata -fprofile-correction -w"
            )
        else
            EXTRA_CMAKE_FLAGS+=(
                "-DYUZU_STATIC_BUILD=ON"
                "-DYUZU_DISABLE_LLVM=ON"
                "-DQt6_DIR=D:/a/_temp/msys64/MINGW64/qt6-static/lib/cmake/Qt6"
                "-DCMAKE_CXX_FLAGS=-march=x86-64-v3 -mtune=generic -O3 -w"
                "-DCMAKE_C_FLAGS=-march=x86-64-v3 -mtune=generic -O3 -w"
                "-DCMAKE_C_COMPILER_LAUNCHER=sccache"
                "-DCMAKE_CXX_COMPILER_LAUNCHER=sccache"
            )
        fi
    ;;
    msvc)
        EXTRA_CMAKE_FLAGS+=(
        "-DYUZU_ENABLE_LTO=ON"
        "-DDYNARMIC_ENABLE_LTO=ON"
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

# Gather dependencies
if [[ "${TOOLCHAIN}" != "msys2" ]]; then
    echo "-- Gathering QT dependencies..."
    windeployqt6 --release --no-compiler-runtime --no-opengl-sw --no-system-dxc-compiler --no-system-d3d-compiler --dir bin ./bin/eden.exe
fi

# Delete un-needed debug files
echo "-- Cleaning up un-needed files..."
if [[ "${TOOLCHAIN}" == "msys2" ]]; then
    find ./bin -type f \( -name "*.dll" -o -name "*.exe" \) -exec strip -s {} +
else
    find bin -type f -name "*.pdb" -exec rm -fv {} +
fi

# Pack for upload
echo "-- Packing build artifacts..."
mkdir -p artifacts
mkdir "$EXE_NAME"
cp -rv bin/* "$EXE_NAME"
ZIP_NAME="$EXE_NAME.7z"
7z a -t7z -mx=9 "$ZIP_NAME" "$EXE_NAME"
mv -v "$ZIP_NAME" artifacts/

echo "=== ALL DONE! ==="
