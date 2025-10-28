#!/bin/bash
set -e

# Script to build libcarla_client using the ORIGINAL process (before installation patch)
# This checks out the code before commit 480ec4020 and builds it
# This script will automatically set up UnrealEngine5_carla if not present

echo "=========================================="
echo "Building libcarla_client (ORIGINAL)"
echo "=========================================="
echo ""

# Save current branch/commit
CURRENT_REF=$(git rev-parse --abbrev-ref HEAD)
if [ "$CURRENT_REF" = "HEAD" ]; then
    CURRENT_REF=$(git rev-parse HEAD)
fi
echo "Current ref: $CURRENT_REF"
echo ""

# Checkout the commit before the installation patch
BEFORE_PATCH="480ec4020^"
echo "Checking out commit before installation patch: $BEFORE_PATCH"
git checkout $BEFORE_PATCH

echo ""
echo "Checking prerequisites..."
command -v cmake >/dev/null 2>&1 || { echo "Error: cmake is required but not installed."; exit 1; }
command -v ninja >/dev/null 2>&1 || { echo "Error: ninja is required but not installed."; exit 1; }
command -v git >/dev/null 2>&1 || { echo "Error: git is required but not installed."; exit 1; }

CMAKE_VERSION=$(cmake --version | head -n1 | cut -d' ' -f3)
echo "Found CMake version: $CMAKE_VERSION"
echo ""

# Setup UnrealEngine5_carla if needed
if [ -z "$CARLA_UNREAL_ENGINE_PATH" ]; then
    CARLA_UNREAL_ENGINE_PATH="$HOME/repos/UnrealEngine5_carla"
    echo "CARLA_UNREAL_ENGINE_PATH not set, using default: $CARLA_UNREAL_ENGINE_PATH"
fi

export CARLA_UNREAL_ENGINE_PATH

if [ ! -d "$CARLA_UNREAL_ENGINE_PATH" ]; then
    echo ""
    echo "=========================================="
    echo "UnrealEngine5_carla not found"
    echo "=========================================="
    echo "Cloning UnrealEngine repository (this will take a while, ~29GB)..."
    echo "Location: $CARLA_UNREAL_ENGINE_PATH"
    echo ""

    mkdir -p "$(dirname "$CARLA_UNREAL_ENGINE_PATH")"
    git clone --depth 1 -b ue5-dev-carla https://github.com/CarlaUnreal/UnrealEngine.git "$CARLA_UNREAL_ENGINE_PATH"

    echo ""
    echo "Clone completed!"
fi

# Check if Setup.sh has been run by looking for the toolchain
TOOLCHAIN_PATH="$CARLA_UNREAL_ENGINE_PATH/Engine/Extras/ThirdPartyNotUE/SDKs/HostLinux/Linux_x64/v23_clang-18.1.0-rockylinux8/x86_64-unknown-linux-gnu/bin/clang"

if [ ! -f "$TOOLCHAIN_PATH" ]; then
    echo ""
    echo "=========================================="
    echo "Running UnrealEngine Setup.sh"
    echo "=========================================="
    echo "Downloading dependencies (this will take a while, ~20GB)..."
    echo ""

    cd "$CARLA_UNREAL_ENGINE_PATH"
    ./Setup.sh --force
    cd - > /dev/null

    echo ""
    echo "Setup completed!"
else
    echo "UnrealEngine toolchain found at: $CARLA_UNREAL_ENGINE_PATH"
fi

echo ""

# Set build directory
BUILD_DIR="Build-Original"
BUILD_TYPE="Release"

echo "Configuration:"
echo "  Build directory: $BUILD_DIR"
echo "  Build type: $BUILD_TYPE"
echo "  Commit: $(git log -1 --oneline)"
echo ""

# Configure
echo "Configuring build..."
cmake -G Ninja -S . -B "$BUILD_DIR" \
    --toolchain="$PWD/CMake/LinuxToolchain.cmake" \
    -DCMAKE_BUILD_TYPE="$BUILD_TYPE" \
    -DCMAKE_POLICY_VERSION_MINIMUM=3.5 \
    -DBUILD_CARLA_CLIENT=ON \
    -DBUILD_CARLA_SERVER=OFF \
    -DBUILD_CARLA_UNREAL=OFF \
    -DBUILD_EXAMPLES=OFF \
    -DBUILD_PYTHON_API=ON

echo ""
echo "Building libcarla_client..."
cmake --build "$BUILD_DIR" -j$(nproc)

echo ""
echo "=========================================="
echo "Build completed successfully!"
echo "=========================================="
echo ""
echo "Output library: $BUILD_DIR/lib/libcarla-client.a"
echo ""
echo "NOTE: This version does NOT have installation support."
echo "The library can only be used from the build directory."
echo ""
echo "Additional libraries built:"
ls -lh "$BUILD_DIR/lib/"*.a 2>/dev/null || true
echo ""

# Return to original ref
echo "Returning to original ref: $CURRENT_REF"
git checkout "$CURRENT_REF"

echo ""
echo "Build artifacts remain in $BUILD_DIR/"
echo "Original branch/commit has been restored."
