package com.toepper.rocks.yumibun.data

import android.content.Context
import java.security.MessageDigest

/**
 * Runtime string lookup keyed by the English source text — the same keys the iOS app uses.
 * Resource names are `s_<md5(key)[:12]>`, generated from Localizable.xcstrings. Unknown
 * keys fall back to the English text itself, so wrapping a literal is always safe.
 */
object Loc {
    private lateinit var appContext: Context

    fun init(context: Context) {
        appContext = context.applicationContext
    }

    private fun idFor(key: String): Int {
        if (!::appContext.isInitialized) return 0
        val name = "s_" + md5Hex(key).substring(0, 12)
        return appContext.resources.getIdentifier(name, "string", appContext.packageName)
    }

    fun get(key: String): String {
        val id = idFor(key)
        return if (id != 0) appContext.getString(id) else key
    }

    fun get(key: String, vararg args: Any): String {
        val id = idFor(key)
        if (id != 0) return appContext.getString(id, *args)
        // Fallback: substitute the iOS specifier with the first arg.
        return key.replace("%lld", args.firstOrNull()?.toString() ?: "")
    }

    private fun md5Hex(s: String): String {
        val bytes = MessageDigest.getInstance("MD5").digest(s.toByteArray(Charsets.UTF_8))
        return bytes.joinToString("") { "%02x".format(it) }
    }
}
