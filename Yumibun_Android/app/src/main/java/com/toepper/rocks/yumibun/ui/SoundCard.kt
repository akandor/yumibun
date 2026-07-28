package com.toepper.rocks.yumibun.ui

import androidx.compose.animation.AnimatedContent
import androidx.compose.animation.core.LinearEasing
import androidx.compose.animation.core.RepeatMode
import androidx.compose.animation.core.animateFloat
import androidx.compose.animation.core.infiniteRepeatable
import androidx.compose.animation.core.rememberInfiniteTransition
import androidx.compose.animation.core.tween
import androidx.compose.animation.fadeIn
import androidx.compose.animation.fadeOut
import androidx.compose.animation.scaleIn
import androidx.compose.animation.scaleOut
import androidx.compose.animation.togetherWith
import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.clickable
import androidx.compose.foundation.interaction.MutableInteractionSource
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxHeight
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Favorite
import androidx.compose.material.icons.outlined.FavoriteBorder
import androidx.compose.material3.Icon
import androidx.compose.material3.Slider
import androidx.compose.material3.SliderDefaults
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.remember
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.toepper.rocks.yumibun.AppViewModel
import com.toepper.rocks.yumibun.data.Sound
import com.toepper.rocks.yumibun.ui.theme.Theme

@Composable
fun SoundCard(
    sound: Sound,
    vm: AppViewModel,
    showsFavorite: Boolean = true,
    modifier: Modifier = Modifier,
) {
    val colors = Theme.colors
    val selected = vm.isSelected(sound)
    val playing = selected && vm.isPlaying

    Box(modifier = modifier) {
        Column(
            horizontalAlignment = Alignment.CenterHorizontally,
            verticalArrangement = Arrangement.spacedBy(8.dp),
            modifier = Modifier
                .clip(RoundedCornerShape(18.dp))
                .background(if (selected) colors.surfaceRaised else colors.surface)
                .border(
                    1.dp,
                    if (selected) colors.accent.copy(alpha = 0.45f) else colors.stroke,
                    RoundedCornerShape(18.dp),
                )
                .clickable(
                    interactionSource = remember { MutableInteractionSource() },
                    indication = null,
                ) { vm.toggle(sound) }
                .padding(horizontal = 10.dp)
                .padding(top = 14.dp, bottom = 12.dp)
                .fillMaxWidth(),
        ) {
            // Icon circle / equalizer
            Box(
                contentAlignment = Alignment.Center,
                modifier = Modifier
                    .size(48.dp)
                    .clip(CircleShape)
                    .background(if (selected) colors.accent.copy(alpha = 0.16f) else colors.surface)
                    .border(
                        if (selected) 1.5.dp else 1.dp,
                        if (selected) colors.accent else colors.stroke,
                        CircleShape,
                    ),
            ) {
                AnimatedContent(
                    targetState = playing,
                    transitionSpec = {
                        (scaleIn(initialScale = 0.6f) + fadeIn()) togetherWith
                            (scaleOut(targetScale = 0.6f) + fadeOut())
                    },
                    label = "icon-eq",
                ) { isPlaying ->
                    if (isPlaying) {
                        EqualizerWave(color = colors.accent)
                    } else {
                        Icon(
                            imageVector = iconForSymbol(sound.symbol),
                            contentDescription = null,
                            tint = if (selected) colors.accent else colors.textSecondary,
                            modifier = Modifier.size(20.dp),
                        )
                    }
                }
            }

            Text(
                text = sound.label,
                color = if (selected) colors.textPrimary else colors.textSecondary,
                fontSize = 12.sp,
                fontWeight = FontWeight.Medium,
                textAlign = TextAlign.Center,
                maxLines = 2,
                modifier = Modifier.height(30.dp),
            )

            Slider(
                value = vm.volumeFor(sound),
                onValueChange = { vm.setVolume(it, sound) },
                enabled = selected,
                valueRange = 0f..1f,
                colors = SliderDefaults.colors(
                    thumbColor = colors.accent,
                    activeTrackColor = colors.accent,
                    inactiveTrackColor = colors.stroke,
                    disabledThumbColor = colors.accent.copy(alpha = 0.35f),
                    disabledActiveTrackColor = colors.accent.copy(alpha = 0.25f),
                    disabledInactiveTrackColor = colors.stroke,
                ),
                modifier = Modifier.height(20.dp),
            )
        }

        if (showsFavorite) {
            val isFav = vm.isFavorite(sound)
            Icon(
                imageVector = if (isFav) Icons.Filled.Favorite else Icons.Outlined.FavoriteBorder,
                contentDescription = if (isFav) "Remove from favorites" else "Add to favorites",
                tint = if (isFav) colors.accent else colors.textSecondary,
                modifier = Modifier
                    .align(Alignment.TopEnd)
                    .padding(8.dp)
                    .size(20.dp)
                    .clickable(
                        interactionSource = remember { MutableInteractionSource() },
                        indication = null,
                    ) { vm.toggleFavorite(sound) },
            )
        }
    }
}

/** Four bars bouncing at staggered rates, reading as a playing equalizer. */
@Composable
fun EqualizerWave(color: Color) {
    val transition = rememberInfiniteTransition(label = "eq")
    val mins = listOf(0.30f, 0.45f, 0.25f, 0.50f)
    val maxs = listOf(0.80f, 1.00f, 0.70f, 0.95f)
    val delays = listOf(0, 180, 360, 120)

    Row(
        verticalAlignment = Alignment.CenterVertically,
        horizontalArrangement = Arrangement.spacedBy(3.dp),
        modifier = Modifier.height(16.dp),
    ) {
        repeat(4) { i ->
            val h by transition.animateFloat(
                initialValue = mins[i],
                targetValue = maxs[i],
                animationSpec = infiniteRepeatable(
                    animation = tween(durationMillis = 420, delayMillis = delays[i], easing = LinearEasing),
                    repeatMode = RepeatMode.Reverse,
                ),
                label = "bar$i",
            )
            Box(
                modifier = Modifier
                    .width(3.dp)
                    .fillMaxHeight(h)
                    .clip(RoundedCornerShape(2.dp))
                    .background(color),
            )
        }
    }
}
