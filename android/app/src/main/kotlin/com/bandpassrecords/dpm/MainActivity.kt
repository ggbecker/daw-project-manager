package com.bandpassrecords.dpm

import android.os.Bundle
import com.ryanheise.audioservice.AudioServiceActivity
import java.io.File
import java.text.SimpleDateFormat
import java.util.Date
import java.util.Locale

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
    override fun onCreate(savedInstanceState: Bundle?) {
        installNativeCrashLogger()
        super.onCreate(savedInstanceState)
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
