import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import 'audio_analysis_service.dart';

/// Persistent on-disk cache for [WaveformPeaks].
///
/// Each entry is a small binary file (~16 KB for 2 000 frames) stored under
/// `<app-support>/waveform_cache/`. The file embeds the source file's
/// modification timestamp so stale entries are automatically ignored when the
/// audio file changes.
///
/// Binary layout (little-endian):
///   4  uint32  magic = 0x57464B50 ('WFPK')
///   4  uint32  version = 1
///   8  int64   source file mtime (microseconds since epoch)
///   4  int32   sampleRate
///   8  float64 durationSeconds
///   4  int32   frameCount
///   4  int32   pathLen (UTF-8 bytes)
///   N  bytes   source file path (UTF-8)
///  F*4 float32 minValues[F]
///  F*4 float32 maxValues[F]
class WaveformDiskCache {
  static const _magic = 0x57464B50;
  static const _version = 1;

  static Future<String> _entryPath(String filePath) async {
    final dir = await getApplicationSupportDirectory();
    // FNV-1a 32-bit hash of the path — collisions are guarded by the stored path.
    int hash = 0x811c9dc5;
    for (final byte in utf8.encode(filePath)) {
      hash ^= byte;
      hash = (hash * 0x01000193) & 0xFFFFFFFF;
    }
    final hex = hash.toRadixString(16).padLeft(8, '0');
    return p.join(dir.path, 'waveform_cache', '$hex.wfpk');
  }

  static Future<WaveformPeaks?> load(String filePath) async {
    try {
      final entryPath = await _entryPath(filePath);
      final file = File(entryPath);
      if (!file.existsSync()) return null;

      final bytes = await file.readAsBytes();
      if (bytes.length < 36) return null;

      final buf = ByteData.sublistView(bytes);
      int off = 0;

      if (buf.getUint32(off, Endian.little) != _magic) return null;
      off += 4;
      if (buf.getUint32(off, Endian.little) != _version) return null;
      off += 4;

      final cachedMtime = buf.getInt64(off, Endian.little); off += 8;
      final sampleRate = buf.getInt32(off, Endian.little); off += 4;
      final duration = buf.getFloat64(off, Endian.little); off += 8;
      final frameCount = buf.getInt32(off, Endian.little); off += 4;
      final pathLen = buf.getInt32(off, Endian.little); off += 4;

      if (off + pathLen > bytes.length) return null;
      final storedPath = utf8.decode(bytes.sublist(off, off + pathLen));
      if (storedPath != filePath) return null; // hash collision guard
      off += pathLen;

      // Invalidate if source file was modified since caching.
      final currentMtime =
          File(filePath).statSync().modified.microsecondsSinceEpoch;
      if (cachedMtime != currentMtime) return null;

      if (off + frameCount * 8 > bytes.length) return null;
      final minValues = List<double>.generate(
          frameCount, (i) => buf.getFloat32(off + i * 4, Endian.little));
      off += frameCount * 4;
      final maxValues = List<double>.generate(
          frameCount, (i) => buf.getFloat32(off + i * 4, Endian.little));

      return WaveformPeaks(
        minValues: minValues,
        maxValues: maxValues,
        sampleRate: sampleRate,
        durationSeconds: duration,
      );
    } catch (_) {
      return null;
    }
  }

  static Future<void> save(String filePath, WaveformPeaks peaks) async {
    try {
      final mtime =
          File(filePath).statSync().modified.microsecondsSinceEpoch;
      final pathBytes = utf8.encode(filePath);
      final frameCount = peaks.frameCount;

      final header = ByteData(36);
      header.setUint32(0, _magic, Endian.little);
      header.setUint32(4, _version, Endian.little);
      header.setInt64(8, mtime, Endian.little);
      header.setInt32(16, peaks.sampleRate, Endian.little);
      header.setFloat64(20, peaks.durationSeconds, Endian.little);
      header.setInt32(28, frameCount, Endian.little);
      header.setInt32(32, pathBytes.length, Endian.little);

      final minData = ByteData(frameCount * 4);
      final maxData = ByteData(frameCount * 4);
      for (int i = 0; i < frameCount; i++) {
        minData.setFloat32(i * 4, peaks.minValues[i], Endian.little);
        maxData.setFloat32(i * 4, peaks.maxValues[i], Endian.little);
      }

      final builder = BytesBuilder(copy: false);
      builder.add(header.buffer.asUint8List());
      builder.add(pathBytes);
      builder.add(minData.buffer.asUint8List());
      builder.add(maxData.buffer.asUint8List());

      final entryPath = await _entryPath(filePath);
      final dir = Directory(p.dirname(entryPath));
      if (!dir.existsSync()) await dir.create(recursive: true);
      await File(entryPath).writeAsBytes(builder.toBytes());
    } catch (_) {}
  }
}
