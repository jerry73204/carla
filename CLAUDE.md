# CARLA Build Documentation

This document contains information about building CARLA libcarla-client, specifically documenting the process of building the original version (before installation patch commit 480ec4020).

## Build Script: build_original.sh

### Purpose
Builds `libcarla-client.a` using the original build process before the installation support was added. The script automatically handles all dependencies including UnrealEngine5_carla setup.

### Features
- Automatically clones UnrealEngine5_carla repository if not present
- Automatically runs Setup.sh to download toolchain and dependencies if needed
- Checks out the code before commit 480ec4020
- Builds libcarla-client.a with Python API support
- Returns to original branch/commit after build

### Prerequisites
The script checks for these tools:
- cmake (tested with version 4.1.2)
- ninja
- git

### Usage

Basic usage (fully automated):
```bash
./build_original.sh
```

With custom UnrealEngine path:
```bash
export CARLA_UNREAL_ENGINE_PATH=/custom/path/to/UnrealEngine
./build_original.sh
```

### UnrealEngine5_carla Setup

The script uses the CARLA fork of Unreal Engine 5:
- Repository: https://github.com/CarlaUnreal/UnrealEngine.git
- Branch: ue5-dev-carla
- Default location: `$HOME/repos/UnrealEngine5_carla`

The script will:
1. Clone the repository if it doesn't exist (~29GB)
2. Run Setup.sh if the toolchain is not found (~20GB of dependencies)

**Note:** GenerateProjectFiles.sh is NOT required for building libcarla-client. Only Setup.sh is needed to download the toolchain and libraries.

### What Setup.sh Downloads

Setup.sh downloads these essential components:
- Clang 18.1.0 toolchain (~133MB binary)
- libc++ and libc++abi libraries (~3.4MB)
- OpenSSL 1.1.1t libraries (~6.5MB)
- Additional Unreal Engine dependencies (~20GB total)

These files are not in the git repository and must be downloaded.

### Output

The build produces:
- Location: `Build-Original/LibCarla/libcarla-client.a`
- Size: ~13MB
- Build type: Release
- Compiler: Clang 18.1.0 from UnrealEngine toolchain

## Build Issues and Solutions

### Issue 1: Missing CARLA_UNREAL_ENGINE_PATH
**Error:**
```
CMake Error at CMake/LinuxToolchain.cmake:23 (message):
  The specified Carla Unreal Engine 5 path does not exist ("").
```

**Solution:**
The build script now automatically sets up UnrealEngine5_carla by cloning the repository and running Setup.sh.

**Manual solution:**
```bash
git clone --depth 1 -b ue5-dev-carla https://github.com/CarlaUnreal/UnrealEngine.git ~/UnrealEngine5_carla
cd ~/UnrealEngine5_carla
./Setup.sh --force
export CARLA_UNREAL_ENGINE_PATH=$HOME/UnrealEngine5_carla
```

### Issue 2: CMake Policy Compatibility
**Error:**
```
CMake Error at Build-Original/_deps/libpng-src/CMakeLists.txt:33 (cmake_minimum_required):
  Compatibility with CMake < 3.5 has been removed from CMake.
```

**Solution:**
Added `-DCMAKE_POLICY_VERSION_MINIMUM=3.5` flag to CMake configuration in build_original.sh:49

### Issue 3: Missing Boost::python Target
**Error:**
```
CMake Error at LibCarla/CMakeLists.txt:353 (target_link_libraries):
  Target "carla-client" links to:
    Boost::python
  but the target was not found.
```

**Solution:**
Changed `-DBUILD_PYTHON_API=OFF` to `-DBUILD_PYTHON_API=ON` in build_original.sh:54 to enable Boost::python compilation.

## CMake Configuration

The build uses these CMake settings:
```cmake
cmake -G Ninja -S . -B "Build-Original" \
    --toolchain="$PWD/CMake/LinuxToolchain.cmake" \
    -DCMAKE_BUILD_TYPE="Release" \
    -DCMAKE_POLICY_VERSION_MINIMUM=3.5 \
    -DBUILD_CARLA_CLIENT=ON \
    -DBUILD_CARLA_SERVER=OFF \
    -DBUILD_CARLA_UNREAL=OFF \
    -DBUILD_EXAMPLES=OFF \
    -DBUILD_PYTHON_API=ON
```

## LinuxToolchain.cmake

The toolchain file (`CMake/LinuxToolchain.cmake`) requires these components from UnrealEngine:

1. **Clang Toolchain** (lines 36-62):
   - Path: `Engine/Extras/ThirdPartyNotUE/SDKs/HostLinux/Linux_x64/v23_clang-18.1.0-rockylinux8/x86_64-unknown-linux-gnu/`
   - Used for: Compiler, linker, ar, objcopy, etc.

2. **libc++ Libraries** (lines 68-75):
   - Include: `Engine/Source/ThirdParty/Unix/LibCxx/include`
   - Lib: `Engine/Source/ThirdParty/Unix/LibCxx/lib/Unix/x86_64-unknown-linux-gnu`
   - Used for: C++ standard library

3. **OpenSSL Libraries** (lines 77-85):
   - Include: `Engine/Source/ThirdParty/OpenSSL/1.1.1t/include/Unix`
   - Lib: `Engine/Source/ThirdParty/OpenSSL/1.1.1t/lib/Unix/x86_64-unknown-linux-gnu`
   - Used for: SSL/TLS support

## Build Process

The complete build process (376 files):
1. Configure CMake with toolchain
2. Download and configure dependencies:
   - sqlite3
   - zlib
   - libpng
   - rpclib
   - RecastNavigation (Recast, Detour, DetourCrowd)
   - Boost (with Python 3.10 support)
3. Compile CARLA client sources
4. Link into libcarla-client.a

Build time: Approximately 5-10 minutes on modern hardware (with -j flag)

## Documentation References

- CARLA Documentation: https://carla.readthedocs.io/en/latest/
- CARLA UE5 Documentation: https://carla-ue5.readthedocs.io/
- UnrealEngine Repository: https://github.com/CarlaUnreal/UnrealEngine
- CARLA Repository: https://github.com/carla-simulator/carla

## Notes

- The original version (before commit 480ec4020) does NOT have installation support
- The library can only be used from the build directory
- GenerateProjectFiles.sh is not needed for building libcarla-client
- The script preserves your current branch/commit and returns to it after building
- Build artifacts remain in `Build-Original/` directory
