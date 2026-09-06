package com.bandpassrecords.dpm

import android.media.MediaCodec
import android.media.MediaCodecInfo
import android.media.MediaExtractor
import android.media.MediaFormat
import android.media.MediaMuxer
import java.io.File
import java.io.RandomAccessFile
import java.nio.ByteBuffer
import java.nio.ByteOrder

/**
 * Transcodes an audio file to AAC in an `.m4a` container, using only the
 * codecs built into Android.
 *
 * Why this exists: WhatsApp (and others) reject WAV/AIFF/FLAC as a direct
 * audio attachment, so a bounce has to be transcoded before sharing. On
 * desktop the app shells out to ffmpeg, but Android forbids spawning
 * executables, so `Process.run` there failed silently and the raw WAV went
 * out — and got dropped, leaving the recipient with just the message text.
 *
 * AAC rather than MP3 because Android ships no MP3 *encoder* (only a
 * decoder). This mirrors what macOS already does via `afconvert`, for the
 * same reason — Apple ships no MP3 encoder either — so `.m4a` is a format
 * this app has been sending from Macs all along.
 *
 * WAV is read straight from its RIFF header rather than through
 * `MediaExtractor` — that extractor rejects a lot of perfectly valid PCM
 * WAV on many devices (`setDataSource failed`), and it never handles 24-bit
 * or 32-bit-float bounces, which is what DAWs actually export. Everything
 * else still goes through `MediaExtractor` (FLAC yes, AIFF no). Callers fall
 * back to sharing the original file when this throws.
 */
object AudioShareConverter {

    private const val OUTPUT_MIME = "audio/mp4a-latm"
    private const val TIMEOUT_US = 10_000L

    /** Roughly transparent for a stereo music bounce, and small enough to send. */
    private fun bitRateFor(channelCount: Int): Int =
        if (channelCount >= 2) 192_000 else 128_000

    /**
     * Writes an AAC/`.m4a` version of [inputPath] to [outputPath].
     *
     * Throws on any failure, including an input `MediaExtractor` cannot read.
     * A partially written output is deleted, so the caller never finds a
     * truncated file that looks like a successful conversion.
     */
    fun convertToM4a(inputPath: String, outputPath: String) {
        val output = File(outputPath)
        output.parentFile?.mkdirs()
        try {
            if (inputPath.substringAfterLast('.', "").lowercase() == "wav") {
                transcodeWav(inputPath, outputPath)
            } else {
                transcode(inputPath, outputPath)
            }
        } catch (e: Throwable) {
            output.delete()
            throw e
        }
    }

    // ── WAV path ────────────────────────────────────────────────────────────
    // Parse the header ourselves, feed the PCM straight to the AAC encoder.

    private data class WavInfo(
        /** 1 = PCM integer, 3 = IEEE float. */
        val audioFormat: Int,
        val sampleRate: Int,
        val channelCount: Int,
        val bitsPerSample: Int,
        val dataOffset: Long,
        val dataSize: Long,
    )

    private fun leU16(b: ByteArray, off: Int): Int =
        (b[off].toInt() and 0xFF) or ((b[off + 1].toInt() and 0xFF) shl 8)

    private fun leU32(b: ByteArray, off: Int): Long =
        (b[off].toLong() and 0xFF) or
            ((b[off + 1].toLong() and 0xFF) shl 8) or
            ((b[off + 2].toLong() and 0xFF) shl 16) or
            ((b[off + 3].toLong() and 0xFF) shl 24)

    private fun readWavInfo(path: String): WavInfo {
        RandomAccessFile(path, "r").use { raf ->
            val riff = ByteArray(12)
            raf.readFully(riff)
            require(
                String(riff, 0, 4, Charsets.US_ASCII) == "RIFF" &&
                    String(riff, 8, 4, Charsets.US_ASCII) == "WAVE",
            ) { "Not a RIFF/WAVE file" }

            var af = 1
            var sr = 0
            var ch = 0
            var bps = 0
            var dataOffset = -1L
            var dataSize = -1L

            val hdr = ByteArray(8)
            while (raf.filePointer + 8 <= raf.length()) {
                raf.readFully(hdr)
                val id = String(hdr, 0, 4, Charsets.US_ASCII)
                val size = leU32(hdr, 4)
                val bodyStart = raf.filePointer
                when (id) {
                    "fmt " -> {
                        val body = ByteArray(size.toInt().coerceAtLeast(16))
                        raf.readFully(body, 0, minOf(size.toInt(), body.size))
                        af = leU16(body, 0)
                        ch = leU16(body, 2)
                        sr = leU32(body, 4).toInt()
                        bps = leU16(body, 14)
                        // WAVE_FORMAT_EXTENSIBLE — the real format tag is the
                        // first 2 bytes of the SubFormat GUID.
                        if (af == 0xFFFE && size >= 26) af = leU16(body, 24)
                    }
                    "data" -> {
                        dataOffset = bodyStart
                        dataSize = size
                    }
                }
                // RIFF chunks are word-aligned.
                raf.seek(bodyStart + size + (size and 1L))
                if (dataOffset >= 0 && sr > 0) break
            }

            require(sr > 0 && ch > 0 && bps > 0 && dataOffset >= 0) {
                "Malformed WAV header (rate=$sr ch=$ch bits=$bps)"
            }
            if (dataSize <= 0 || dataOffset + dataSize > raf.length()) {
                dataSize = raf.length() - dataOffset
            }
            return WavInfo(af, sr, ch, bps, dataOffset, dataSize)
        }
    }

