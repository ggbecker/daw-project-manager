// No-op replacement for ffmpeg_kit_flutter_new_audio's Linux plugin, used by
// the Flatpak build only — see CMakeLists.txt in this directory and
// com.bandpassrecords.dpm.yml.
//
// DAW Project Manager never invokes ffmpeg-kit on Linux (that path shells out
// to a PATH ffmpeg instead), so all this has to do is define the one symbol
// the generated plugin registrant links against. Calling into the ffmpeg-kit
// method channel on Linux would raise MissingPluginException — nothing does.
//
// The header filename really is "f_fmpeg_..." — the Flutter tool snake-cases
// the pluginClass and inserts a separator before every capital after the
// first. The include path mirrors the real plugin's own .cc.

#include "include/ffmpeg_kit_flutter_new_audio/f_fmpeg_kit_flutter_plugin.h"

void f_fmpeg_kit_flutter_plugin_register_with_registrar(
    FlPluginRegistrar* registrar) {
  (void)registrar;
}
