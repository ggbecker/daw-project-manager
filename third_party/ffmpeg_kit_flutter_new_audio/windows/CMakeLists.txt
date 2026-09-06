# Stubbed Windows native layer for the vendored ffmpeg_kit_flutter_new_audio.
#
# The upstream file downloads a prebuilt ffmpeg bundle from GitHub at CMake
# configure time and runs editbin over the DLLs. DAW Project Manager never
# invokes ffmpeg-kit on Windows - AudioAnalysisService only routes to the
# in-process library on Android/iOS (_usesInProcessFfmpeg); the Windows path
# shells out to a bundled/PATH ffmpeg instead. So this builds a do-nothing
# plugin that only satisfies the generated plugin registrant's link: no
# download, no editbin, no bundled DLLs. See README-vendor.md.

cmake_minimum_required(VERSION 3.14)

set(PROJECT_NAME "ffmpeg_kit_flutter_new_audio")
project(${PROJECT_NAME} LANGUAGES CXX)

set(PLUGIN_NAME "ffmpeg_kit_flutter_new_audio_plugin")

add_library(${PLUGIN_NAME} SHARED
  "ffmpeg_kit_flutter_plugin_c_api.cpp"
)

set_target_properties(${PLUGIN_NAME} PROPERTIES
  CXX_STANDARD 17
  CXX_VISIBILITY_PRESET hidden)

target_compile_definitions(${PLUGIN_NAME} PRIVATE FLUTTER_PLUGIN_IMPL)

# generated_plugin_registrant.cc includes <ffmpeg_kit_flutter_new_audio/
# f_fmpeg_kit_flutter_plugin.h>; generate it here exactly as upstream does.
set(PUBLIC_HEADER_DIR "${CMAKE_CURRENT_BINARY_DIR}/include/${PROJECT_NAME}")
file(MAKE_DIRECTORY "${PUBLIC_HEADER_DIR}")
file(WRITE "${PUBLIC_HEADER_DIR}/f_fmpeg_kit_flutter_plugin.h" [=[
#ifndef FLUTTER_PLUGIN_FFMPEG_KIT_FLUTTER_PLUGIN_C_API_H_
#define FLUTTER_PLUGIN_FFMPEG_KIT_FLUTTER_PLUGIN_C_API_H_

#include <flutter_plugin_registrar.h>

#ifdef FLUTTER_PLUGIN_IMPL
#define FLUTTER_PLUGIN_EXPORT __declspec(dllexport)
#else
#define FLUTTER_PLUGIN_EXPORT __declspec(dllimport)
#endif

#if defined(__cplusplus)
extern "C" {
#endif

FLUTTER_PLUGIN_EXPORT void FFmpegKitFlutterPluginRegisterWithRegistrar(
    FlutterDesktopPluginRegistrarRef registrar);

#if defined(__cplusplus)
}
#endif

#endif  // FLUTTER_PLUGIN_FFMPEG_KIT_FLUTTER_PLUGIN_C_API_H_
]=])

target_include_directories(${PLUGIN_NAME} PRIVATE
  "${CMAKE_CURRENT_BINARY_DIR}")
target_include_directories(${PLUGIN_NAME} INTERFACE
  "${CMAKE_CURRENT_BINARY_DIR}/include")

target_link_libraries(${PLUGIN_NAME} PRIVATE flutter flutter_wrapper_plugin)

# No ffmpeg DLLs to bundle into the app.
set(ffmpeg_kit_flutter_new_audio_bundled_libraries "" PARENT_SCOPE)
