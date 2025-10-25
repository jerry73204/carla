# CARLA Build Documentation

## Overview

This document describes the custom build setup for CARLA 0.9.16 on Linux, including the automated build script and patches applied for compatibility with modern build tools.

## Quick Start

To build CARLA LibCarla Client with all dependencies:

```bash
./build_libcarla.sh
```

This script handles:
- Cloning UnrealEngine 4.26 (shallow clone with `--depth=1`)
- Running UnrealEngine Setup.sh (downloads toolchain ~734 MB)
- Running CARLA setup (generates build configuration)
- Building LibCarla Client

**Note**: The script does **not** build the full UnrealEngine (~91GB). It only downloads the toolchain (~734 MB) which contains the clang 10.0.1 compiler needed for LibCarla.

## Why We Need UnrealEngine (But Don't Build It)

Key insight from optimization:

- **We need**: UnrealEngine source directory for its toolchain (clang 10.0.1 compiler, ~734 MB)
- **We don't need**: To build UnrealEngine itself (~91 GB and 1-2 hours)

The build process works as follows:

1. Clone UnrealEngine repository (shallow clone, ~8 GB)
2. Run `Setup.sh` to download the toolchain (~734 MB)
3. Set `UE4_ROOT` environment variable pointing to UnrealEngine directory
4. Run `make setup` to regenerate CARLA's CMake toolchain files with correct paths
5. Run `make LibCarla.client.release` which uses the UE4 clang compiler from the toolchain

This approach saves:
- **~91 GB** of disk space (no UnrealEngine build artifacts)
- **1-2 hours** of build time (no UnrealEngine compilation)

## build_libcarla.sh Script

### Features

- **Idempotent**: Can be run multiple times safely
- **Automatic dependency management**: Downloads UnrealEngine toolchain automatically
- **Optimized for space**: Only downloads what's needed (~8 GB source + ~734 MB toolchain)
- **Fast**: Skips the expensive UnrealEngine build (saves 1-2 hours)
- **Shallow clones**: Uses `--depth=1` to minimize disk space
- **Progress tracking**: Clear status messages for each build step

### Build Checks

The script checks for completion at each stage:

1. **UnrealEngine Clone Check**: Verifies `$UE4_ROOT/Engine` exists
2. **Toolchain Download Check**: Verifies `Build/OneTimeSetupPerformed` marker
3. **CARLA Setup**: Runs `make setup` to regenerate toolchain files with correct paths
4. **LibCarla Build**: Runs `make LibCarla.client.release`

### UnrealEngine Setup Workaround

The script includes a workaround for shallow clones:

- UnrealEngine Setup.sh tries to cache downloads in `../.git/ue4-sdks/`
- With `git submodule absorbgitdirs`, `.git` is a file reference, not a directory
- Workaround: Temporarily renames `.git` file during Setup.sh execution

```bash
# Workaround applied automatically by build_libcarla.sh
mv .git .git.tmp
./Setup.sh
mv .git.tmp .git
```

## CMake 4.x Compatibility Patches

### Problem

CMake 4.x removed support for `cmake_minimum_required(VERSION < 3.5)`, causing build failures for several CARLA dependencies.

### Solution

Modified `/Util/BuildTools/Setup.sh` to patch CMakeLists.txt files after cloning dependencies:

#### 1. Google Test (Line 318-321)

```bash
# Patch Google Test CMakeLists.txt for CMake 4.x compatibility
# CMake 4.x removed support for cmake_minimum_required < 3.5
# Replace all old cmake versions with 3.5
find ${GTEST_BASENAME}-source -name "CMakeLists.txt" -exec sed -i 's/cmake_minimum_required(VERSION 2\.[0-9]\+\.[0-9]\+)/cmake_minimum_required(VERSION 3.5)/g' {} \;
```

#### 2. Recast & Detour (Line 390-392)

```bash
# Patch Recast & Detour CMakeLists.txt for CMake 4.x compatibility
# CMake 4.x removed support for cmake_minimum_required < 3.5
find ${RECAST_BASENAME}-source -name "CMakeLists.txt" -exec sed -i 's/cmake_minimum_required(VERSION [23]\.[0-9]\+)/cmake_minimum_required(VERSION 3.5)/g' {} \;
```

#### 3. xerces-c (Line 512-514)

```bash
# Patch xerces-c CMakeLists.txt for CMake 4.x compatibility
# CMake 4.x removed support for cmake_minimum_required < 3.5
find ${XERCESC_SRC_DIR} -name "CMakeLists.txt" -exec sed -i 's/cmake_minimum_required(VERSION [23]\.[0-9]\+\(\.[0-9]\+\)\?)/cmake_minimum_required(VERSION 3.5)/g' {} \;
```

