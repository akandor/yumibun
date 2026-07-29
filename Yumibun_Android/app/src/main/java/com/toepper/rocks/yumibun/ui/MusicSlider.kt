package com.toepper.rocks.yumibun.ui

import androidx.compose.animation.core.animateDpAsState
import androidx.compose.animation.core.spring
import androidx.compose.foundation.background
import androidx.compose.foundation.gestures.awaitEachGesture
import androidx.compose.foundation.gestures.awaitFirstDown
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableFloatStateOf
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.input.pointer.pointerInput
import androidx.compose.ui.layout.onSizeChanged
import androidx.compose.ui.semantics.ProgressBarRangeInfo
import androidx.compose.ui.semantics.progressBarRangeInfo
import androidx.compose.ui.semantics.semantics
import androidx.compose.ui.semantics.setProgress
import androidx.compose.ui.unit.Dp
import androidx.compose.ui.unit.dp
import com.toepper.rocks.yumibun.ui.theme.Theme

/**
 * A thin, thumbless volume slider modelled on the iOS Music app: at rest it's a
 * slim capsule with no handle; the moment you press it the bar swells taller and
 * the fill tracks your finger, then it settles back when you let go.
 */
@Composable
fun MusicSlider(
    value: Float,
    onValueChange: (Float) -> Unit,
    modifier: Modifier = Modifier,
    enabled: Boolean = true,
    tint: Color = Theme.colors.accent,
    restHeight: Dp = 6.dp,
    activeHeight: Dp = 11.dp,
    touchHeight: Dp = 28.dp,
) {
    val trackColor = Theme.colors.textPrimary.copy(alpha = 0.14f)
    val fillColor = if (enabled) tint else tint.copy(alpha = 0.35f)

    var pressed by remember { mutableStateOf(false) }
    var widthPx by remember { mutableFloatStateOf(0f) }
    val barHeight by animateDpAsState(
        targetValue = if (pressed && enabled) activeHeight else restHeight,
        animationSpec = spring(dampingRatio = 0.72f, stiffness = 900f),
        label = "barHeight",
    )

    val fraction = value.coerceIn(0f, 1f)

    Box(
        modifier = modifier
            .fillMaxWidth()
            .height(touchHeight)
            .onSizeChanged { widthPx = it.width.toFloat() }
            .semantics {
                progressBarRangeInfo = ProgressBarRangeInfo(fraction, 0f..1f)
                if (enabled) {
                    setProgress { target -> onValueChange(target.coerceIn(0f, 1f)); true }
                }
            }
            .then(
                if (enabled) {
                    Modifier.pointerInput(Unit) {
                        awaitEachGesture {
                            fun report(x: Float) {
                                if (widthPx > 0f) onValueChange((x / widthPx).coerceIn(0f, 1f))
                            }
                            val down = awaitFirstDown(requireUnconsumed = false)
                            pressed = true
                            report(down.position.x)
                            down.consume()
                            do {
                                val event = awaitPointerEvent()
                                val change = event.changes.firstOrNull { it.id == down.id }
                                    ?: event.changes.first()
                                if (change.pressed) {
                                    report(change.position.x)
                                    change.consume()
                                }
                            } while (event.changes.any { it.pressed })
                            pressed = false
                        }
                    }
                } else Modifier,
            ),
        contentAlignment = Alignment.CenterStart,
    ) {
        Box(
            modifier = Modifier
                .fillMaxWidth()
                .height(barHeight)
                .clip(RoundedCornerShape(percent = 50))
        ) {
            Box(
                modifier = Modifier
                    .fillMaxWidth()
                    .height(barHeight)
                    .background(trackColor)
            )
            Box(
                modifier = Modifier
                    .fillMaxWidth(fraction)
                    .height(barHeight)
                    .background(fillColor)
            )
        }
    }
}
