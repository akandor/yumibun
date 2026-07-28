package com.toepper.rocks.yumibun

import android.app.Application
import com.toepper.rocks.yumibun.data.Loc
import com.toepper.rocks.yumibun.playback.GeneratorController
import com.toepper.rocks.yumibun.playback.SoundMixer
import com.toepper.rocks.yumibun.playback.TimerController

/**
 * Holds the app-scoped [SoundMixer], [TimerController] and [GeneratorController] so
 * playback, timers and tone synthesis survive the UI and the service.
 */
class YumibunApp : Application() {
    val mixer: SoundMixer by lazy { SoundMixer(this) }
    val timer: TimerController by lazy { TimerController(this, mixer) }
    val generator: GeneratorController by lazy { GeneratorController(this) }

    override fun onCreate() {
        super.onCreate()
        Loc.init(this)
    }
}
