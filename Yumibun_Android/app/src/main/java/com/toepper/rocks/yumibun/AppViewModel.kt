package com.toepper.rocks.yumibun

import android.app.Application
import android.content.SharedPreferences
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.setValue
import androidx.compose.runtime.snapshots.SnapshotStateList
import androidx.compose.runtime.toMutableStateList
import androidx.lifecycle.AndroidViewModel
import com.toepper.rocks.yumibun.data.MixShare
import com.toepper.rocks.yumibun.data.Preset
import com.toepper.rocks.yumibun.data.Sound
import com.toepper.rocks.yumibun.data.SoundCatalog
import com.toepper.rocks.yumibun.playback.GeneratorController
import com.toepper.rocks.yumibun.playback.SoundMixer
import com.toepper.rocks.yumibun.playback.TimerController
import com.toepper.rocks.yumibun.ui.theme.AccentPalette
import com.toepper.rocks.yumibun.ui.theme.AppearanceMode
import com.toepper.rocks.yumibun.ui.theme.HomeStyle

/**
 * UI-scoped state: favorites, presets and settings (persisted in SharedPreferences).
 * The audio mixer itself is app-scoped ([SoundMixer]) so playback survives the UI; this
 * class delegates every mixer call to it.
 */
class AppViewModel(app: Application) : AndroidViewModel(app) {

    private val prefs: SharedPreferences =
        app.getSharedPreferences("yumibun", Application.MODE_PRIVATE)

    private val mixer: SoundMixer get() = getApplication<YumibunApp>().mixer
    private val timer: TimerController get() = getApplication<YumibunApp>().timer
    val generator: GeneratorController get() = getApplication<YumibunApp>().generator

    // MARK: Settings ---------------------------------------------------------

    var appearance by mutableStateOf(AppearanceMode.from(prefs.getString(KEY_APPEARANCE, null)))
        private set
    var accent by mutableStateOf(AccentPalette.from(prefs.getString(KEY_ACCENT, null)))
        private set
    var homeStyle by mutableStateOf(HomeStyle.from(prefs.getString(KEY_HOME_STYLE, null)))
        private set

    fun chooseAppearance(mode: AppearanceMode) {
        appearance = mode
        prefs.edit().putString(KEY_APPEARANCE, mode.key).apply()
    }

    fun chooseAccent(palette: AccentPalette) {
        accent = palette
        prefs.edit().putString(KEY_ACCENT, palette.key).apply()
    }

    fun chooseHomeStyle(style: HomeStyle) {
        homeStyle = style
        prefs.edit().putString(KEY_HOME_STYLE, style.key).apply()
    }

    // MARK: Favorites --------------------------------------------------------

    val favorites: SnapshotStateList<String> =
        (prefs.getStringSet(KEY_FAVORITES, emptySet()) ?: emptySet()).toMutableStateList()

    fun isFavorite(sound: Sound): Boolean = favorites.contains(sound.id)

    fun toggleFavorite(sound: Sound) {
        if (!favorites.remove(sound.id)) favorites.add(sound.id)
        prefs.edit().putStringSet(KEY_FAVORITES, favorites.toSet()).apply()
    }

    val favoriteSounds: List<Sound>
        get() = SoundCatalog.allSounds.filter { favorites.contains(it.id) }

    // MARK: Presets ----------------------------------------------------------

    val presets: SnapshotStateList<Preset> =
        Preset.listFromJson(prefs.getString(KEY_PRESETS, null)).toMutableStateList()

    private fun persistPresets() {
        prefs.edit().putString(KEY_PRESETS, Preset.listToJson(presets.toList())).apply()
    }

    fun savePreset(name: String) {
        if (!mixer.hasSelection) return
        val finalName = name.trim().ifEmpty { mixer.suggestedPresetName() }
        presets.add(Preset(name = finalName, volumes = mixer.volumes.toMap(), masterVolume = mixer.masterVolume))
        persistPresets()
    }

    fun deletePreset(preset: Preset) {
        presets.removeAll { it.id == preset.id }
        persistPresets()
    }

    fun renamePreset(preset: Preset, name: String) {
        val trimmed = name.trim()
        if (trimmed.isEmpty()) return
        val i = presets.indexOfFirst { it.id == preset.id }
        if (i >= 0) {
            presets[i] = presets[i].copy(name = trimmed)
            persistPresets()
        }
    }

    fun movePresetUp(preset: Preset) {
        val i = presets.indexOfFirst { it.id == preset.id }
        if (i > 0) {
            presets.add(i - 1, presets.removeAt(i))
            persistPresets()
        }
    }

