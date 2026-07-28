package com.toepper.rocks.yumibun.playback

import android.content.Context
import android.content.Intent
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.setValue
import androidx.core.content.ContextCompat
import com.toepper.rocks.yumibun.data.GeneratorPreset
import com.toepper.rocks.yumibun.data.GeneratorType

/**
 * What the UI talks to: which preset is playing (if any), and play/stop/volume. Only one
 * generator runs at a time; it layers on top of the ambient mix. App-scoped so it can keep
 * playing (via [PlaybackService]) while navigating or backgrounded.
 */
class GeneratorController(context: Context) {

    private val appContext = context.applicationContext

    data class Active(val id: String, val name: String, val type: GeneratorType)

    var active by mutableStateOf<Active?>(null)
        private set

    /** Set by [PlaybackService] so state changes refresh the notification. */
    var onStateChanged: (() -> Unit)? = null

    private val engine = ToneEngine()
    private val defaultCarrier = 200.0

    /** Last frequencies entered in the custom sheet, reused when Custom is played. */
    var customCarrier by mutableStateOf(200.0)
    var customBeat by mutableStateOf(10.0)

    private var lastVolume = 0.5

    val isActive: Boolean get() = active != null

    fun isPlaying(preset: GeneratorPreset, type: GeneratorType): Boolean =
        active?.id == preset.id && active?.type == type

    fun toggle(preset: GeneratorPreset, type: GeneratorType, volume: Double) {
        if (isPlaying(preset, type)) stop() else play(preset, type, volume)
    }

    fun play(preset: GeneratorPreset, type: GeneratorType, volume: Double) {
        val carrier = if (preset.isCustom) customCarrier else defaultCarrier
        val beat = if (preset.isCustom) customBeat else (preset.frequency ?: customBeat)
        lastVolume = volume
        active = Active(preset.id, preset.displayName, type)
        engine.start(type, carrier, beat, volume)
        ContextCompat.startForegroundService(appContext, Intent(appContext, PlaybackService::class.java))
        onStateChanged?.invoke()
    }

    fun retuneCustomIfPlaying(type: GeneratorType) {
        if (!isPlaying(GeneratorPreset.custom, type)) return
        engine.configure(type, customCarrier, customBeat, lastVolume)
    }

    fun setVolume(value: Double) {
        lastVolume = value
        engine.setVolume(value)
    }

    fun stop() {
        if (active == null) return
        active = null
        engine.stop()
        onStateChanged?.invoke()
    }
}
