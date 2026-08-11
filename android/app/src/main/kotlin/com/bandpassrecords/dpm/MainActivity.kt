package com.bandpassrecords.dpm

import android.os.Bundle
import com.ryanheise.audioservice.AudioServiceActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File
import java.text.SimpleDateFormat
import java.util.Date
import java.util.Locale
import java.util.concurrent.Executors

/// Android-only: catches native (JVM-level) uncaught exceptions that never
/// reach Dart — e.g. a crash inside a plugin's Kotlin/Java code — and writes
/// them next to CrashLogger's Dart-side log file before letting the OS's
/// default handler take over (so the process still dies/restarts as normal,
/// but a trace is left behind).
///
/// Written to <filesDir>/app_flutter/logs/native_crash_log.txt, matching
/// where path_provider's getApplicationSupportDirectory() resolves on
/// Android, so it sits alongside crash_log.txt written by lib/services/crash_logger.dart.
class MainActivity : AudioServiceActivity() {
    /// Single worker for audio transcoding: the MediaCodec loop in
    /// AudioShareConverter is synchronous and can run for seconds on a long
    /// bounce, so it must never touch the platform channel's main thread.
    private val conversionExecutor = Executors.newSingleThreadExecutor()

    override fun onCreate(savedInstanceState: Bundle?) {
        installNativeCrashLogger()
        super.onCreate(savedInstanceState)
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        registerAudioConvertChannel(flutterEngine)
    }

    override fun onDestroy() {
        conversionExecutor.shutdown()
        super.onDestroy()
    }

    /// Backs AudioAnalysisService.convertForSharing on Android — see the
    /// channel name in lib/services/audio_analysis_service.dart.
    private fun registerAudioConvertChannel(flutterEngine: FlutterEngine) {
        val channel = MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            "com.bandpassrecords.dpm/audio_convert",
        )
        channel.setMethodCallHandler { call, result ->
            if (call.method != "toM4a") {
                result.notImplemented()
                return@setMethodCallHandler
            }
            val input = call.argument<String>("input")
            val output = call.argument<String>("output")
            if (input == null || output == null) {
                result.error("bad_args", "input and output are required", null)
                return@setMethodCallHandler
            }
            conversionExecutor.execute {
                try {
                    AudioShareConverter.convertToM4a(input, output)
                    // MethodChannel replies must be delivered on the main
                    // thread; this handler is already off it.
                    runOnUiThread { result.success(output) }
                } catch (e: Throwable) {
                    runOnUiThread {
                        result.error("convert_failed", e.message, null)
                    }
                }
            }
        }
    }

    private fun installNativeCrashLogger() {
        val previousHandler = Thread.getDefaultUncaughtExceptionHandler()
        Thread.setDefaultUncaughtExceptionHandler { thread, throwable ->
            try {
                val dir = File(filesDir, "app_flutter/logs")
                if (!dir.exists()) dir.mkdirs()
                val file = File(dir, "native_crash_log.txt")
                val timestamp = SimpleDateFormat("yyyy-MM-dd'T'HH:mm:ss", Locale.US).format(Date())
                file.appendText("--- $timestamp [native] ---\n")
                file.appendText("Thread: ${thread.name}\n")
                file.appendText(android.util.Log.getStackTraceString(throwable))
                file.appendText("\n")
            } catch (loggingFailure: Throwable) {
                // Logging must never block the crash handoff to the OS.
            }
            previousHandler?.uncaughtException(thread, throwable)
        }
    }
}
