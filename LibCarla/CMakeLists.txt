project (
  libcarla
  LANGUAGES
    CXX
  VERSION
    ${CARLA_VERSION}
)

set (
  LIBCARLA_SOURCE_PATH
  ${CARLA_WORKSPACE_PATH}/LibCarla/source
)

carla_two_step_configure_file (
  ${LIBCARLA_SOURCE_PATH}/carla/Version.h
  ${LIBCARLA_SOURCE_PATH}/carla/Version.h.in
)

if (WIN32)

  set (
    WINNT_MACRO_PATH
    ${LIBCARLA_SOURCE_PATH}/util/winnt-macros.txt
  )

  file (
    STRINGS
    ${WINNT_MACRO_PATH}
    WINDOWS_MACRO_LIST
  )

  set (
    GUARD_BEGIN_FILE_TEXT
    ""
  )

  set (
    GUARD_END_FILE_TEXT
    ""
  )

  foreach (WINDOWS_MACRO ${WINDOWS_MACRO_LIST})
    string (
      APPEND
      GUARD_BEGIN_FILE_TEXT
      "#pragma push_macro(\"${WINDOWS_MACRO}\")\n"
      "#undef ${WINDOWS_MACRO}\n"
    )
    string (
      APPEND
      GUARD_END_FILE_TEXT
      "#pragma pop_macro(\"${WINDOWS_MACRO}\")\n"
    )
  endforeach ()

  file (
    WRITE
    ${LIBCARLA_SOURCE_PATH}/util/ue-header-guard-begin.h
    ${GUARD_BEGIN_FILE_TEXT}
  )

  file (
    WRITE
    ${LIBCARLA_SOURCE_PATH}/util/ue-header-guard-end.h
    ${GUARD_END_FILE_TEXT}
  )

  set_directory_properties(
    PROPERTIES
    CMAKE_CONFIGURE_DEPENDS
    ${WINNT_MACRO_PATH}
  )

else ()

  file (
    WRITE
    ${LIBCARLA_SOURCE_PATH}/util/ue-header-guard-begin.h
    ""
  )

  file (
    WRITE
    ${LIBCARLA_SOURCE_PATH}/util/ue-header-guard-end.h
    ""
  )

endif ()