    /** Converts [len] bytes of interleaved WAV samples in [src] to 16-bit LE PCM. */
    private fun toPcm16(src: ByteArray, len: Int, wav: WavInfo): ByteArray {
        val srcBps = wav.bitsPerSample / 8
        if (wav.audioFormat == 1 && wav.bitsPerSample == 16) {
            return if (len == src.size) src else src.copyOf(len)
        }
        val samples = len / srcBps
        val out = ByteArray(samples * 2)
        val ob = ByteBuffer.wrap(out).order(ByteOrder.LITTLE_ENDIAN)
        when {
            wav.audioFormat == 3 && wav.bitsPerSample == 32 -> {
                val fb = ByteBuffer.wrap(src, 0, len).order(ByteOrder.LITTLE_ENDIAN)
                repeat(samples) {
                    val v = (fb.float.coerceIn(-1f, 1f) * 32767f).toInt()
                    ob.putShort(v.toShort())
                }
            }
            wav.audioFormat == 1 && wav.bitsPerSample == 24 -> {
                var p = 0
                repeat(samples) {
                    val s24 = (src[p + 2].toInt() shl 16) or
                        ((src[p + 1].toInt() and 0xFF) shl 8) or
                        (src[p].toInt() and 0xFF)
                    ob.putShort((s24 shr 8).toShort())
                    p += 3
                }
            }
            wav.audioFormat == 1 && wav.bitsPerSample == 32 -> {
                val ib = ByteBuffer.wrap(src, 0, len).order(ByteOrder.LITTLE_ENDIAN)
                repeat(samples) { ob.putShort((ib.int shr 16).toShort()) }
            }
            wav.audioFormat == 1 && wav.bitsPerSample == 8 -> {
                var p = 0
                repeat(samples) {
                    ob.putShort((((src[p].toInt() and 0xFF) - 128) shl 8).toShort())
                    p++
                }
            }
            else -> throw IllegalArgumentException(
                "Unsupported WAV sample format ${wav.audioFormat}/${wav.bitsPerSample}-bit",
            )
        }
        return out
    }

    /**
     * Rewrites the input as a canonical 44-byte-header, 16-bit PCM WAV in a
     * temp file, then hands it to the shared [transcode] path (whose raw
     * branch handles `audio/raw`).
     *
     * Always rewriting — not just for 24-bit / float / 8-bit — means the
     * extractor only ever sees a textbook header, so an odd chunk order or a
     * `WAVE_FORMAT_EXTENSIBLE` `fmt ` block can't be what trips it.
     */
    private fun transcodeWav(inputPath: String, outputPath: String) {
        val wav = readWavInfo(inputPath)
        val normalised =
            File.createTempFile("wav16_", ".wav", File(outputPath).parentFile)
        try {
            writeCanonical16BitWav(inputPath, wav, normalised)
            transcode(normalised.path, outputPath)
        } finally {
            normalised.delete()
        }
    }

    private fun wavHeader16(sampleRate: Int, channels: Int, dataSize: Long): ByteArray {
        val buf = ByteBuffer.allocate(44).order(ByteOrder.LITTLE_ENDIAN)
        buf.put("RIFF".toByteArray(Charsets.US_ASCII))
        buf.putInt((36 + dataSize).toInt())
        buf.put("WAVE".toByteArray(Charsets.US_ASCII))
        buf.put("fmt ".toByteArray(Charsets.US_ASCII))
        buf.putInt(16)
        buf.putShort(1) // PCM
        buf.putShort(channels.toShort())
        buf.putInt(sampleRate)
        buf.putInt(sampleRate * channels * 2) // byte rate
        buf.putShort((channels * 2).toShort()) // block align
        buf.putShort(16) // bits per sample
        buf.put("data".toByteArray(Charsets.US_ASCII))
        buf.putInt(dataSize.toInt())
        return buf.array()
    }

