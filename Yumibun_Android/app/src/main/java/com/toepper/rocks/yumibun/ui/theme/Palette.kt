package com.toepper.rocks.yumibun.ui.theme

import androidx.compose.runtime.Composable
import androidx.compose.runtime.ReadOnlyComposable
import androidx.compose.runtime.staticCompositionLocalOf
import androidx.compose.ui.graphics.Color

/** The accent tints the app can be themed with — each carries a light/dark pair. */
enum class AccentPalette(val key: String, val label: String) {
    Pure("pure", "Pure"),
    Lavender("lavender", "Soft Lavender"),
    Sage("sage", "Sage Green"),
    Peach("peach", "Warm Peach"),
    Cyan("cyan", "Misty Cyan");

    fun color(dark: Boolean): Color = when (this) {
        Pure -> if (dark) Color(0xFFFFFFFF) else Color(0xFF000000)
        Lavender -> if (dark) Color(0xFFB8A7FF) else Color(0xFF7357D8)
        Sage -> if (dark) Color(0xFF8EC9A8) else Color(0xFF4F8B69)
        Peach -> if (dark) Color(0xFFF0B78A) else Color(0xFFD67B45)
        Cyan -> if (dark) Color(0xFF7FD6E5) else Color(0xFF2E8EA5)
    }

    /** Always the lighter variant, for text/icons over the dark photo hero. */
    val colorOnDark: Color
        get() = color(dark = true)

    companion object {
        fun from(key: String?): AccentPalette =
            entries.firstOrNull { it.key == key } ?: Peach
    }
}

enum class AppearanceMode(val key: String, val label: String) {
    System("system", "System"),
    Light("light", "Light"),
    Dark("dark", "Dark");

    companion object {
        fun from(key: String?): AppearanceMode =
            entries.firstOrNull { it.key == key } ?: System
    }
}

enum class HomeStyle(val key: String, val label: String) {
    Modern("modern", "Modern"),
    Simple("simple", "Simple");

    companion object {
        fun from(key: String?): HomeStyle =
            entries.firstOrNull { it.key == key } ?: Modern
    }
}

/** Semantic palette, mirroring the iOS `Theme` enum. */
data class YumibunColors(
    val background: Color,
    val surface: Color,
    val surfaceRaised: Color,
    val stroke: Color,
    val textPrimary: Color,
    val textSecondary: Color,
    val textTertiary: Color,
    val danger: Color,
    val accent: Color,
    val accentPalette: AccentPalette,
    val isDark: Boolean,
)

fun yumibunColors(dark: Boolean, accent: AccentPalette): YumibunColors =
    if (dark) YumibunColors(
        background = Color(0xFF0C0C0E),
        surface = Color(0xFF161618),
        surfaceRaised = Color(0xFF1E1E21),
        stroke = Color(0x14FFFFFF),
        textPrimary = Color(0xFFF5F5F7),
        textSecondary = Color(0xFF9A9AA0),
        textTertiary = Color(0xFF5E5E63),
        danger = Color(0xFFE5484D),
        accent = accent.color(true),
        accentPalette = accent,
        isDark = true,
    ) else YumibunColors(
        background = Color(0xFFE8E8E3),
        surface = Color(0xFFFBFBF9),
        surfaceRaised = Color(0xFFFFFFFF),
        stroke = Color(0x1A000000),
        textPrimary = Color(0xFF1A1A1C),
        textSecondary = Color(0xFF66666C),
        textTertiary = Color(0xFF96969C),
        danger = Color(0xFFE5484D),
        accent = accent.color(false),
        accentPalette = accent,
        isDark = false,
    )

val LocalYumibunColors = staticCompositionLocalOf { yumibunColors(dark = true, accent = AccentPalette.Peach) }

/** Access the semantic palette: `Theme.colors.accent`, etc. */
object Theme {
    val colors: YumibunColors
        @Composable @ReadOnlyComposable
        get() = LocalYumibunColors.current
}
