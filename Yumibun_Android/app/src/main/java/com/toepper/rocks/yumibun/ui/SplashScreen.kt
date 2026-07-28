package com.toepper.rocks.yumibun.ui

import androidx.compose.animation.core.Spring
import androidx.compose.animation.core.animateFloatAsState
import androidx.compose.animation.core.spring
import androidx.compose.animation.core.tween
import androidx.compose.foundation.background
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.offset
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.alpha
import androidx.compose.ui.draw.scale
import androidx.compose.ui.text.font.FontFamily
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.toepper.rocks.yumibun.ui.theme.Theme
import kotlinx.coroutines.delay

/**
 * Brand moment on launch: the logo settles in and breathes, the title rises under it,
 * then it hands over to the app — mirroring the iOS SplashView.
 */
@Composable
fun SplashScreen(onFinish: () -> Unit) {
    val colors = Theme.colors
    var logoIn by remember { mutableStateOf(false) }
    var titleIn by remember { mutableStateOf(false) }

    val logoAlpha by animateFloatAsState(if (logoIn) 1f else 0f, tween(500), label = "logoAlpha")
    val logoScale by animateFloatAsState(
        targetValue = if (logoIn) 1f else 0.7f,
        animationSpec = spring(dampingRatio = 0.62f, stiffness = Spring.StiffnessLow),
        label = "logoScale",
    )
    val titleAlpha by animateFloatAsState(if (titleIn) 1f else 0f, tween(500), label = "titleAlpha")
    val titleOffset by animateFloatAsState(if (titleIn) 0f else 12f, tween(500), label = "titleOffset")

    LaunchedEffect(Unit) {
        logoIn = true
        delay(320)
        titleIn = true
        delay(1450)
        onFinish()
    }

    Column(
        horizontalAlignment = Alignment.CenterHorizontally,
        verticalArrangement = Arrangement.Center,
        modifier = Modifier.fillMaxSize().background(colors.background),
    ) {
        Column(
            horizontalAlignment = Alignment.CenterHorizontally,
            verticalArrangement = Arrangement.spacedBy(24.dp),
        ) {
            LogoMark(
                size = 112.dp,
                modifier = Modifier.alpha(logoAlpha).scale(logoScale),
            )
            Text(
                text = "Yumibun",
                color = colors.textPrimary,
                fontSize = 36.sp,
                fontFamily = FontFamily.Serif,
                modifier = Modifier
                    .alpha(titleAlpha)
                    .offset(y = titleOffset.dp),
            )
        }
    }
}
