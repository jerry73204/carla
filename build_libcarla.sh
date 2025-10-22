#!/usr/bin/env bash

# One-step build script for LibCarla Client
# This script downloads the UnrealEngine toolchain and builds LibCarla Client
# Note: We don't build the full UnrealEngine (~91GB), only use its toolchain (~734 MB)

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
  echo "Note: We only need the toolchain, not the full build"
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

# Step 1: Download UnrealEngine Toolchain (if not already done)
if [ ! -f "$UE4_ROOT/Build/OneTimeSetupPerformed" ]; then
  echo "======================================="
  echo "Step 1: Downloading UE4 Toolchain"
  echo "======================================="
  echo ""
  echo "Running Setup.sh..."
  echo "This will download the Unreal Engine toolchain (~734 MB)"
  echo "Note: We skip the full UnrealEngine build to save ~91GB"
  echo ""

  cd "$UE4_ROOT"

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
  echo "Toolchain downloaded successfully!"
  echo ""

  cd "$SCRIPT_DIR"
else
  echo "UE4 toolchain already downloaded, skipping..."
  echo ""
fi

# Step 2: Run CARLA setup
echo "======================================="
echo "Step 2: Running CARLA Setup"
echo "======================================="
echo ""

cd "$SCRIPT_DIR"
make setup

echo ""
echo "CARLA setup complete!"
echo ""

# Step 3: Build LibCarla Client
echo "======================================="
echo "Step 3: Building LibCarla Client"
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
