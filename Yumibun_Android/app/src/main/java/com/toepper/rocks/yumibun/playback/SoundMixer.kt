package com.toepper.rocks.yumibun.playback

import android.content.Context
import android.content.Intent
import android.media.AudioAttributes
import android.media.AudioFocusRequest
import android.media.AudioManager
import android.media.MediaPlayer
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableFloatStateOf
import androidx.compose.runtime.mutableStateListOf
import androidx.compose.runtime.mutableStateMapOf
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.setValue
import androidx.compose.runtime.snapshots.SnapshotStateMap
import androidx.core.content.ContextCompat
import com.toepper.rocks.yumibun.data.Preset
import com.toepper.rocks.yumibun.data.Sound
import com.toepper.rocks.yumibun.data.SoundCatalog
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.Job
import kotlinx.coroutines.SupervisorJob
import kotlinx.coroutines.delay
import kotlinx.coroutines.launch

/**
 * The application-scoped audio engine: plays any number of looping sounds at once, each
 * with its own volume. Lives beyond the UI so playback continues in the background,
 * driven by [PlaybackService]. Exposes Compose snapshot state for the UI to observe.
 */
class SoundMixer(context: Context) {

    private val appContext = context.applicationContext
    private val prefs = appContext.getSharedPreferences("yumibun", Context.MODE_PRIVATE)
    private val scope = CoroutineScope(SupervisorJob() + Dispatchers.Main.immediate)

    /** Volume per selected sound id. Membership here *is* selection. */
    val volumes: SnapshotStateMap<String, Float> = mutableStateMapOf()

    var isPlaying by mutableStateOf(false)
        private set
    var masterVolume by mutableFloatStateOf(prefs.getFloat(KEY_MASTER_VOLUME, 0.8f))
        private set
    var currentPresetName by mutableStateOf<String?>(null)
        private set

    /** An ordered list of presets to step through with next/previous (from "Play All"). */
    val queue = mutableStateListOf<Preset>()
    var queueIndex by mutableStateOf<Int?>(null)
        private set

    /** Whether a "Play All" queue is currently steering the mix. */
    val hasQueue: Boolean get() = queueIndex != null && queue.size > 1

    private val players = HashMap<String, MediaPlayer>()
    private val fadeJobs = HashMap<String, Job>()
    private val currentVolume = HashMap<String, Float>()

    /** Set by [PlaybackService] so state changes refresh the notification. */
    var onStateChanged: (() -> Unit)? = null

    private val audioAttributes = AudioAttributes.Builder()
        .setUsage(AudioAttributes.USAGE_MEDIA)
        .setContentType(AudioAttributes.CONTENT_TYPE_MUSIC)
        .build()

    private val audioManager = appContext.getSystemService(Context.AUDIO_SERVICE) as AudioManager
    private var focusRequest: AudioFocusRequest? = null
    private var pausedForFocusLoss = false

    // MARK: Queries ----------------------------------------------------------

    val selectedCount: Int get() = volumes.size
    val hasSelection: Boolean get() = volumes.isNotEmpty()

    fun isSelected(sound: Sound): Boolean = volumes.containsKey(sound.id)
    fun volumeFor(sound: Sound): Float = volumes[sound.id] ?: DEFAULT_VOLUME

    val selectedSounds: List<Sound>
        get() = SoundCatalog.allSounds.filter { volumes.containsKey(it.id) }

    val artworkName: String?
        get() = selectedSounds.firstOrNull()?.categoryId

    val mixTitle: String
        get() {
            currentPresetName?.let { return it }
            val sounds = selectedSounds
            val first = sounds.firstOrNull() ?: return "Nothing playing"
            return if (sounds.size == 1) first.label else "${first.label} + ${sounds.size - 1} more"
        }

    val mixSubtitle: String
        get() = when {
            !hasSelection -> "No sounds selected"
            !isPlaying -> "Paused"
            else -> "$selectedCount sound${if (selectedCount == 1) "" else "s"} playing"
        }

    fun suggestedPresetName(): String {
        val first = selectedSounds.firstOrNull()?.label ?: "Mix"
        return if (selectedCount <= 1) first else "$first + ${selectedCount - 1}"
    }