    private fun writeCanonical16BitWav(inputPath: String, wav: WavInfo, out: File) {
        val srcBlock = (wav.bitsPerSample / 8) * wav.channelCount
        val readBuf = ByteArray(maxOf(1, 256 * 1024 / srcBlock) * srcBlock)
        val data16Size = wav.dataSize / (wav.bitsPerSample / 8) * 2
        RandomAccessFile(inputPath, "r").use { raf ->
            raf.seek(wav.dataOffset)
            out.outputStream().buffered().use { os ->
                os.write(wavHeader16(wav.sampleRate, wav.channelCount, data16Size))
                var remaining = wav.dataSize
                while (remaining > 0) {
                    val toRead = minOf(remaining, readBuf.size.toLong()).toInt()
                    raf.readFully(readBuf, 0, toRead)
                    remaining -= toRead
                    os.write(toPcm16(readBuf, toRead, wav))
                }
            }
        }
    }

    private fun transcode(inputPath: String, outputPath: String) {
        val extractor = MediaExtractor()
        var decoder: MediaCodec? = null
        var encoder: MediaCodec? = null
        var muxer: MediaMuxer? = null

        try {
            extractor.setDataSource(inputPath)

            val trackIndex = (0 until extractor.trackCount).firstOrNull { i ->
                extractor.getTrackFormat(i)
                    .getString(MediaFormat.KEY_MIME)
                    ?.startsWith("audio/") == true
            } ?: throw IllegalArgumentException("No audio track in $inputPath")

            extractor.selectTrack(trackIndex)
            val inputFormat = extractor.getTrackFormat(trackIndex)
            val inputMime = inputFormat.getString(MediaFormat.KEY_MIME)!!
            val sampleRate = inputFormat.getInteger(MediaFormat.KEY_SAMPLE_RATE)
            val channelCount = inputFormat.getInteger(MediaFormat.KEY_CHANNEL_COUNT)

            encoder = MediaCodec.createEncoderByType(OUTPUT_MIME).apply {
                configure(
                    MediaFormat.createAudioFormat(OUTPUT_MIME, sampleRate, channelCount).apply {
                        setInteger(
                            MediaFormat.KEY_AAC_PROFILE,
                            MediaCodecInfo.CodecProfileLevel.AACObjectLC,
                        )
                        setInteger(MediaFormat.KEY_BIT_RATE, bitRateFor(channelCount))
                    },
                    null,
                    null,
                    MediaCodec.CONFIGURE_FLAG_ENCODE,
                )
                start()
            }

            // WAV arrives as audio/raw — already PCM, so there is nothing to
            // decode and the extractor's samples feed the encoder directly.
            // Everything else (FLAC, and re-encoding a compressed source)
            // needs a decoder in front.
            if (inputMime != MediaFormat.MIMETYPE_AUDIO_RAW) {
                decoder = MediaCodec.createDecoderByType(inputMime).apply {
                    configure(inputFormat, null, null, 0)
                    start()
                }
            }

            muxer = MediaMuxer(outputPath, MediaMuxer.OutputFormat.MUXER_OUTPUT_MPEG_4)

            pump(extractor, decoder, encoder, muxer, sampleRate, channelCount)
        } finally {
            // Each release is guarded: one codec failing to stop must not
            // leak the others, and MediaMuxer.stop() throws if no track was
            // ever written (an input that produced no samples).
            runCatching { decoder?.stop() }
            runCatching { decoder?.release() }
            runCatching { encoder?.stop() }
            runCatching { encoder?.release() }
            runCatching { muxer?.stop() }
            runCatching { muxer?.release() }
            runCatching { extractor.release() }
        }
    }

