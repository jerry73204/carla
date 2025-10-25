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
- Running UnrealEngine Setup.sh (downloads toolchain)
- Building UnrealEngine
- Building LibCarla Client

## build_libcarla.sh Script

### Features

- **Idempotent**: Can be run multiple times safely
- **Automatic dependency management**: Downloads and builds UnrealEngine automatically
- **Shallow clones**: Uses `--depth=1` to minimize disk space (~734 MB for toolchain)
- **Progress tracking**: Clear status messages for each build step

### Build Checks

The script checks for completion at each stage:

1. **UnrealEngine Clone Check**: Verifies `$UE4_ROOT/Engine` exists
2. **Setup.sh Check**: Verifies `Build/OneTimeSetupPerformed` marker
3. **UnrealEngine Build Check**: Verifies `Engine/Binaries/Linux/UE4Editor` exists

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
- 130 GB disk space (UE4: ~91 GB, CARLA: ~31 GB, toolchain: ~734 MB)
- CMake 3.5+ (tested with CMake 4.1.2)
- NVIDIA RTX 2000 series or better (6+ GB VRAM)
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

### Build Fails with "Platform Linux is not a valid platform"

**Cause**: UnrealEngine Setup.sh didn't complete successfully

**Solution**: Run `./build_libcarla.sh` - it handles this automatically by:
1. Checking for `Build/OneTimeSetupPerformed` marker
2. Running Setup.sh with the shallow clone workaround if needed

### CMake errors about "cmake_minimum_required"

**Cause**: Using CMake 4.x with old CMakeLists.txt files

**Solution**: Patches are already applied in `Util/BuildTools/Setup.sh`. Clean the build and re-run:

```bash
rm -rf Build/gtest-* Build/recast-* Build/xerces-*
./build_libcarla.sh
```

### Disk Space Issues

The UnrealEngine clone uses shallow clone (`--depth=1`) to save space. If you need the full history:

```bash
cd Unreal/UnrealEngine
git fetch --unshallow
```

## Files Modified

1. **build_libcarla.sh** (created)
   - One-step build script for LibCarla Client
   - Handles UnrealEngine download and build

2. **Util/BuildTools/Setup.sh** (patched)
   - Line 318-321: Google Test CMake patch
   - Line 390-392: Recast & Detour CMake patch
   - Line 512-514: xerces-c CMake patch

## Branch Information

- **Current branch**: 0.9.16-for-carla-rust
- **Main branch**: ue5-dev (use for PRs)
- **CARLA version**: 0.9.16

## Additional Notes

- The script uses the bundled Mono (v5.16.0) from UnrealEngine
- Clang 10.0.1 toolchain is downloaded automatically from CDN
- Build artifacts are cached to avoid re-downloads
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

This will re-download UnrealEngine (~734 MB) and rebuild all dependencies.

---

**Last Updated**: 2025-10-25
**CARLA Version**: 0.9.16
**CMake Version**: 4.1.2
**UnrealEngine Version**: 4.26 (CARLA fork)
