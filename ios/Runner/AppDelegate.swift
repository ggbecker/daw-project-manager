import Flutter
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
    registerAudioConvertChannel(engineBridge.pluginRegistry)
  }

  /// Backs `AudioAnalysisService.convertForSharing` on iOS. Mirrors the
  /// identically-named channel registered in MainActivity.kt on Android —
  /// same channel name, same method, same arguments, so the Dart side has a
  /// single code path for both.
  private func registerAudioConvertChannel(_ registry: FlutterPluginRegistry) {
    let messenger = registry.registrar(forPlugin: "AudioShareConverter")!.messenger()
    let channel = FlutterMethodChannel(
      name: "com.bandpassrecords.dpm/audio_convert",
      binaryMessenger: messenger
    )

    channel.setMethodCallHandler { call, result in
      guard call.method == "toM4a" else {
        result(FlutterMethodNotImplemented)
        return
      }
      guard
        let args = call.arguments as? [String: Any],
        let input = args["input"] as? String,
        let output = args["output"] as? String
      else {
        result(
          FlutterError(
            code: "bad_args",
            message: "input and output are required",
            details: nil
          )
        )
        return
      }

      AudioShareConverter.convertToM4a(inputPath: input, outputPath: output) { error in
        // exportAsynchronously' completion runs off the main thread; channel
        // replies have to be delivered on it.
        DispatchQueue.main.async {
          if let error = error {
            result(
              FlutterError(
                code: "convert_failed",
                message: error.localizedDescription,
                details: nil
              )
            )
          } else {
            result(output)
          }
        }
      }
    }
  }
}
