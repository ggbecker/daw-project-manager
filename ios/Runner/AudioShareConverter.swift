import AVFoundation
import Foundation

/// Transcodes an audio file to AAC in an `.m4a` container using AVFoundation,
/// the iOS counterpart of `AudioShareConverter.kt` on Android.
///
/// Why this exists: WhatsApp (and others) reject WAV/AIFF/FLAC as a direct
/// audio attachment, so a bounce has to be transcoded before sharing. iOS
/// cannot spawn an ffmpeg subprocess any more than Android can, so the
/// desktop `Process.run` path is unavailable here.
///
/// AAC rather than MP3 because Apple has never shipped an MP3 *encoder* —
/// the same reason the macOS build uses `afconvert` to produce `.m4a`. Unlike
/// Android's MediaExtractor, AVFoundation does read AIFF, so iOS covers every
/// format in `AudioAnalysisService.extensionsNeedingConversionForSharing`.
enum AudioShareConverter {

    enum ConversionError: LocalizedError {
        case unsupportedInput(String)
        case exportSessionUnavailable
        case exportFailed(String)
        case producedNothing

        var errorDescription: String? {
            switch self {
            case .unsupportedInput(let path):
                return "AVFoundation cannot read \(path)"
            case .exportSessionUnavailable:
                return "Could not create an AAC export session"
            case .exportFailed(let reason):
                return "Export failed: \(reason)"
            case .producedNothing:
                return "Export reported success but wrote no audio"
            }
        }
    }

    /// Writes an AAC/`.m4a` version of [inputPath] to [outputPath], calling
    /// [completion] with nil on success or the failure otherwise.
    ///
    /// Asynchronous because `exportAsynchronously` is; the caller replies on
    /// the platform channel from within [completion].
    static func convertToM4a(
        inputPath: String,
        outputPath: String,
        completion: @escaping (Error?) -> Void
    ) {
        let inputURL = URL(fileURLWithPath: inputPath)
        let outputURL = URL(fileURLWithPath: outputPath)

        do {
            try FileManager.default.createDirectory(
                at: outputURL.deletingLastPathComponent(),
                withIntermediateDirectories: true
            )
            // AVAssetExportSession refuses to start if the destination
            // already exists, which it will on a repeat share of the same
            // track.
            if FileManager.default.fileExists(atPath: outputPath) {
                try FileManager.default.removeItem(at: outputURL)
            }
        } catch {
            completion(error)
            return
        }

        let asset = AVURLAsset(url: inputURL)
        guard
            let session = AVAssetExportSession(
                asset: asset,
                presetName: AVAssetExportPresetAppleM4A
            )
        else {
            completion(ConversionError.exportSessionUnavailable)
            return
        }

        session.outputURL = outputURL
        session.outputFileType = .m4a

        session.exportAsynchronously {
            switch session.status {
            case .completed:
                // A zero-byte export is worse than sharing the original: the
                // receiving app silently drops it and the recipient sees only
                // the message text.
                let size = (try? FileManager.default.attributesOfItem(
                    atPath: outputPath
                )[.size] as? Int) ?? 0
                if size > 0 {
                    completion(nil)
                } else {
                    try? FileManager.default.removeItem(at: outputURL)
                    completion(ConversionError.producedNothing)
                }
            case .cancelled:
                try? FileManager.default.removeItem(at: outputURL)
                completion(ConversionError.exportFailed("cancelled"))
            default:
                try? FileManager.default.removeItem(at: outputURL)
                let reason = session.error?.localizedDescription
                    ?? "status \(session.status.rawValue)"
                completion(ConversionError.exportFailed(reason))
            }
        }
    }
}
