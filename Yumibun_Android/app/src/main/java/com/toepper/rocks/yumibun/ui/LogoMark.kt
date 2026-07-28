package com.toepper.rocks.yumibun.ui

import androidx.compose.animation.core.LinearEasing
import androidx.compose.animation.core.RepeatMode
import androidx.compose.animation.core.animateFloat
import androidx.compose.animation.core.infiniteRepeatable
import androidx.compose.animation.core.rememberInfiniteTransition
import androidx.compose.animation.core.tween
import androidx.compose.foundation.layout.size
import androidx.compose.material3.Icon
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.rotate
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.res.painterResource
import androidx.compose.ui.unit.Dp
import com.toepper.rocks.yumibun.R
import com.toepper.rocks.yumibun.ui.theme.AccentPalette
import com.toepper.rocks.yumibun.ui.theme.Theme

/**
 * The Yumibun mark, turning slowly and continuously. Follows the accent palette — `Pure`
 * renders monochrome via textSecondary; every other palette tints it with the accent.
 */
@Composable
fun LogoMark(
    size: Dp,
    modifier: Modifier = Modifier,
    tint: Color? = null,
    spin: Boolean = true,
    revolutionMillis: Int = 24_000,
) {
    val colors = Theme.colors
    val resolved = tint ?: if (colors.accentPalette == AccentPalette.Pure) colors.textSecondary else colors.accent

    val rotation = if (spin) {
        val transition = rememberInfiniteTransition(label = "logo-spin")
        val angle by transition.animateFloat(
            initialValue = 0f,
            targetValue = 360f,
            animationSpec = infiniteRepeatable(
                animation = tween(revolutionMillis, easing = LinearEasing),
                repeatMode = RepeatMode.Restart,
            ),
            label = "angle",
        )
        angle
    } else 0f

    Icon(
        painter = painterResource(R.drawable.logo),
        contentDescription = "Yumibun",
        tint = resolved,
        modifier = modifier.size(size).rotate(rotation),
    )
}