    /** Drops the "playing from a preset" label so the mix is titled by its sounds again. */
    fun clearCurrentPresetName() {
        currentPresetName = null
        notifyChanged()
    }

    // MARK: Selection --------------------------------------------------------

    fun toggle(sound: Sound) {
        if (isSelected(sound)) deselect(sound) else select(sound)
    }

    fun select(sound: Sound) {
        if (volumes.containsKey(sound.id)) return
        currentPresetName = null
        volumes[sound.id] = DEFAULT_VOLUME
        if (!isPlaying) {
            isPlaying = true
            requestFocus()
            selectedSounds.forEach { start(it) }
        } else {
            start(sound)
        }
        onPlaybackBegan()
    }

    fun deselect(sound: Sound) {
        currentPresetName = null
        volumes.remove(sound.id)
        fadeOutAndStop(sound.id)
        if (volumes.isEmpty()) {
            isPlaying = false
            stop()
        } else {
            notifyChanged()
        }
    }

    fun setVolume(value: Float, sound: Sound) {
        if (!volumes.containsKey(sound.id)) return
        volumes[sound.id] = value
        players[sound.id]?.let { setLevel(it, sound.id) }
    }

    fun updateMasterVolume(value: Float) {
        masterVolume = value
        prefs.edit().putFloat(KEY_MASTER_VOLUME, value).apply()
        if (isPlaying) players.forEach { (id, p) -> setLevel(p, id) }
    }

    fun clearAll() {
        clearQueue()
        currentPresetName = null
        players.keys.toList().forEach { fadeOutAndStop(it) }
        volumes.clear()
        isPlaying = false
        stop()
    }

    fun shuffle() {
        clearQueue()
        currentPresetName = null
        players.keys.toList().forEach { fadeOutAndStop(it) }
        volumes.clear()
        val picked = SoundCatalog.allSounds.shuffled().take(4)
        picked.forEach { volumes[it.id] = 0.2f + Math.random().toFloat() * 0.8f }
        isPlaying = picked.isNotEmpty()
        if (isPlaying) {
            requestFocus()
            selectedSounds.forEach { start(it) }
            onPlaybackBegan()
        } else {
            stop()
        }
    }

    /** Replaces the current mix with a saved preset. Tapping a preset directly ends any
     *  active queue — the user has stepped off the playlist. */
    fun restore(preset: Preset) {
        clearQueue()
        loadMix(preset)
    }

    private fun loadMix(preset: Preset) {
        players.keys.toList().forEach { fadeOutAndStop(it) }
        volumes.clear()
        preset.volumes.forEach { (id, v) -> if (SoundCatalog.sound(id) != null) volumes[id] = v }
        updateMasterVolume(preset.masterVolume)
        if (volumes.isEmpty()) {
            currentPresetName = null
            isPlaying = false
            stop()
            return
        }
        currentPresetName = preset.name
        isPlaying = true
        requestFocus()
        selectedSounds.forEach { start(it) }
        onPlaybackBegan()
    }

    // MARK: Queue ("Play All") ----------------------------------------------

    /** Starts a playlist: loads the first preset (or the one at [index]) and keeps the
     *  rest queued so next/previous can step through them. */
    fun playQueue(presets: List<Preset>, index: Int = 0) {
        val ordered = presets.filter { it.volumes.isNotEmpty() }
        if (ordered.isEmpty()) return
        queue.clear()
        queue.addAll(ordered)
        playQueueItem(index.coerceIn(0, ordered.size - 1))
    }

    fun next() {
        val i = queueIndex ?: return
        if (queue.isNotEmpty()) playQueueItem((i + 1) % queue.size)
    }

    fun previous() {
        val i = queueIndex ?: return
        if (queue.isNotEmpty()) playQueueItem((i - 1 + queue.size) % queue.size)
    }

    private fun playQueueItem(index: Int) {
        if (index !in queue.indices) return
        queueIndex = index
        loadMix(queue[index])
    }

    private fun clearQueue() {
        queue.clear()
        queueIndex = null
    }

    // MARK: Transport --------------------------------------------------------