if (BUILD_CARLA_SERVER)

  file (
    GLOB
    LIBCARLA_SERVER_SOURCES
    ${LIBCARLA_SOURCE_PATH}/carla/Buffer.cpp
    ${LIBCARLA_SOURCE_PATH}/carla/Exception.cpp
    ${LIBCARLA_SOURCE_PATH}/carla/geom/*.cpp
    ${LIBCARLA_SOURCE_PATH}/carla/opendrive/*.cpp
    ${LIBCARLA_SOURCE_PATH}/carla/opendrive/parser/*.cpp
    ${LIBCARLA_SOURCE_PATH}/carla/road/*.cpp
    ${LIBCARLA_SOURCE_PATH}/carla/road/element/*.cpp
    ${LIBCARLA_SOURCE_PATH}/carla/road/general/*.cpp
    ${LIBCARLA_SOURCE_PATH}/carla/road/object/*.cpp
    ${LIBCARLA_SOURCE_PATH}/carla/road/signal/*.cpp
    ${LIBCARLA_SOURCE_PATH}/carla/rpc/*.cpp
    ${LIBCARLA_SOURCE_PATH}/carla/sensor/s11n/SensorHeaderSerializer.cpp
    ${LIBCARLA_SOURCE_PATH}/carla/streaming/detail/*.cpp
    ${LIBCARLA_SOURCE_PATH}/carla/streaming/detail/tcp/*.cpp
    ${LIBCARLA_SOURCE_PATH}/carla/multigpu/*.cpp
  )

  if (ENABLE_ROS2)
    file (
      GLOB
      LIBCARLA_SERVER_SOURCES_ROS2
      ${LIBCARLA_SOURCE_PATH}/carla/ros2/*.cpp
    )
    list (
      APPEND
      LIBCARLA_SERVER_SOURCES
      ${LIBCARLA_SERVER_SOURCES_ROS2}
    )
  endif ()

  file (
    GLOB
    LIBCARLA_SERVER_SOURCES_THIRD_PARTY
    ${LIBCARLA_SOURCE_PATH}/third-party/odrSpiral/*.cpp
    ${LIBCARLA_SOURCE_PATH}/third-party/moodycamel/*.cpp
    ${LIBCARLA_SOURCE_PATH}/third-party/pugixml/*.cpp
  )

  file (
    GLOB
    LIBCARLA_SERVER_HEADERS
    ${LIBCARLA_SOURCE_PATH}/carla/*.h
    ${LIBCARLA_SOURCE_PATH}/carla/geom/*.h
    ${LIBCARLA_SOURCE_PATH}/carla/opendrive/*.h
    ${LIBCARLA_SOURCE_PATH}/carla/opendrive/parser/*.h
    ${LIBCARLA_SOURCE_PATH}/carla/road/*.h
    ${LIBCARLA_SOURCE_PATH}/carla/road/element/*.h
    ${LIBCARLA_SOURCE_PATH}/carla/road/general/*.h
    ${LIBCARLA_SOURCE_PATH}/carla/road/object/*.h
    ${LIBCARLA_SOURCE_PATH}/carla/road/signal/*.h
    ${LIBCARLA_SOURCE_PATH}/carla/rpc/*.h
    ${LIBCARLA_SOURCE_PATH}/carla/sensor/*.h
    ${LIBCARLA_SOURCE_PATH}/carla/sensor/s11n/*.h
    ${LIBCARLA_SOURCE_PATH}/carla/streaming/*.h
    ${LIBCARLA_SOURCE_PATH}/carla/streaming/detail/*.h
    ${LIBCARLA_SOURCE_PATH}/carla/streaming/low_level/*.h
    ${LIBCARLA_SOURCE_PATH}/carla/multigpu/*.h
    ${LIBCARLA_SOURCE_PATH}/util/*.h
  )
  
  list (
    APPEND
    LIBCARLA_SERVER_HEADERS
    ${LIBCARLA_SOURCE_PATH}/util/winnt-macros.txt
  )

  if (ENABLE_ROS2)
    file (
      GLOB
      LIBCARLA_SERVER_HEADERS_ROS2
      ${LIBCARLA_SOURCE_PATH}/carla/ros2/*.h
    )
    list (
      APPEND
      LIBCARLA_SERVER_HEADERS
      ${LIBCARLA_SERVER_HEADERS_ROS2}
    )
    set (CARLA_ROS2_DEFINITIONS WITH_ROS2)
  endif ()

  if (ENABLE_ROS2_DEMO)
    set (CARLA_ROS2_DEFINITIONS ${CARLA_ROS2_DEFINITIONS} WITH_ROS2_DEMO)
  endif ()

  file (
    GLOB
    LIBCARLA_SERVER_HEADERS_THIRD_PARTY
    ${LIBCARLA_SOURCE_PATH}/third-party/odrSpiral/*.h
    ${LIBCARLA_SOURCE_PATH}/third-party/moodycamel/*.h
    ${LIBCARLA_SOURCE_PATH}/third-party/pugixml/*.hpp
  )

  carla_add_library (
    carla-server
    "Build the CARLA server."
    ${LIBCARLA_SERVER_HEADERS}
    ${LIBCARLA_SERVER_SOURCES}
    ${LIBCARLA_SERVER_HEADERS_THIRD_PARTY}
    ${LIBCARLA_SERVER_SOURCES_THIRD_PARTY}
  )

  target_link_libraries (
    carla-server PUBLIC SYSTEM
    Boost::asio
    Boost::geometry
    Boost::algorithm
    Boost::assert
    Boost::gil
    RecastNavigation::Recast
    RecastNavigation::Detour
    RecastNavigation::DetourCrowd
    png_static
    zlibstatic
    rpc
  )
  
  target_include_directories (
    carla-server PUBLIC
    ${LIBCARLA_SOURCE_PATH}
  )

  target_compile_definitions (
    carla-server PUBLIC
    ${CARLA_COMMON_DEFINITIONS}
    ${CARLA_EXCEPTION_DEFINITIONS}
    ${CARLA_RTTI_DEFINITIONS}
    ${CARLA_ROS2_DEFINITIONS}
  )

  if (ENABLE_ROS2)
    add_dependencies (carla-server carla-ros2-native)
  endif ()

endif ()



if (BUILD_CARLA_CLIENT)

  file (
    GLOB
    LIBCARLA_CLIENT_HEADERS
    ${LIBCARLA_SOURCE_PATH}/carla/*.h
    ${LIBCARLA_SOURCE_PATH}/carla/client/*.h
    ${LIBCARLA_SOURCE_PATH}/carla/client/detail/*.h
    ${LIBCARLA_SOURCE_PATH}/carla/geom/*.h
    ${LIBCARLA_SOURCE_PATH}/carla/image/*.h
    ${LIBCARLA_SOURCE_PATH}/carla/nav/*.h
    ${LIBCARLA_SOURCE_PATH}/carla/opendrive/*.h
    ${LIBCARLA_SOURCE_PATH}/carla/opendrive/parser/*.h
    ${LIBCARLA_SOURCE_PATH}/carla/pointcloud/*.h
    ${LIBCARLA_SOURCE_PATH}/carla/profiler/*.h
    ${LIBCARLA_SOURCE_PATH}/carla/road/*.h
    ${LIBCARLA_SOURCE_PATH}/carla/road/element/*.h
    ${LIBCARLA_SOURCE_PATH}/carla/road/general/*.h
    ${LIBCARLA_SOURCE_PATH}/carla/road/object/*.h
    ${LIBCARLA_SOURCE_PATH}/carla/road/signal/*.h
    ${LIBCARLA_SOURCE_PATH}/carla/rpc/*.h
    ${LIBCARLA_SOURCE_PATH}/carla/sensor/*.h
    ${LIBCARLA_SOURCE_PATH}/carla/sensor/data/*.h
    ${LIBCARLA_SOURCE_PATH}/carla/sensor/s11n/*.h
    ${LIBCARLA_SOURCE_PATH}/carla/streaming/*.h
    ${LIBCARLA_SOURCE_PATH}/carla/streaming/detail/*.h
    ${LIBCARLA_SOURCE_PATH}/carla/streaming/detail/tcp/*.h
    ${LIBCARLA_SOURCE_PATH}/carla/streaming/low_level/*.h
    ${LIBCARLA_SOURCE_PATH}/carla/multigpu/*.h
    ${LIBCARLA_SOURCE_PATH}/carla/trafficmanager/*.h
    ${LIBCARLA_SOURCE_PATH}/util/*.h
  )

  list (
    APPEND
    LIBCARLA_CLIENT_HEADERS
    ${LIBCARLA_SOURCE_PATH}/util/winnt-macros.txt
  )

  if (ENABLE_RSS)
    file (
      GLOB
      LIBCARLA_CLIENT_HEADERS_RSS
      ${LIBCARLA_SOURCE_PATH}/carla/rss/*.h
    )
    list (
      APPEND
      LIBCARLA_CLIENT_HEADERS
      ${LIBCARLA_CLIENT_HEADERS_RSS}
    )
  endif ()

  file (
    GLOB
    LIBCARLA_CLIENT_HEADERS_THIRD_PARTY
    ${LIBCARLA_SOURCE_PATH}/third-party/odrSpiral/*.h
    ${LIBCARLA_SOURCE_PATH}/third-party/moodycamel/*.h
    ${LIBCARLA_SOURCE_PATH}/third-party/pugixml/*.hpp
    ${LIBCARLA_SOURCE_PATH}/third-party/pugixml/*.h
  )

  file (
    GLOB
    LIBCARLA_CLIENT_SOURCES
    ${LIBCARLA_SOURCE_PATH}/carla/*.cpp
    ${LIBCARLA_SOURCE_PATH}/carla/client/*.cpp
    ${LIBCARLA_SOURCE_PATH}/carla/client/detail/*.cpp
    ${LIBCARLA_SOURCE_PATH}/carla/geom/*.cpp
    ${LIBCARLA_SOURCE_PATH}/carla/image/*.cpp
    ${LIBCARLA_SOURCE_PATH}/carla/nav/*.cpp
    ${LIBCARLA_SOURCE_PATH}/carla/opendrive/*.cpp
    ${LIBCARLA_SOURCE_PATH}/carla/opendrive/parser/*.cpp
    ${LIBCARLA_SOURCE_PATH}/carla/pointcloud/*.cpp
    ${LIBCARLA_SOURCE_PATH}/carla/road/*.cpp
    ${LIBCARLA_SOURCE_PATH}/carla/road/element/*.cpp
    ${LIBCARLA_SOURCE_PATH}/carla/road/general/*.cpp
    ${LIBCARLA_SOURCE_PATH}/carla/road/object/*.cpp
    ${LIBCARLA_SOURCE_PATH}/carla/road/signal/*.cpp
    ${LIBCARLA_SOURCE_PATH}/carla/rpc/*.cpp
    ${LIBCARLA_SOURCE_PATH}/carla/sensor/*.cpp
    ${LIBCARLA_SOURCE_PATH}/carla/sensor/data/*.cpp
    ${LIBCARLA_SOURCE_PATH}/carla/sensor/s11n/*.cpp
    ${LIBCARLA_SOURCE_PATH}/carla/streaming/*.cpp
    ${LIBCARLA_SOURCE_PATH}/carla/streaming/detail/*.cpp
    ${LIBCARLA_SOURCE_PATH}/carla/streaming/detail/tcp/*.cpp
    ${LIBCARLA_SOURCE_PATH}/carla/streaming/low_level/*.cpp
    ${LIBCARLA_SOURCE_PATH}/carla/multigpu/*.cpp
    ${LIBCARLA_SOURCE_PATH}/carla/trafficmanager/*.cpp
  )

  if (ENABLE_RSS)
    file (
      GLOB
      LIBCARLA_CLIENT_SOURCES_RSS
      ${LIBCARLA_SOURCE_PATH}/carla/rss/*.cpp
    )
    list (
      APPEND
      LIBCARLA_CLIENT_SOURCES
      ${LIBCARLA_CLIENT_SOURCES_RSS}
    )
  endif ()

  file (
    GLOB
    LIBCARLA_CLIENT_SOURCES_THIRD_PARTY
    ${LIBCARLA_SOURCE_PATH}/third-party/odrSpiral/*.cpp
    ${LIBCARLA_SOURCE_PATH}/third-party/pugixml/*.cpp
  )

  carla_add_library (
    carla-client
    "Build the CARLA client."
    ${LIBCARLA_CLIENT_HEADERS}
    ${LIBCARLA_CLIENT_SOURCES}
    ${LIBCARLA_CLIENT_HEADERS_THIRD_PARTY}
    ${LIBCARLA_CLIENT_SOURCES_THIRD_PARTY}
  )

  target_link_libraries (
    carla-client PUBLIC
    Boost::asio
    Boost::python
    Boost::algorithm
    Boost::geometry
    Boost::assert
    Boost::gil
    RecastNavigation::Recast
    RecastNavigation::Detour
    RecastNavigation::DetourCrowd
    png_static
    zlibstatic
    rpc
  )
  
  target_include_directories (
    carla-client PUBLIC
    ${LIBCARLA_SOURCE_PATH}
  )

  target_compile_definitions (
    carla-client PUBLIC
    ${CARLA_COMMON_DEFINITIONS}
    ${CARLA_EXCEPTION_DEFINITIONS}
    ${CARLA_RTTI_DEFINITIONS}
  )

  # Set target properties for better CMake integration
  set_target_properties(carla-client PROPERTIES
    VERSION ${CARLA_VERSION}
    SOVERSION ${CARLA_VERSION_MAJOR}
    OUTPUT_NAME carla-client
    EXPORT_NAME carla-client
    PUBLIC_HEADER ""
  )

  # Create interface properties for consuming projects
  target_compile_features(carla-client PUBLIC cxx_std_14)

  # Add interface compile definitions that consumers will inherit
  target_compile_definitions(carla-client INTERFACE
    $<BUILD_INTERFACE:CARLA_BUILD_INTERFACE>
    $<INSTALL_INTERFACE:CARLA_INSTALL_INTERFACE>
  )

  # Install LibCarla client library and headers
  install(TARGETS carla-client
    ARCHIVE DESTINATION lib COMPONENT carla-client
    LIBRARY DESTINATION lib COMPONENT carla-client
    RUNTIME DESTINATION bin COMPONENT carla-client
  )

  # Create an interface library for export (avoids dependency export issues)
  add_library(carla-client-interface INTERFACE)

  # Set the interface properties for consumers
  target_include_directories(carla-client-interface INTERFACE
    $<INSTALL_INTERFACE:include>
  )
  target_compile_features(carla-client-interface INTERFACE cxx_std_14)

  # Install all dependency libraries to make them available
  install(TARGETS rpc Recast Detour DetourCrowd png_static zlibstatic
    ARCHIVE DESTINATION lib COMPONENT carla-client
    LIBRARY DESTINATION lib COMPONENT carla-client
  )

  # Link to all required libraries in the interface target
  target_link_libraries(carla-client-interface INTERFACE
    $<INSTALL_INTERFACE:\${_IMPORT_PREFIX}/lib/libcarla-client.a>
    $<INSTALL_INTERFACE:\${_IMPORT_PREFIX}/lib/librpc.a>
    $<INSTALL_INTERFACE:\${_IMPORT_PREFIX}/lib/libRecast.a>
    $<INSTALL_INTERFACE:\${_IMPORT_PREFIX}/lib/libDetour.a>
    $<INSTALL_INTERFACE:\${_IMPORT_PREFIX}/lib/libDetourCrowd.a>
    $<INSTALL_INTERFACE:\${_IMPORT_PREFIX}/lib/libpng16.a>
    $<INSTALL_INTERFACE:\${_IMPORT_PREFIX}/lib/libz.a>
    pthread
  )

  # Install the interface library with export information
  install(TARGETS carla-client-interface
    EXPORT CarlaTargets
    COMPONENT carla-client
  )

  # Install LibCarla headers
  install(DIRECTORY ${LIBCARLA_SOURCE_PATH}/carla
    DESTINATION include
    COMPONENT carla-client
    FILES_MATCHING PATTERN "*.h" PATTERN "*.hpp"
    PATTERN "test" EXCLUDE
    PATTERN "examples" EXCLUDE
  )

  # Install third-party headers that are part of the public API
  install(DIRECTORY ${LIBCARLA_SOURCE_PATH}/third-party/
    DESTINATION include/third-party
    COMPONENT carla-client
    FILES_MATCHING PATTERN "*.h" PATTERN "*.hpp"
    PATTERN "test" EXCLUDE
    PATTERN "examples" EXCLUDE
    PATTERN "build" EXCLUDE
  )

  # === THIRD-PARTY DEPENDENCY HEADERS INSTALLATION ===

  # Install RPC library headers (from rpclib dependency)
  set(RPCLIB_INCLUDE_DIR ${CMAKE_BINARY_DIR}/_deps/rpclib-src/include)
  if(EXISTS ${RPCLIB_INCLUDE_DIR})
    install(DIRECTORY ${RPCLIB_INCLUDE_DIR}/
      DESTINATION include
      COMPONENT carla-client
      FILES_MATCHING PATTERN "*.h" PATTERN "*.hpp" PATTERN "*.inl"
      PATTERN "test" EXCLUDE
      PATTERN "examples" EXCLUDE
      PATTERN "benchmark" EXCLUDE
    )
    message(STATUS "CARLA: Will install RPC headers from ${RPCLIB_INCLUDE_DIR}")
  else()
    message(WARNING "CARLA: RPC headers not found at ${RPCLIB_INCLUDE_DIR}")
  endif()

  # Install RecastNavigation headers
  set(RECAST_INCLUDE_DIR ${CMAKE_BINARY_DIR}/_deps/recastnavigation-src)
  if(EXISTS ${RECAST_INCLUDE_DIR})
    # Install Detour headers
    if(EXISTS ${RECAST_INCLUDE_DIR}/Detour/Include)
      install(DIRECTORY ${RECAST_INCLUDE_DIR}/Detour/Include/
        DESTINATION include
        COMPONENT carla-client
        FILES_MATCHING PATTERN "*.h"
      )
      message(STATUS "CARLA: Will install Detour headers from ${RECAST_INCLUDE_DIR}/Detour/Include")
    endif()

    # Install Recast headers
    if(EXISTS ${RECAST_INCLUDE_DIR}/Recast/Include)
      install(DIRECTORY ${RECAST_INCLUDE_DIR}/Recast/Include/
        DESTINATION include
        COMPONENT carla-client
        FILES_MATCHING PATTERN "*.h"
      )
      message(STATUS "CARLA: Will install Recast headers from ${RECAST_INCLUDE_DIR}/Recast/Include")
    endif()

    # Install DetourCrowd headers
    if(EXISTS ${RECAST_INCLUDE_DIR}/DetourCrowd/Include)
      install(DIRECTORY ${RECAST_INCLUDE_DIR}/DetourCrowd/Include/
        DESTINATION include
        COMPONENT carla-client
        FILES_MATCHING PATTERN "*.h"
      )
      message(STATUS "CARLA: Will install DetourCrowd headers from ${RECAST_INCLUDE_DIR}/DetourCrowd/Include")
    endif()
  else()
    message(WARNING "CARLA: RecastNavigation headers not found at ${RECAST_INCLUDE_DIR}")
  endif()

  # Note: PNG, zlib, and Eigen headers are internal dependencies
  # Only RPC and RecastNavigation headers are needed for public API

  # Export targets for use by other CMake projects
  install(EXPORT CarlaTargets
    FILE CarlaTargets.cmake
    NAMESPACE Carla::
    DESTINATION lib/cmake/Carla
    COMPONENT carla-client
  )

  # Create package configuration files
  include(CMakePackageConfigHelpers)

  # Generate CarlaConfig.cmake
  configure_package_config_file(
    ${CMAKE_CURRENT_SOURCE_DIR}/cmake/CarlaConfig.cmake.in
    ${CMAKE_CURRENT_BINARY_DIR}/CarlaConfig.cmake
    INSTALL_DESTINATION lib/cmake/Carla
    PATH_VARS CMAKE_INSTALL_PREFIX
  )

  # Generate CarlaConfigVersion.cmake
  write_basic_package_version_file(
    ${CMAKE_CURRENT_BINARY_DIR}/CarlaConfigVersion.cmake
    VERSION ${CARLA_VERSION}
    COMPATIBILITY SameMajorVersion
  )

  # Install package configuration files
  install(FILES
    ${CMAKE_CURRENT_BINARY_DIR}/CarlaConfig.cmake
    ${CMAKE_CURRENT_BINARY_DIR}/CarlaConfigVersion.cmake
    DESTINATION lib/cmake/Carla
    COMPONENT carla-client
  )

  # Update pkg-config file for non-CMake projects
  configure_file(
    ${CMAKE_CURRENT_SOURCE_DIR}/cmake/carla-client.pc.in
    ${CMAKE_CURRENT_BINARY_DIR}/carla-client.pc
    @ONLY
  )
  install(FILES ${CMAKE_CURRENT_BINARY_DIR}/carla-client.pc
    DESTINATION lib/pkgconfig
    COMPONENT carla-client
  )
endif ()
