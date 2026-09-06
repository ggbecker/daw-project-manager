# Stubbed Linux native layer for the vendored ffmpeg_kit_flutter_new_audio.
#
# The upstream file downloads a ~19 MB prebuilt ffmpeg bundle from GitHub at
# CMake *configure* time and also requires json-glib-1.0 dev headers. DAW
# Project Manager never invokes ffmpeg-kit on Linux -
# AudioAnalysisService only routes to the in-process library on Android/iOS
# (_usesInProcessFfmpeg); every desktop path shells out to a PATH ffmpeg or
# afconvert instead. So this builds a do-nothing plugin that only satisfies
# the generated plugin registrant's link: no download, no json-glib, no
# bundled .so files. See third_party/ffmpeg_kit_flutter_new_audio/README-vendor.md.

cmake_minimum_required(VERSION 3.13)

set(PROJECT_NAME "ffmpeg_kit_flutter_new_audio")
project(${PROJECT_NAME} LANGUAGES CXX)

set(PLUGIN_NAME "ffmpeg_kit_flutter_new_audio_plugin")

add_library(${PLUGIN_NAME} SHARED
  "ffmpeg_kit_flutter_plugin.cc"
)

# apply_standard_settings comes from the host application's linux/CMakeLists.txt.
apply_standard_settings(${PLUGIN_NAME})

set_target_properties(${PLUGIN_NAME} PROPERTIES
  CXX_VISIBILITY_PRESET hidden)
target_compile_definitions(${PLUGIN_NAME} PRIVATE FLUTTER_PLUGIN_IMPL)

# The generated registrant includes <ffmpeg_kit_flutter_new_audio/...h>; the
# vendored include/ directory is left in place, not overwritten.
target_include_directories(${PLUGIN_NAME} INTERFACE
  "${CMAKE_CURRENT_SOURCE_DIR}/include")

find_package(PkgConfig REQUIRED)
pkg_check_modules(GTK REQUIRED IMPORTED_TARGET gtk+-3.0)

target_link_libraries(${PLUGIN_NAME} PRIVATE flutter PkgConfig::GTK)

# No ffmpeg shared libraries to bundle into the app.
set(ffmpeg_kit_flutter_new_audio_bundled_libraries "" PARENT_SCOPE)
