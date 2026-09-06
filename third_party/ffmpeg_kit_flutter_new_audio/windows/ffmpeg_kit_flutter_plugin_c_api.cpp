// Stubbed Windows plugin entry point for the vendored
// ffmpeg_kit_flutter_new_audio.
//
// DAW Project Manager never invokes ffmpeg-kit on Windows (that path shells
// out to a bundled/PATH ffmpeg instead), so all this has to do is define the
// one symbol the generated plugin registrant links against. Calling into the
// ffmpeg-kit method channel on Windows would raise MissingPluginException -
// nothing does.

#include "include/ffmpeg_kit_flutter_new_audio/f_fmpeg_kit_flutter_plugin.h"

void FFmpegKitFlutterPluginRegisterWithRegistrar(
    FlutterDesktopPluginRegistrarRef registrar) {
  (void)registrar;
}
