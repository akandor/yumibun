package com.toepper.rocks.yumibun.ui.theme

import androidx.compose.foundation.isSystemInDarkTheme
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.darkColorScheme
import androidx.compose.material3.lightColorScheme
import androidx.compose.runtime.Composable
import androidx.compose.runtime.CompositionLocalProvider

@Composable
fun YumibunTheme(
    appearance: AppearanceMode = AppearanceMode.System,
    accent: AccentPalette = AccentPalette.Peach,
    content: @Composable () -> Unit,
) {
    val dark = when (appearance) {
        AppearanceMode.System -> isSystemInDarkTheme()
        AppearanceMode.Light -> false
        AppearanceMode.Dark -> true
    }
    val colors = yumibunColors(dark = dark, accent = accent)

    // Feed the semantic palette into Material3 so built-in controls (Slider, Switch,
    // Segmented buttons) pick up the accent and surfaces without per-call tinting.
    val scheme = if (dark) darkColorScheme(
        primary = colors.accent,
        onPrimary = colors.background,
        background = colors.background,
        onBackground = colors.textPrimary,
        surface = colors.surface,
        onSurface = colors.textPrimary,
        surfaceVariant = colors.surfaceRaised,
        onSurfaceVariant = colors.textSecondary,
        error = colors.danger,
    ) else lightColorScheme(
        primary = colors.accent,
        onPrimary = colors.surfaceRaised,
        background = colors.background,
        onBackground = colors.textPrimary,
        surface = colors.surface,
        onSurface = colors.textPrimary,
        surfaceVariant = colors.surfaceRaised,
        onSurfaceVariant = colors.textSecondary,
        error = colors.danger,
    )

    CompositionLocalProvider(LocalYumibunColors provides colors) {
        MaterialTheme(
            colorScheme = scheme,
            typography = Typography,
            content = content,
        )
    }
}