    fun togglePlayPause() {
        if (!hasSelection) return
        if (isPlaying) pause() else resume()
    }

    fun resume() {
        if (!hasSelection) return
        isPlaying = true
        requestFocus()
        selectedSounds.forEach { start(it) }
        onPlaybackBegan()
    }

    fun pause() {
        isPlaying = false
        players.forEach { (id, player) ->
            fade(id, player, target = 0f) {
                if (!isPlaying) runCatching { player.pause() }
            }
        }
        notifyChanged()
    }

    // MARK: Players ----------------------------------------------------------

    private fun start(sound: Sound) {
        val player = playerFor(sound) ?: return
        player.isLooping = true
        if (!player.isPlaying) {
            player.setVolume(0f, 0f)
            runCatching { player.start() }
        }
        fade(sound.id, player, target = level(sound.id))
    }

    private fun fadeOutAndStop(id: String) {
        val player = players[id] ?: return
        fade(id, player, target = 0f) {
            runCatching {
                player.stop()
                player.release()
            }
            players.remove(id)
        }
    }

    private fun playerFor(sound: Sound): MediaPlayer? {
        players[sound.id]?.let { return it }
        return runCatching {
            val afd = appContext.assets.openFd(sound.assetPath)
            MediaPlayer().apply {
                setAudioAttributes(audioAttributes)
                setDataSource(afd.fileDescriptor, afd.startOffset, afd.length)
                afd.close()
                isLooping = true
                prepare()
            }
        }.getOrNull()?.also { players[sound.id] = it }
    }

    private fun level(id: String): Float = (volumes[id] ?: DEFAULT_VOLUME) * masterVolume

    private fun setLevel(player: MediaPlayer, id: String) {
        val l = level(id)
        runCatching { player.setVolume(l, l) }
    }

    private fun fade(id: String, player: MediaPlayer, target: Float, onDone: (() -> Unit)? = null) {
        fadeJobs.remove(id)?.cancel()
        fadeJobs[id] = scope.launch {
            val steps = 12
            val start = currentVolume[id] ?: target
            for (i in 1..steps) {
                val v = start + (target - start) * (i / steps.toFloat())
                runCatching { player.setVolume(v, v) }
                currentVolume[id] = v
                delay(FADE_MS / steps)
            }
            currentVolume[id] = target
            onDone?.invoke()
        }
    }

    // MARK: Service + focus --------------------------------------------------

    private fun onPlaybackBegan() {
        val intent = Intent(appContext, PlaybackService::class.java)
        ContextCompat.startForegroundService(appContext, intent)
        notifyChanged()
    }

    private fun stop() {
        abandonFocus()
        notifyChanged()
        appContext.stopService(Intent(appContext, PlaybackService::class.java))
    }

    private fun notifyChanged() {
        onStateChanged?.invoke()
    }

    private fun requestFocus() {
        val request = AudioFocusRequest.Builder(AudioManager.AUDIOFOCUS_GAIN)
            .setAudioAttributes(audioAttributes)
            .setOnAudioFocusChangeListener { change ->
                when (change) {
                    AudioManager.AUDIOFOCUS_LOSS -> clearAll()
                    AudioManager.AUDIOFOCUS_LOSS_TRANSIENT,
                    AudioManager.AUDIOFOCUS_LOSS_TRANSIENT_CAN_DUCK -> {
                        if (isPlaying) {
                            pausedForFocusLoss = true
                            pause()
                        }
                    }
                    AudioManager.AUDIOFOCUS_GAIN -> {
                        if (pausedForFocusLoss) {
                            pausedForFocusLoss = false
                            resume()
                        }
                    }
                }
            }
            .build()
        focusRequest = request
        audioManager.requestAudioFocus(request)
    }

    private fun abandonFocus() {
        focusRequest?.let { audioManager.abandonAudioFocusRequest(it) }
        focusRequest = null
        pausedForFocusLoss = false
    }

    companion object {
        private const val DEFAULT_VOLUME = 0.5f
        private const val FADE_MS = 250L
        private const val KEY_MASTER_VOLUME = "masterVolume"
    }
}