### Affected Dependencies

- **Google Test 1.8.1**: `VERSION 2.8.8` → `VERSION 3.5`
- **googlemock**: `VERSION 2.6.4` → `VERSION 3.5`
- **googletest**: `VERSION 2.8.12` → `VERSION 3.5`
- **Recast & Detour**: `VERSION 3.1` → `VERSION 3.5`
- **xerces-c 3.2.3**: `VERSION 3.2.0` → `VERSION 3.5`

## System Requirements

- Ubuntu 20.04 or 22.04
- ~40 GB disk space (UE4 source: ~8 GB, toolchain: ~734 MB, CARLA: ~31 GB)
  - **Note**: We no longer build the full UnrealEngine (~91 GB saved!)
- CMake 3.5+ (tested with CMake 4.1.2)
- NVIDIA RTX 2000 series or better (6+ GB VRAM) - only if running simulations
- Intel Core i7 or equivalent (4+ cores)

## Dependencies Built

The build process compiles:

1. **Boost 1.84.0** (c10)
2. **rpclib v2.2.1_c5** (libc++ and libstdc++)
3. **Google Test 1.8.1** (libc++ and libstdc++)
4. **Recast & Detour** (navigation mesh)
5. **xerces-c 3.2.3** (XML parser)
6. **SQLite 3.34.1** (database)
7. **PROJ** (cartographic projections)
8. **LibCarla Client**

## Build Output

Successful build produces:

- **Build folder**: `Build/libcarla-client-build.release`
- **Install folder**: `PythonAPI/carla/dependencies`

## Troubleshooting

### Missing UE4 Toolchain

**Cause**: UnrealEngine Setup.sh didn't complete successfully

**Solution**: Run `./build_libcarla.sh` - it handles this automatically by:
1. Cloning UnrealEngine repository (shallow clone)
2. Checking for `Build/OneTimeSetupPerformed` marker
3. Running Setup.sh with the shallow clone workaround if needed
4. Setting UE4_ROOT environment variable
5. Running `make setup` to regenerate toolchain configuration

### CMake errors about "cmake_minimum_required"

**Cause**: Using CMake 4.x with old CMakeLists.txt files

**Solution**: Patches are already applied in `Util/BuildTools/Setup.sh`. Clean the build and re-run:

```bash
rm -rf Build/gtest-* Build/recast-* Build/xerces-*
./build_libcarla.sh
```

### Disk Space Issues

The UnrealEngine clone uses shallow clone (`--depth=1`) to save space (~8 GB vs full history). We also skip building the full UnrealEngine to save ~91 GB of disk space.

If you need the full UnrealEngine history (not recommended):

```bash
cd Unreal/UnrealEngine
git fetch --unshallow
```

**Important**: You do **not** need to build UnrealEngine to compile LibCarla. The toolchain (~734 MB) is sufficient.

## Files Modified

1. **build_libcarla.sh** (created)
   - One-step build script for LibCarla Client
   - Downloads UnrealEngine source and toolchain (no full build needed)
   - Runs `make setup` to configure CARLA build system
   - Builds LibCarla Client library

2. **Util/BuildTools/Setup.sh** (patched)
   - Line 318-321: Google Test CMake patch
   - Line 390-392: Recast & Detour CMake patch
   - Line 512-514: xerces-c CMake patch

## Branch Information

- **Current branch**: 0.9.16-for-carla-rust
- **Main branch**: ue5-dev (use for PRs)
- **CARLA version**: 0.9.16

## Additional Notes

- **No UnrealEngine build required**: The script only downloads the UE4 source and toolchain, saving ~91 GB
- The script uses the bundled Mono (v5.16.0) from UnrealEngine
- Clang 10.0.1 toolchain is downloaded automatically from CDN (~734 MB)
- Build artifacts are cached to avoid re-downloads
- `make setup` regenerates toolchain files with correct UE4_ROOT paths
- The build process is fully automated and requires no manual intervention

## Environment Variables

Set by the build script:

- `UE4_ROOT`: Path to UnrealEngine installation
- Used for LibCarla compilation

## Clean Build

To perform a completely clean build:

```bash
# Remove all build artifacts
rm -rf Build/
rm -rf Unreal/UnrealEngine/

# Run the build script
./build_libcarla.sh
```

This will re-download UnrealEngine source (~8 GB) and toolchain (~734 MB), then rebuild all dependencies.

**Note**: A clean build is much faster now since we skip the UnrealEngine compilation (~91 GB and 1-2 hours saved!).

---

**Last Updated**: 2025-10-25
**CARLA Version**: 0.9.16
**CMake Version**: 4.1.2
**UnrealEngine Version**: 4.26 (CARLA fork)
