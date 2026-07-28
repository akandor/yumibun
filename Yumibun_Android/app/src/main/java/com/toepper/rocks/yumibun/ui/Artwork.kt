package com.toepper.rocks.yumibun.ui

import android.content.Context
import android.graphics.Bitmap
import android.graphics.BitmapFactory
import androidx.compose.runtime.Composable
import androidx.compose.runtime.remember
import androidx.compose.ui.graphics.ImageBitmap
import androidx.compose.ui.graphics.asImageBitmap
import androidx.compose.ui.platform.LocalContext

/** Loads and caches the bundled category artwork from assets/artwork/<name>.jpg. */
object Artwork {
    private val cache = HashMap<String, ImageBitmap?>()

    fun load(context: Context, name: String): ImageBitmap? {
        if (cache.containsKey(name)) return cache[name]
        val bitmap = androidBitmap(context, name)?.asImageBitmap()
        cache[name] = bitmap
        return bitmap
    }

    /** Raw Android bitmap, for the media notification / lockscreen art. */
    fun androidBitmap(context: Context, name: String): Bitmap? = runCatching {
        context.assets.open("artwork/$name.jpg").use { BitmapFactory.decodeStream(it) }
    }.getOrNull()
}

@Composable
fun rememberArtwork(name: String?): ImageBitmap? {
    val context = LocalContext.current
    return remember(name) { name?.let { Artwork.load(context, it) } }
}
