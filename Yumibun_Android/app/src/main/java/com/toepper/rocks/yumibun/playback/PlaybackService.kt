package com.toepper.rocks.yumibun.playback

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.app.Service
import android.content.Intent
import android.content.pm.ServiceInfo
import android.os.Build
import android.os.IBinder
import android.support.v4.media.MediaMetadataCompat
import android.support.v4.media.session.MediaSessionCompat
import android.support.v4.media.session.PlaybackStateCompat
import androidx.core.app.NotificationCompat
import androidx.media.session.MediaButtonReceiver
import com.toepper.rocks.yumibun.MainActivity
import com.toepper.rocks.yumibun.R
import com.toepper.rocks.yumibun.YumibunApp
import com.toepper.rocks.yumibun.ui.Artwork

/**
 * Foreground service that keeps the [SoundMixer] alive in the background and publishes a
 * MediaStyle notification with lock-screen transport controls.
 */
class PlaybackService : Service() {

    private val mixer get() = (application as YumibunApp).mixer
    private val generator get() = (application as YumibunApp).generator
    private lateinit var session: MediaSessionCompat

    /** Keep the service foreground while either the mix or a tone is active. */
    private fun shouldRun(): Boolean = mixer.hasSelection || generator.isActive

    override fun onCreate() {
        super.onCreate()
        createChannel()
        session = MediaSessionCompat(this, "Yumibun").apply {
            setCallback(object : MediaSessionCompat.Callback() {
                override fun onPlay() = mixer.resume()
                override fun onPause() = mixer.pause()
                override fun onStop() { mixer.clearAll(); generator.stop() }
            })
            isActive = true
        }
        mixer.onStateChanged = { refresh() }
        generator.onStateChanged = { refresh() }
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        when (intent?.action) {
            ACTION_TOGGLE -> mixer.togglePlayPause()
            ACTION_STOP -> mixer.clearAll()
            ACTION_STOP_TONE -> generator.stop()
            else -> MediaButtonReceiver.handleIntent(session, intent)
        }
        // Always enter the foreground promptly (started via startForegroundService).
        startForegroundNow()
        if (!shouldRun()) stopSelfSafely()
        return START_STICKY
    }

    private fun refresh() {
        if (!shouldRun()) {
            stopSelfSafely()
            return
        }
        val nm = getSystemService(NotificationManager::class.java)
        nm.notify(NOTIF_ID, buildNotification())
    }

    private fun startForegroundNow() {
        val notification = buildNotification()
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            startForeground(NOTIF_ID, notification, ServiceInfo.FOREGROUND_SERVICE_TYPE_MEDIA_PLAYBACK)
        } else {
            startForeground(NOTIF_ID, notification)
        }
    }

    private fun stopSelfSafely() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.N) {
            stopForeground(STOP_FOREGROUND_REMOVE)
        } else {
            @Suppress("DEPRECATION")
            stopForeground(true)
        }
        stopSelf()
    }

    private fun buildNotification(): Notification {
        // The mix is primary when present; otherwise the notification represents the tone.
        val hasMix = mixer.hasSelection
        val title: String
        val subtitle: String
        val artwork = if (hasMix) mixer.artworkName?.let { Artwork.androidBitmap(this, it) } else null
        val playing: Boolean

        if (hasMix) {
            title = mixer.mixTitle
            subtitle = mixer.mixSubtitle
            playing = mixer.isPlaying
        } else {
            val tone = generator.active
            title = tone?.name ?: "Neuro"
            subtitle = tone?.type?.title ?: ""
            playing = true
        }

        session.setMetadata(
            MediaMetadataCompat.Builder()
                .putString(MediaMetadataCompat.METADATA_KEY_TITLE, title)
                .putString(MediaMetadataCompat.METADATA_KEY_ARTIST, subtitle)
                .putBitmap(MediaMetadataCompat.METADATA_KEY_ALBUM_ART, artwork)
                .build()
        )
        session.setPlaybackState(
            PlaybackStateCompat.Builder()
                .setActions(
                    PlaybackStateCompat.ACTION_PLAY or
                        PlaybackStateCompat.ACTION_PAUSE or
                        PlaybackStateCompat.ACTION_PLAY_PAUSE or
                        PlaybackStateCompat.ACTION_STOP
                )
                .setState(
                    if (playing) PlaybackStateCompat.STATE_PLAYING else PlaybackStateCompat.STATE_PAUSED,
                    PlaybackStateCompat.PLAYBACK_POSITION_UNKNOWN,
                    1f,
                )
                .build()
        )

        val contentIntent = PendingIntent.getActivity(
            this, 0,
            Intent(this, MainActivity::class.java).addFlags(Intent.FLAG_ACTIVITY_SINGLE_TOP),
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
        )

        val builder = NotificationCompat.Builder(this, CHANNEL_ID)
            .setSmallIcon(R.drawable.ic_stat_wave)
            .setContentTitle(title)
            .setContentText(subtitle)
            .setLargeIcon(artwork)
            .setContentIntent(contentIntent)
            .setOnlyAlertOnce(true)
            .setOngoing(playing)
            .setVisibility(NotificationCompat.VISIBILITY_PUBLIC)

        if (hasMix) {
            val toggleIcon = if (playing) android.R.drawable.ic_media_pause else android.R.drawable.ic_media_play
            builder.addAction(toggleIcon, if (playing) "Pause" else "Play", service(ACTION_TOGGLE))
                .addAction(android.R.drawable.ic_menu_close_clear_cancel, "Stop", service(ACTION_STOP))
                .setStyle(
                    androidx.media.app.NotificationCompat.MediaStyle()
                        .setMediaSession(session.sessionToken)
                        .setShowActionsInCompactView(0, 1)
                )
        } else {
            builder.addAction(android.R.drawable.ic_menu_close_clear_cancel, "Stop", service(ACTION_STOP_TONE))
                .setStyle(
                    androidx.media.app.NotificationCompat.MediaStyle()
                        .setMediaSession(session.sessionToken)
                        .setShowActionsInCompactView(0)
                )
        }
        return builder.build()
    }

    private fun service(action: String): PendingIntent {
        val intent = Intent(this, PlaybackService::class.java).setAction(action)
        return PendingIntent.getService(
            this, action.hashCode(), intent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
        )
    }

    private fun createChannel() {
        val channel = NotificationChannel(
            CHANNEL_ID, "Playback", NotificationManager.IMPORTANCE_LOW,
        ).apply {
            description = "Ambient sound playback controls"
            setShowBadge(false)
        }
        getSystemService(NotificationManager::class.java).createNotificationChannel(channel)
    }

    override fun onDestroy() {
        super.onDestroy()
        mixer.onStateChanged = null
        generator.onStateChanged = null
        session.isActive = false
        session.release()
    }

    override fun onBind(intent: Intent?): IBinder? = null

    companion object {
        private const val NOTIF_ID = 1001
        private const val CHANNEL_ID = "yumibun.playback"
        const val ACTION_TOGGLE = "com.toepper.rocks.yumibun.TOGGLE"
        const val ACTION_STOP = "com.toepper.rocks.yumibun.STOP"
        const val ACTION_STOP_TONE = "com.toepper.rocks.yumibun.STOP_TONE"
    }
}
