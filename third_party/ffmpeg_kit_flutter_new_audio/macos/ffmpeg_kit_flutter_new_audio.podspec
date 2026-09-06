#
# Stubbed macOS podspec for the vendored ffmpeg_kit_flutter_new_audio.
#
# The upstream spec vendors eight ffmpeg *.framework bundles (downloaded by
# scripts/setup_macos.sh in a prepare_command) and CodeSign fails on them in
# CI ("code object is not signed at all"). DAW Project Manager never invokes
# ffmpeg-kit on macOS - AudioAnalysisService only routes to the in-process
# library on Android/iOS (_usesInProcessFfmpeg); the macOS path uses
# afconvert / a PATH ffmpeg instead. So this ships only the no-op Objective-C
# plugin class that GeneratedPluginRegistrant.swift needs: no frameworks, no
# prepare_command, no download. See README-vendor.md.
#
Pod::Spec.new do |s|
  s.name             = 'ffmpeg_kit_flutter_new_audio'
  s.version          = '8.1.2'
  s.summary          = 'FFmpeg Kit for Flutter (desktop-stubbed vendor copy)'
  s.description      = 'Vendored with the macOS native layer stubbed to a no-op.'
  s.homepage         = 'https://github.com/sk3llo/ffmpeg_kit_flutter'
  s.license          = { :file => '../LICENSE' }
  s.author           = { 'Anton Karpenko' => 'kapraton@gmail.com' }

  s.platform            = :osx
  s.osx.deployment_target = '10.15'
  s.requires_arc        = true
  s.static_framework    = true

  s.source              = { :path => '.' }
  s.source_files        = 'ffmpeg_kit_flutter_new_audio/Sources/ffmpeg_kit_flutter_new_audio/**/*.{h,m}'
  s.public_header_files = 'ffmpeg_kit_flutter_new_audio/Sources/ffmpeg_kit_flutter_new_audio/include/**/*.h'

  s.dependency          'FlutterMacOS'
  s.pod_target_xcconfig = { 'DEFINES_MODULE' => 'YES' }
end