    /**
     * Drives extractor → (decoder) → encoder → muxer until the encoder
     * reports end of stream.
     *
     * Presentation timestamps for the encoder are derived from the running
     * PCM byte count rather than copied from the extractor: on the raw path
     * the source timestamps can be coarse or absent, and the muxer needs
     * monotonically increasing values or the resulting file won't seek.
     */
    private fun pump(
        extractor: MediaExtractor,
        decoder: MediaCodec?,
        encoder: MediaCodec,
        muxer: MediaMuxer,
        sampleRate: Int,
        channelCount: Int,
    ) {
        val bytesPerFrame = channelCount * 2 // PCM 16-bit
        var pcmBytesSubmitted = 0L
        var muxerTrack = -1
        var muxerStarted = false

        var extractorDone = false
        var decoderDone = decoder == null
        var encoderDone = false

        // A decoder output buffer can hold more PCM than one encoder input
        // buffer accepts, so it is consumed across several iterations and
        // only released once drained.
        var pendingIndex = -1
        var pendingBuffer: ByteBuffer? = null

        val info = MediaCodec.BufferInfo()

        fun ptsUs(): Long = pcmBytesSubmitted / bytesPerFrame * 1_000_000L / sampleRate

        while (!encoderDone) {
            // 1. extractor → decoder (or straight to the encoder for raw PCM)
            if (!extractorDone) {
                val target = decoder ?: encoder
                val index = target.dequeueInputBuffer(TIMEOUT_US)
                if (index >= 0) {
                    val buffer = target.getInputBuffer(index)!!
                    val size = extractor.readSampleData(buffer, 0)
                    if (size < 0) {
                        extractorDone = true
                        // On the raw path this also ends the encoder's input.
                        target.queueInputBuffer(
                            index,
                            0,
                            0,
                            if (decoder == null) ptsUs() else 0L,
                            MediaCodec.BUFFER_FLAG_END_OF_STREAM,
                        )
                    } else {
                        val pts = if (decoder == null) ptsUs() else extractor.sampleTime
                        target.queueInputBuffer(index, 0, size, pts, 0)
                        if (decoder == null) pcmBytesSubmitted += size
                        extractor.advance()
                    }
                }
            }

            // 2. decoder → encoder
            if (decoder != null && !decoderDone) {
                if (pendingIndex < 0) {
                    val index = decoder.dequeueOutputBuffer(info, TIMEOUT_US)
                    if (index >= 0) {
                        if (info.size > 0) {
                            pendingIndex = index
                            pendingBuffer = decoder.getOutputBuffer(index)!!.apply {
                                position(info.offset)
                                limit(info.offset + info.size)
                            }
                        } else {
                            decoder.releaseOutputBuffer(index, false)
                        }
                        if (info.flags and MediaCodec.BUFFER_FLAG_END_OF_STREAM != 0) {
                            decoderDone = true
                        }
                    }
                }

                if (pendingIndex >= 0) {
                    val source = pendingBuffer!!
                    val index = encoder.dequeueInputBuffer(TIMEOUT_US)
                    if (index >= 0) {
                        val dest = encoder.getInputBuffer(index)!!
                        val chunk = minOf(dest.remaining(), source.remaining())
                        val slice = source.slice().apply { limit(chunk) }
                        dest.put(slice)
                        source.position(source.position() + chunk)

                        encoder.queueInputBuffer(index, 0, chunk, ptsUs(), 0)
                        pcmBytesSubmitted += chunk

                        if (!source.hasRemaining()) {
                            decoder.releaseOutputBuffer(pendingIndex, false)
                            pendingIndex = -1
                            pendingBuffer = null
                        }
                    }
                }

                // Only signal end of input once every decoded byte is through.
                if (decoderDone && pendingIndex < 0) {
                    val index = encoder.dequeueInputBuffer(TIMEOUT_US)
                    if (index >= 0) {
                        encoder.queueInputBuffer(
                            index,
                            0,
                            0,
                            ptsUs(),
                            MediaCodec.BUFFER_FLAG_END_OF_STREAM,
                        )
                    } else {
                        // No input buffer free yet — retry next iteration
                        // rather than dropping the EOS on the floor.
                        decoderDone = false
                    }
                }
            }

            // 3. encoder → muxer
            when (val index = encoder.dequeueOutputBuffer(info, TIMEOUT_US)) {
                MediaCodec.INFO_OUTPUT_FORMAT_CHANGED -> {
                    if (muxerStarted) throw IllegalStateException("Encoder format changed twice")
                    muxerTrack = muxer.addTrack(encoder.outputFormat)
                    muxer.start()
                    muxerStarted = true
                }
                MediaCodec.INFO_TRY_AGAIN_LATER -> Unit
                else -> if (index >= 0) {
                    // Codec-config bytes go into the track format the muxer
                    // already took from outputFormat; writing them as a
                    // sample as well produces a file some players reject.
                    val isConfig = info.flags and MediaCodec.BUFFER_FLAG_CODEC_CONFIG != 0
                    if (info.size > 0 && !isConfig) {
                        if (!muxerStarted) throw IllegalStateException("Muxer not started")
                        val buffer = encoder.getOutputBuffer(index)!!.apply {
                            position(info.offset)
                            limit(info.offset + info.size)
                        }
                        muxer.writeSampleData(muxerTrack, buffer, info)
                    }
                    encoder.releaseOutputBuffer(index, false)
                    if (info.flags and MediaCodec.BUFFER_FLAG_END_OF_STREAM != 0) {
                        encoderDone = true
                    }
                }
            }
        }

        if (!muxerStarted) {
            throw IllegalStateException("Encoder produced no output for the input file")
        }
    }
}
