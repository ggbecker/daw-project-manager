package com.bandpassrecords.dpm

import android.media.MediaCodec
import android.media.MediaCodecInfo
import android.media.MediaExtractor
import android.media.MediaFormat
import android.media.MediaMuxer
import java.io.File
import java.nio.ByteBuffer

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
 * Supported inputs are whatever `MediaExtractor` can open: WAV and FLAC yes,
 * AIFF no. Callers fall back to sharing the original file when this throws.
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
            transcode(inputPath, outputPath)
        } catch (e: Throwable) {
            output.delete()
            throw e
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
