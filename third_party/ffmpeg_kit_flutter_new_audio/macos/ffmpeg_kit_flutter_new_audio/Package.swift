// swift-tools-version: 5.9
//
// Stubbed SwiftPM manifest for the vendored ffmpeg_kit_flutter_new_audio.
//
// The upstream manifest declares eight remote binaryTargets (ffmpeg *.xcframework
// zips downloaded from GitHub). DAW Project Manager builds macOS with
// CocoaPods and never invokes ffmpeg-kit on macOS anyway, so this drops the
// binary targets entirely and ships only the no-op plugin target. See
// README-vendor.md.

import PackageDescription

let package = Package(
    name: "ffmpeg_kit_flutter_new_audio",
    platforms: [
        .macOS("10.15")
    ],
    products: [
        .library(name: "ffmpeg-kit-flutter-new-audio", targets: ["ffmpeg_kit_flutter_new_audio"])
    ],
    dependencies: [],
    targets: [
        .target(
            name: "ffmpeg_kit_flutter_new_audio",
            cSettings: [
                .headerSearchPath("include/ffmpeg_kit_flutter_new_audio")
            ]
        )
    ]
)
