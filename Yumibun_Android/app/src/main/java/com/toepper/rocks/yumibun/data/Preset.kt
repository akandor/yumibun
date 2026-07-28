package com.toepper.rocks.yumibun.data

import org.json.JSONArray
import org.json.JSONObject
import java.util.UUID

/** A saved mix: the selected sounds with their volumes, plus the master volume. */
data class Preset(
    val id: String = UUID.randomUUID().toString(),
    val name: String,
    val volumes: Map<String, Float>,
    val masterVolume: Float,
) {
    /** Saved sounds in catalog order, skipping any id no longer in the catalog. */
    val sounds: List<Sound> get() = SoundCatalog.allSounds.filter { volumes.containsKey(it.id) }

    /** Artwork follows the first sound's category. */
    val artworkName: String? get() = sounds.firstOrNull()?.categoryId

    val subtitle: String
        get() {
            val names = sounds.map { it.label }
            val first = names.firstOrNull() ?: return "Empty mix"
            return if (names.size == 1) first else "$first + ${names.size - 1} more"
        }

    fun toJson(): JSONObject = JSONObject().apply {
        put("id", id)
        put("name", name)
        put("masterVolume", masterVolume.toDouble())
        put("volumes", JSONObject().apply {
            volumes.forEach { (k, v) -> put(k, v.toDouble()) }
        })
    }

    companion object {
        fun fromJson(o: JSONObject): Preset {
            val vols = HashMap<String, Float>()
            val v = o.getJSONObject("volumes")
            v.keys().forEach { key -> vols[key] = v.getDouble(key).toFloat() }
            return Preset(
                id = o.optString("id", UUID.randomUUID().toString()),
                name = o.getString("name"),
                volumes = vols,
                masterVolume = o.optDouble("masterVolume", 0.8).toFloat(),
            )
        }

        fun listToJson(presets: List<Preset>): String =
            JSONArray().apply { presets.forEach { put(it.toJson()) } }.toString()

        fun listFromJson(s: String?): List<Preset> {
            if (s.isNullOrBlank()) return emptyList()
            return runCatching {
                val arr = JSONArray(s)
                (0 until arr.length()).map { fromJson(arr.getJSONObject(it)) }
            }.getOrDefault(emptyList())
        }
    }
}
