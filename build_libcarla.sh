#!/usr/bin/env bash

# One-step build script for LibCarla Client
# This script builds Unreal Engine and then builds LibCarla Client

set -e

echo "======================================="
echo "One-Step LibCarla Client Build"
echo "======================================="
echo ""

# Get the directory where this script is located
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
cd "$SCRIPT_DIR"

# Set UE4_ROOT to the UnrealEngine directory
export UE4_ROOT="${SCRIPT_DIR}/Unreal/UnrealEngine"

echo "UE4_ROOT: $UE4_ROOT"
echo ""

# Check if UnrealEngine is already cloned and valid
if [ ! -d "$UE4_ROOT/Engine" ]; then
  echo "======================================="
  echo "Cloning UnrealEngine 4.26"
  echo "======================================="
  echo ""
  echo "Performing shallow clone (depth=1) to save space..."
  echo "This will download CARLA's fork of Unreal Engine 4.26"
  echo ""

  # Remove directory if it exists but is incomplete
  if [ -d "$UE4_ROOT" ]; then
    echo "Removing incomplete UnrealEngine directory..."
    rm -rf "$UE4_ROOT"
  fi

  # Create parent directory if needed
  mkdir -p "$(dirname "$UE4_ROOT")"

  # Clone CARLA's fork of Unreal Engine with shallow clone
  echo "Cloning from https://github.com/CarlaUnreal/UnrealEngine.git (branch: carla)..."
  git clone --depth 1 -b carla https://github.com/CarlaUnreal/UnrealEngine.git "$UE4_ROOT"

  echo ""
  echo "UnrealEngine cloned successfully!"
  echo ""
else
  echo "UnrealEngine already cloned at $UE4_ROOT"
  echo ""
fi

# Step 1: Build Unreal Engine (if not already built)
if [ ! -f "$UE4_ROOT/Engine/Binaries/Linux/UE4Editor" ]; then
  echo "======================================="
  echo "Step 1: Building Unreal Engine 4.26"
  echo "======================================="
  echo ""
  echo "This will take a long time (1-2 hours)..."
  echo ""

  cd "$UE4_ROOT"

  # Run Setup.sh if not already done
  if [ ! -f "Build/OneTimeSetupPerformed" ]; then
    echo "Running Setup.sh..."
    echo "This will download the Unreal Engine toolchain (~734 MB)"
    echo ""

    # Workaround: If .git is a file (gitdir reference from submodule setup),
    # Setup.sh cannot create ../.git/ue4-sdks/ cache directory. Temporarily rename it.
    GIT_FILE_RENAMED=0
    if [ -f ".git" ] && [ ! -d ".git" ]; then
      echo "Note: Detected .git file reference - temporarily renaming for Setup.sh"
      mv .git .git.tmp
      GIT_FILE_RENAMED=1
    fi

    ./Setup.sh

    # Restore the .git file if we renamed it
    if [ $GIT_FILE_RENAMED -eq 1 ]; then
      mv .git.tmp .git
      echo "Restored .git file reference"
    fi

    echo ""
  else
    echo "Setup.sh already completed, skipping..."
    echo ""
  fi

  echo "Generating project files..."
  ./GenerateProjectFiles.sh

  echo ""
  echo "Building Unreal Engine (this will take a while)..."
  echo "Note: Not using -j flag as recommended by CARLA docs"
  make

  echo ""
  echo "Unreal Engine build complete!"
  echo ""

  cd "$SCRIPT_DIR"
else
  echo "Unreal Engine already built, skipping..."
  echo ""
fi

# Step 2: Build LibCarla Client
echo "======================================="
echo "Step 2: Building LibCarla Client"
echo "======================================="
echo ""

cd "$SCRIPT_DIR"
make LibCarla.client.release

echo ""
echo "======================================="
echo "Build Complete!"
echo "======================================="
echo ""
echo "Output locations:"
echo "  Build folder:   Build/libcarla-client-build.release"
echo "  Install folder: PythonAPI/carla/dependencies"
echo ""
