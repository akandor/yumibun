package com.toepper.rocks.yumibun.playback

import android.media.AudioAttributes
import android.media.AudioFormat
import android.media.AudioTrack
import com.toepper.rocks.yumibun.data.GeneratorType
import kotlin.concurrent.thread
import kotlin.math.cos
import kotlin.math.sin
import kotlin.math.max

/**
 * Synthesizes binaural beats and isochronic tones with a streaming [AudioTrack], mirroring
 * the iOS ToneEngine. Parameters are set on the main thread and read once per render block;
 * the phase accumulators live only on the render thread.
 */
class ToneEngine {
    private val sampleRate = 44_100
    private val twoPi = 2.0 * Math.PI

    private var track: AudioTrack? = null
    private var renderThread: Thread? = null
    @Volatile private var running = false

    private val lock = Any()
    private var type: GeneratorType = GeneratorType.Binaural
    private var carrier = 200.0
    private var beat = 10.0
    @Volatile private var volume = 0.5f

    fun start(type: GeneratorType, carrier: Double, beat: Double, volume: Double) {
        configure(type, carrier, beat, volume)
        if (running) return

        val minBytes = AudioTrack.getMinBufferSize(
            sampleRate,
            AudioFormat.CHANNEL_OUT_STEREO,
            AudioFormat.ENCODING_PCM_FLOAT,
        )
        val track = AudioTrack.Builder()
            .setAudioAttributes(
                AudioAttributes.Builder()
                    .setUsage(AudioAttributes.USAGE_MEDIA)
                    .setContentType(AudioAttributes.CONTENT_TYPE_MUSIC)
                    .build()
            )
            .setAudioFormat(
                AudioFormat.Builder()
                    .setSampleRate(sampleRate)
                    .setEncoding(AudioFormat.ENCODING_PCM_FLOAT)
                    .setChannelMask(AudioFormat.CHANNEL_OUT_STEREO)
                    .build()
            )
            .setBufferSizeInBytes(max(minBytes, 4096))
            .setTransferMode(AudioTrack.MODE_STREAM)
            .build()

        this.track = track
        running = true
        track.play()
        renderThread = thread(name = "ToneEngine", priority = Thread.MAX_PRIORITY) { render(track) }
    }

    fun stop() {
        if (!running) return
        running = false
        renderThread?.join()
        renderThread = null
        track?.let { runCatching { it.stop(); it.release() } }
        track = null
    }

    fun configure(type: GeneratorType, carrier: Double, beat: Double, volume: Double) {
        synchronized(lock) {
            this.type = type
            this.carrier = carrier
            this.beat = beat
            this.volume = volume.toFloat()
        }
    }

    fun setVolume(value: Double) {
        volume = value.toFloat()
    }

    private fun render(track: AudioTrack) {
        val frames = 512
        val buffer = FloatArray(frames * 2)
        var phaseCarrier = 0.0
        var phaseRight = 0.0
        var pulsePhase = 0.0

        while (running) {
            val localType: GeneratorType
            val localCarrier: Double
            val localBeat: Double
            synchronized(lock) {
                localType = type
                localCarrier = carrier
                localBeat = beat
            }
            val vol = volume
            val carrierStep = twoPi * localCarrier / sampleRate

            var i = 0
            while (i < frames) {
                var left: Float
                var right: Float
                when (localType) {
                    GeneratorType.Binaural -> {
                        phaseCarrier += carrierStep
                        phaseRight += twoPi * (localCarrier + localBeat) / sampleRate
                        left = sin(phaseCarrier).toFloat()
                        right = sin(phaseRight).toFloat()
                    }
                    GeneratorType.Isochronic -> {
                        phaseCarrier += carrierStep
                        val tone = sin(phaseCarrier).toFloat()
                        pulsePhase += localBeat / sampleRate
                        if (pulsePhase >= 1) pulsePhase -= 1.0
                        val gate = (0.5 - 0.5 * cos(twoPi * pulsePhase)).toFloat()
                        left = tone * gate
                        right = left
                    }
                }
                if (phaseCarrier > twoPi) phaseCarrier -= twoPi
                if (phaseRight > twoPi) phaseRight -= twoPi

                buffer[i * 2] = left * vol
                buffer[i * 2 + 1] = right * vol
                i++
            }
            track.write(buffer, 0, buffer.size, AudioTrack.WRITE_BLOCKING)
        }
    }
}
