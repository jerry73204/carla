# CARLA 0.9.14 Build Documentation for carla-rust

## Overview

This document describes the modifications to CARLA 0.9.14's build system for compatibility with modern build tools, specifically CMake 4.x.

## CMake 4.x Compatibility Patch

### Problem

CMake 4.x removed support for `cmake_minimum_required(VERSION < 3.5)`, causing build failures when compiling LLVM 8.0 and its libc++ libraries from source.

### Error Message

```
CMake Error at CMakeLists.txt:3 (cmake_minimum_required):
  Compatibility with CMake < 3.5 has been removed from CMake.

  Update the VERSION argument <min> value.  Or, use the <min>...<max> syntax
  to tell CMake that the project requires at least <min> but has been updated
  to work with policies introduced by <max> or earlier.

  Or, add -DCMAKE_POLICY_VERSION_MINIMUM=3.5 to try configuring anyway.
```

### Solution

Modified `/Util/BuildTools/Setup.sh` to patch CMakeLists.txt files after cloning LLVM source (Line 90-93):

```bash
# Patch LLVM CMakeLists.txt for CMake 4.x compatibility
# CMake 4.x removed support for cmake_minimum_required < 3.5
# Replace all old cmake versions with 3.5
find ${LLVM_BASENAME}-source -name "CMakeLists.txt" -exec sed -i 's/cmake_minimum_required(VERSION [23]\.[0-9]\+\(\.[0-9]\+\)\?)/cmake_minimum_required(VERSION 3.5)/g' {} \;
```

### Location in Build Process

The patch is applied in `Setup.sh` after cloning LLVM 8.0, libcxx, and libcxxabi sources:

1. Line 86: Clone llvm-8.0 main repository
2. Line 87: Clone libcxx into projects/libcxx
3. Line 88: Clone libcxxabi into projects/libcxxabi
4. **Line 90-93: Apply CMake patch** ← NEW
5. Line 95+: Compile libc++

### Affected Files

The patch updates all CMakeLists.txt files in the llvm-8.0-source tree, including:
- LLVM main CMakeLists.txt
- libcxx CMakeLists.txt
- libcxxabi CMakeLists.txt
- Any subdirectory CMakeLists.txt files

### Testing

Tested with:
- CMake 4.1.2
- Ubuntu 22.04
- CARLA 0.9.14

## Google Test CMake 4.x Compatibility Patch

### Problem

Similar to LLVM, Google Test 1.8.1 uses `cmake_minimum_required(VERSION 2.8.8)`, causing CMake 4.x build failures.

### Solution

Modified `/Util/BuildTools/Setup.sh` to patch CMakeLists.txt files after cloning Google Test source (Line 296-299):

```bash
# Patch Google Test CMakeLists.txt for CMake 4.x compatibility
# CMake 4.x removed support for cmake_minimum_required < 3.5
# Replace all old cmake versions with 3.5
find ${GTEST_BASENAME}-source -name "CMakeLists.txt" -exec sed -i 's/cmake_minimum_required[[:space:]]*([[:space:]]*VERSION[[:space:]]\+[23]\.[0-9]\+\(\.[0-9]\+\)\?)/cmake_minimum_required(VERSION 3.5)/g' {} \;
```

## Recast & Detour CMake 4.x Compatibility Patch

### Problem

Recast Navigation library uses `cmake_minimum_required(VERSION 3.1)`, causing CMake 4.x build failures.

### Solution

Modified `/Util/BuildTools/Setup.sh` to patch CMakeLists.txt files after git reset (Line 371-374):

```bash
# Patch Recast CMakeLists.txt for CMake 4.x compatibility
# CMake 4.x removed support for cmake_minimum_required < 3.5
# Replace all old cmake versions with 3.5
find ${RECAST_BASENAME}-source -name "CMakeLists.txt" -exec sed -i 's/cmake_minimum_required[[:space:]]*([[:space:]]*VERSION[[:space:]]\+[23]\.[0-9]\+\(\.[0-9]\+\)\?)/cmake_minimum_required(VERSION 3.5)/g' {} \;
```

## Xerces-C CMake 4.x Compatibility Patch

### Problem

Xerces-C 3.2.3 uses `cmake_minimum_required(VERSION 3.2.0)`, causing CMake 4.x build failures.

### Solution

Modified `/Util/BuildTools/Setup.sh` to patch CMakeLists.txt files after extraction (Line 474-477):

```bash
# Patch xerces-c CMakeLists.txt for CMake 4.x compatibility
# CMake 4.x removed support for cmake_minimum_required < 3.5
# Replace all old cmake versions with 3.5
find ${XERCESC_SRC_DIR} -name "CMakeLists.txt" -exec sed -i 's/cmake_minimum_required[[:space:]]*([[:space:]]*VERSION[[:space:]]\+[23]\.[0-9]\+\(\.[0-9]\+\)\?)/cmake_minimum_required(VERSION 3.5)/g' {} \;
```

## Boost Download URL Fix

### Problem

The original Boost download URL at JFrog Artifactory has been deactivated:

```
https://boostorg.jfrog.io/artifactory/main/release/${BOOST_VERSION}/source/${BOOST_PACKAGE_BASENAME}.tar.gz
```

This causes wget to redirect to a reactivation landing page instead of downloading the actual Boost tarball.

### Solution

Modified `/Util/BuildTools/Setup.sh` line 152 to use the working archives.boost.io URL:

```bash
wget "https://archives.boost.io/release/${BOOST_VERSION}/source/${BOOST_PACKAGE_BASENAME}.tar.gz" -O ${BOOST_PACKAGE_BASENAME}.tar.gz || true
```

This change:
- Uses the official Boost archives mirror (same as CARLA 0.9.16)
- Adds explicit `-O` flag to specify output filename
- Maintains compatibility with fallback download from carla-releases.s3

## Build Command

From carla-rust repository:

```bash
# For CARLA 0.9.14
./scripts/build_prebuilt.sh /path/to/carla-0.9.14 0.9.14
```

## Related

This patch is similar to the patches applied in CARLA 0.9.16 for other dependencies (Google Test, Recast, xerces-c). See CARLA 0.9.16's CLAUDE.md for more comprehensive CMake 4.x compatibility documentation.
