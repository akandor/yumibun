package com.toepper.rocks.yumibun.ui

import androidx.compose.foundation.Image
import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.WindowInsets
import androidx.compose.foundation.layout.asPaddingValues
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.systemBars
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.KeyboardArrowDown
import androidx.compose.material.icons.filled.MoreHoriz
import androidx.compose.material.icons.filled.Pause
import androidx.compose.material.icons.filled.PlayArrow
import androidx.compose.material.icons.filled.SkipNext
import androidx.compose.material.icons.filled.SkipPrevious
import androidx.compose.material3.Icon
import androidx.compose.material3.Slider
import androidx.compose.material3.SliderDefaults
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.layout.ContentScale
import androidx.compose.ui.text.font.FontFamily
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.toepper.rocks.yumibun.AppViewModel
import com.toepper.rocks.yumibun.ui.theme.Theme

/** The expanded player: full-bleed artwork, transport, master volume and the action menu. */
@Composable
fun FullPlayer(
    vm: AppViewModel,
    onClose: () -> Unit,
    onSave: () -> Unit,
    onSleep: () -> Unit,
    onCountdown: () -> Unit,
    onPomodoro: () -> Unit,
) {
    val colors = Theme.colors
    val artwork = rememberArtwork(vm.artworkName)
    val insets = WindowInsets.systemBars.asPaddingValues()

    Box(Modifier.fillMaxSize().background(colors.background)) {
        if (artwork != null) {
            Image(
                bitmap = artwork,
                contentDescription = null,
                contentScale = ContentScale.Crop,
                modifier = Modifier.fillMaxSize(),
            )
        }
        Box(
            Modifier.fillMaxSize().background(
                Brush.verticalGradient(
                    colors = if (colors.isDark) {
                        listOf(colors.background.copy(0.35f), colors.background.copy(0.75f), colors.background.copy(0.98f))
                    } else {
                        listOf(colors.background.copy(0.15f), colors.background.copy(0.55f), colors.background.copy(0.92f))
                    }
                )
            )
        )

        Column(
            modifier = Modifier
                .fillMaxSize()
                .padding(top = insets.calculateTopPadding(), bottom = insets.calculateBottomPadding())
                .padding(horizontal = 20.dp),
        ) {
            // Header
            Row(Modifier.fillMaxWidth().padding(top = 8.dp), verticalAlignment = Alignment.CenterVertically) {
                CircleButton(Icons.Filled.KeyboardArrowDown, "Close player") { onClose() }
                Spacer(Modifier.weight(1f))
                FullPlayerMenu(vm, onSave, onSleep, onCountdown, onPomodoro)
            }

            Spacer(Modifier.weight(1f))

            Column(
                horizontalAlignment = Alignment.CenterHorizontally,
                verticalArrangement = Arrangement.spacedBy(16.dp),
                modifier = Modifier.fillMaxWidth().padding(bottom = 28.dp),
            ) {
                Column(horizontalAlignment = Alignment.CenterHorizontally, verticalArrangement = Arrangement.spacedBy(6.dp)) {
                    Text(
                        vm.mixTitle,
                        color = colors.textPrimary,
                        fontSize = 34.sp,
                        fontFamily = FontFamily.Serif,
                        textAlign = TextAlign.Center,
                        maxLines = 2,
                    )
                    Text(vm.mixSubtitle, color = colors.textSecondary, fontSize = 15.sp)
                }
            }

            Slider(
                value = vm.masterVolume,
                onValueChange = { vm.updateMasterVolume(it) },
                valueRange = 0f..1f,
                colors = SliderDefaults.colors(
                    thumbColor = colors.accent,
                    activeTrackColor = colors.accent,
                    inactiveTrackColor = colors.stroke,
                ),
                modifier = Modifier.fillMaxWidth().padding(bottom = 34.dp),
            )

            Row(
                verticalAlignment = Alignment.CenterVertically,
                horizontalArrangement = Arrangement.spacedBy(40.dp),
                modifier = Modifier
                    .align(Alignment.CenterHorizontally)
                    .padding(bottom = 46.dp),
            ) {
                SkipButton(Icons.Filled.SkipPrevious, "Previous preset", enabled = vm.hasQueue) { vm.previousPreset() }
                Box(
                    contentAlignment = Alignment.Center,
                    modifier = Modifier
                        .size(84.dp)
                        .clip(CircleShape)
                        .background(colors.textPrimary)
                        .clickable { vm.togglePlayPause() },
                ) {
                    Icon(
                        imageVector = if (vm.isPlaying) Icons.Filled.Pause else Icons.Filled.PlayArrow,
                        contentDescription = if (vm.isPlaying) "Pause" else "Play",
                        tint = colors.background,
                        modifier = Modifier.size(38.dp),
                    )
                }
                SkipButton(Icons.Filled.SkipNext, "Next preset", enabled = vm.hasQueue) { vm.nextPreset() }
            }
        }
    }
}

@Composable
private fun FullPlayerMenu(
    vm: AppViewModel,
    onSave: () -> Unit,
    onSleep: () -> Unit,
    onCountdown: () -> Unit,
    onPomodoro: () -> Unit,
) {
    var expanded by remember { mutableStateOf(false) }
    Box {
        CircleButton(Icons.Filled.MoreHoriz, "Menu") { expanded = true }
        PlayerActionsDropdown(
            expanded = expanded,
            onDismiss = { expanded = false },
            vm = vm,
            onSave = onSave,
            onSleep = onSleep,
            onCountdown = onCountdown,
            onPomodoro = onPomodoro,
        )
    }
}

@Composable
private fun SkipButton(icon: ImageVector, label: String, enabled: Boolean, onClick: () -> Unit) {
    val colors = Theme.colors
    Icon(
        imageVector = icon,
        contentDescription = label,
        tint = colors.textPrimary.copy(alpha = if (enabled) 1f else 0.3f),
        modifier = Modifier
            .size(44.dp)
            .then(if (enabled) Modifier.clickable { onClick() } else Modifier),
    )
}

@Composable
private fun CircleButton(icon: ImageVector, label: String, onClick: () -> Unit) {
    val colors = Theme.colors
    Box(
        contentAlignment = Alignment.Center,
        modifier = Modifier
            .size(40.dp)
            .clip(CircleShape)
            .background(colors.surface.copy(alpha = 0.7f))
            .clickable { onClick() },
    ) {
        Icon(icon, contentDescription = label, tint = colors.textPrimary, modifier = Modifier.size(20.dp))
    }
}