    fun movePresetDown(preset: Preset) {
        val i = presets.indexOfFirst { it.id == preset.id }
        if (i in 0 until presets.size - 1) {
            presets.add(i + 1, presets.removeAt(i))
            persistPresets()
        }
    }

    fun canMoveUp(preset: Preset): Boolean = presets.indexOfFirst { it.id == preset.id } > 0
    fun canMoveDown(preset: Preset): Boolean {
        val i = presets.indexOfFirst { it.id == preset.id }
        return i >= 0 && i < presets.size - 1
    }

    fun playAllPresets() = mixer.playQueue(presets.toList())

    // Queue transport
    val hasQueue: Boolean get() = mixer.hasQueue
    fun nextPreset() = mixer.next()
    fun previousPreset() = mixer.previous()

    // MARK: Mixer delegates --------------------------------------------------

    val isPlaying: Boolean get() = mixer.isPlaying
    val hasSelection: Boolean get() = mixer.hasSelection
    val selectedCount: Int get() = mixer.selectedCount
    val masterVolume: Float get() = mixer.masterVolume
    val mixTitle: String get() = mixer.mixTitle
    val mixSubtitle: String get() = mixer.mixSubtitle
    val artworkName: String? get() = mixer.artworkName

    fun isSelected(sound: Sound): Boolean = mixer.isSelected(sound)
    fun volumeFor(sound: Sound): Float = mixer.volumeFor(sound)
    fun toggle(sound: Sound) = mixer.toggle(sound)
    fun setVolume(value: Float, sound: Sound) = mixer.setVolume(value, sound)
    fun updateMasterVolume(value: Float) = mixer.updateMasterVolume(value)
    fun togglePlayPause() = mixer.togglePlayPause()
    fun clearAll() = mixer.clearAll()
    fun shuffle() = mixer.shuffle()
    fun restore(preset: Preset) = mixer.restore(preset)
    fun suggestedPresetName(): String = mixer.suggestedPresetName()

    /** Reset also ends any running timer — the sounds it was watching are gone. */
    fun resetMix() {
        timer.cancel()
        mixer.clearAll()
    }

    // MARK: Sharing ----------------------------------------------------------

    fun shareUrl(): String? = MixShare.url(mixer.volumes.toMap())

    /** A mix parsed from an incoming share link, awaiting the user's confirmation. */
    var incomingSharedMix by mutableStateOf<Map<String, Float>?>(null)
        private set

    fun receiveShareUri(uri: android.net.Uri) {
        MixShare.volumes(uri)?.let { incomingSharedMix = it }
    }

    fun loadIncomingSharedMix() {
        incomingSharedMix?.let { applySharedMix(it) }
        incomingSharedMix = null
    }

    fun dismissSharedMix() {
        incomingSharedMix = null
    }

    private fun applySharedMix(shared: Map<String, Float>) {
        mixer.restore(Preset(name = "Shared Mix", volumes = shared, masterVolume = mixer.masterVolume))
        mixer.clearCurrentPresetName()
    }

    // MARK: Timers -----------------------------------------------------------

    val timerKind: TimerController.Kind? get() = timer.kind
    val timerRinging: TimerController.Kind? get() = timer.ringing
    val isTimerActive: Boolean get() = timer.isActive
    val timerDisplay: String get() = timer.display

    fun startSleepTimer(seconds: Int) = timer.start(TimerController.Kind.Sleep, seconds)
    fun startCountdownTimer(seconds: Int) = timer.start(TimerController.Kind.Countdown, seconds)
    fun startPomodoro(seconds: Int) = timer.start(TimerController.Kind.Pomodoro, seconds)
    fun cancelTimer() = timer.cancel()

    // MARK: Alarm settings ---------------------------------------------------

    val alarmVolume: Float get() = timer.alarmVolume
    fun setAlarmVolume(value: Float) = timer.updateAlarmVolume(value)
    val vibrationEnabled: Boolean get() = timer.vibrationEnabled
    fun setVibration(enabled: Boolean) = timer.updateVibration(enabled)
    val isPreviewingAlarm: Boolean get() = timer.isPreviewing
    fun toggleAlarmPreview() = timer.togglePreview()

    companion object {
        private const val KEY_APPEARANCE = "appearanceMode"
        private const val KEY_ACCENT = "accent"
        private const val KEY_HOME_STYLE = "homeStyle"
        private const val KEY_FAVORITES = "favorites"
        private const val KEY_PRESETS = "presets"
    }
}
