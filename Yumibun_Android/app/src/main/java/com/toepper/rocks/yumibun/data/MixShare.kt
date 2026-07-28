package com.toepper.rocks.yumibun.data

import android.net.Uri
import org.json.JSONObject
import java.net.URLEncoder
import kotlin.math.roundToInt

/**
 * Builds and parses shareable mix links matching the web app's format:
 * `https://moodist.toepper.rocks/?share=<url-encoded {id: volume}>`.
 */
object MixShare {
    const val HOST = "moodist.toepper.rocks"

    /** A share link for the given `{soundId: volume}` map, or null if the mix is empty. */
    fun url(volumes: Map<String, Float>): String? {
        if (volumes.isEmpty()) return null
        // Mirror the web app: round each volume to two decimals, sort keys.
        val obj = JSONObject()
        volumes.toSortedMap().forEach { (id, v) ->
            obj.put(id, (v * 100).roundToInt() / 100.0)
        }
        val encoded = encodeUriComponent(obj.toString())
        return "https://$HOST/?share=$encoded"
    }

    /** The `{soundId: volume}` map carried by an incoming link, or null if none. */
    fun volumes(uri: Uri): Map<String, Float>? {
        val share = uri.getQueryParameter("share") ?: return null
        val json = runCatching { JSONObject(share) }.getOrNull() ?: return null
        val result = HashMap<String, Float>()
        json.keys().forEach { id ->
            if (SoundCatalog.sound(id) != null) {
                val value = json.optDouble(id, Double.NaN)
                if (!value.isNaN()) result[id] = value.toFloat().coerceIn(0f, 1f)
            }
        }
        return result.ifEmpty { null }
    }

    /** `encodeURIComponent` equivalent so the site decodes it byte-for-byte. */
    private fun encodeUriComponent(s: String): String =
        URLEncoder.encode(s, "UTF-8")
            .replace("+", "%20")
            .replace("%21", "!")
            .replace("%27", "'")
            .replace("%28", "(")
            .replace("%29", ")")
            .replace("%7E", "~")
            .replace("*", "%2A")
}
