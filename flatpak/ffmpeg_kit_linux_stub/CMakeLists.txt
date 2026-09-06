# Stub replacement for ffmpeg_kit_flutter_new_audio/linux/CMakeLists.txt,
# copied over the vendored package by the Flatpak build (see the `cp` in
# com.bandpassrecords.dpm.yml).
#
# The real one downloads a ~19 MB prebuilt ffmpeg bundle from GitHub at CMake
# *configure* time and FATAL_ERRORs without network — impossible in the
# offline Flathub build. And nothing calls ffmpeg-kit on Linux anyway:
# AudioAnalysisService.convertForSharing shells out to a PATH ffmpeg there,
# not the in-process library (_usesInProcessFfmpeg is Android/iOS only). So
# this builds a do-nothing plugin that just satisfies the generated plugin
# registrant's link — no download, no json-glib, no bundled .so files.

cmake_minimum_required(VERSION 3.13)

set(PROJECT_NAME "ffmpeg_kit_flutter_new_audio")
project(${PROJECT_NAME} LANGUAGES CXX)

set(PLUGIN_NAME "ffmpeg_kit_flutter_new_audio_plugin")

add_library(${PLUGIN_NAME} SHARED "ffmpeg_kit_flutter_plugin_stub.cc")

# apply_standard_settings comes from the host application's linux/CMakeLists.txt.
apply_standard_settings(${PLUGIN_NAME})
set_target_properties(${PLUGIN_NAME} PROPERTIES CXX_VISIBILITY_PRESET hidden)
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
