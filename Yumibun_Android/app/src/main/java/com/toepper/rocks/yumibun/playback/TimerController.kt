package com.toepper.rocks.yumibun.playback

import android.content.Context
import android.media.AudioAttributes
import android.media.MediaPlayer
import android.os.VibrationEffect
import android.os.VibratorManager
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableFloatStateOf
import androidx.compose.runtime.mutableIntStateOf
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.setValue
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.Job
import kotlinx.coroutines.delay
import kotlinx.coroutines.isActive
import kotlinx.coroutines.launch

/**
 * Drives the active sleep / countdown / pomodoro timer and the alarm that rings when a
 * countdown or pomodoro reaches zero. App-scoped (held by [com.toepper.rocks.yumibun.YumibunApp])
 * so it keeps running with the UI backgrounded, alongside [SoundMixer].
 *
 * Sleep timers stop playback at zero; countdown and pomodoro ring the alarm and leave the
 * mix playing — matching the iOS/web behaviour.
 */
class TimerController(context: Context, private val mixer: SoundMixer) {

    enum class Kind(val title: String) {
        Sleep("Sleep timer"),
        Countdown("Countdown"),
        Pomodoro("Pomodoro");

        val stopsPlayback: Boolean get() = this == Sleep
    }

    private val appContext = context.applicationContext
    private val prefs = appContext.getSharedPreferences("yumibun", Context.MODE_PRIVATE)
    private val scope = CoroutineScope(SupervisorJobMain())

    var kind by mutableStateOf<Kind?>(null)
        private set
    /** Remaining whole seconds, for the chip's countdown label. */
    var remaining by mutableIntStateOf(0)
        private set
    var ringing by mutableStateOf<Kind?>(null)
        private set

    val isActive: Boolean get() = kind != null || ringing != null

    /** mm:ss, or h:mm:ss past an hour. */
    val display: String
        get() {
            val total = remaining
            val h = total / 3600
            val m = (total % 3600) / 60
            val s = total % 60
            return if (h > 0) "%d:%02d:%02d".format(h, m, s) else "%02d:%02d".format(m, s)
        }

    // MARK: Alarm settings ---------------------------------------------------

    var alarmVolume by mutableFloatStateOf(prefs.getFloat(KEY_ALARM_VOLUME, 0.8f))
        private set
    var vibrationEnabled by mutableStateOf(prefs.getBoolean(KEY_ALARM_VIBRATION, true))
        private set
    var isPreviewing by mutableStateOf(false)
        private set

    fun updateAlarmVolume(value: Float) {
        alarmVolume = value
        prefs.edit().putFloat(KEY_ALARM_VOLUME, value).apply()
        alarmPlayer?.setVolume(value, value)
    }

    fun updateVibration(enabled: Boolean) {
        vibrationEnabled = enabled
        prefs.edit().putBoolean(KEY_ALARM_VIBRATION, enabled).apply()
        if (!enabled) stopVibration()
        else if (isPreviewing || ringing != null) startVibration(loop = ringing != null)
    }

    // MARK: Timer ------------------------------------------------------------

    private var ticker: Job? = null

    fun start(kind: Kind, durationSeconds: Int) {
        cancel()
        if (durationSeconds <= 0) return
        this.kind = kind
        remaining = durationSeconds
        val endAt = System.currentTimeMillis() + durationSeconds * 1000L
        ticker = scope.launch {
            while (isActive) {
                val leftMs = endAt - System.currentTimeMillis()
                if (leftMs <= 0) break
                remaining = ((leftMs + 999) / 1000).toInt()
                delay(minOf(500L, leftMs))
            }
            if (isActive) fire()
        }
    }

    /** Stops the running countdown and silences the alarm if it's ringing. */
    fun cancel() {
        ticker?.cancel()
        ticker = null
        kind = null
        remaining = 0
        if (ringing != null) {
            ringing = null
            stopAlarm()
        }
    }

    private fun fire() {
        val finished = kind
        ticker = null
        kind = null
        remaining = 0
        when (finished) {
            Kind.Sleep -> mixer.clearAll()
            Kind.Countdown, Kind.Pomodoro -> {
                ringing = finished
                playAlarm(loop = true)
            }
            null -> {}
        }
    }

    // MARK: Alarm playback ---------------------------------------------------

    private var alarmPlayer: MediaPlayer? = null

    fun togglePreview() {
        if (isPreviewing) stopPreview() else startPreview()
    }

    private fun startPreview() {
        playAlarm(loop = false)
        isPreviewing = true
        val player = alarmPlayer ?: return
        val duration = player.duration.toLong().coerceAtLeast(300)
        scope.launch {
            delay(duration)
            if (isPreviewing) stopPreview()
        }
    }

    private fun stopPreview() {
        if (!isPreviewing) return
        stopAlarm()
        isPreviewing = false
    }

    private fun playAlarm(loop: Boolean) {
        stopAlarm()
        alarmPlayer = runCatching {
            val afd = appContext.assets.openFd("sounds/alarm.mp3")
            MediaPlayer().apply {
                setAudioAttributes(
                    AudioAttributes.Builder()
                        .setUsage(AudioAttributes.USAGE_ALARM)
                        .setContentType(AudioAttributes.CONTENT_TYPE_SONIFICATION)
                        .build()
                )
                setDataSource(afd.fileDescriptor, afd.startOffset, afd.length)
                afd.close()
                isLooping = loop
                setVolume(alarmVolume, alarmVolume)
                prepare()
                start()
            }
        }.getOrNull()
        if (vibrationEnabled) startVibration(loop = loop)
    }

    private fun stopAlarm() {
        alarmPlayer?.let { runCatching { it.stop(); it.release() } }
        alarmPlayer = null
        stopVibration()
    }

    // MARK: Vibration --------------------------------------------------------

    private val vibrator by lazy {
        (appContext.getSystemService(Context.VIBRATOR_MANAGER_SERVICE) as VibratorManager).defaultVibrator
    }

    private fun startVibration(loop: Boolean) {
        runCatching {
            val timings = longArrayOf(0, 400, 250)
            val amplitudes = intArrayOf(0, 255, 0)
            val effect = VibrationEffect.createWaveform(timings, amplitudes, if (loop) 0 else -1)
            vibrator.vibrate(effect)
        }
    }

    private fun stopVibration() {
        runCatching { vibrator.cancel() }
    }

    companion object {
        private const val KEY_ALARM_VOLUME = "alarmVolume"
        private const val KEY_ALARM_VIBRATION = "alarmVibration"
    }
}

private fun SupervisorJobMain() = kotlinx.coroutines.SupervisorJob() + Dispatchers.Main.immediate
