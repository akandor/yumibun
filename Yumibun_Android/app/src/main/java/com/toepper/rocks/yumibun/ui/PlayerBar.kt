package com.toepper.rocks.yumibun.ui

import android.content.Intent
import androidx.compose.foundation.Image
import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.AddCircle
import androidx.compose.material.icons.filled.Bedtime
import androidx.compose.material.icons.filled.Close
import androidx.compose.material.icons.filled.DeleteOutline
import androidx.compose.material.icons.filled.GraphicEq
import androidx.compose.material.icons.filled.MoreVert
import androidx.compose.material.icons.filled.NotificationsActive
import androidx.compose.material.icons.filled.Pause
import androidx.compose.material.icons.filled.PlayArrow
import androidx.compose.material.icons.filled.Share
import androidx.compose.material.icons.filled.Timelapse
import androidx.compose.material.icons.filled.Timer
import androidx.compose.material3.DropdownMenu
import androidx.compose.material3.DropdownMenuItem
import androidx.compose.material3.HorizontalDivider
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
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.layout.ContentScale
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.toepper.rocks.yumibun.AppViewModel
import com.toepper.rocks.yumibun.data.Loc
import com.toepper.rocks.yumibun.ui.theme.Theme

@Composable
fun PlayerBar(
    vm: AppViewModel,
    onSave: () -> Unit,
    onSleep: () -> Unit,
    onCountdown: () -> Unit,
    onPomodoro: () -> Unit,
    onExpand: () -> Unit,
    modifier: Modifier = Modifier,
) {
    if (!vm.hasSelection) return
    val colors = Theme.colors
    val artwork = rememberArtwork(vm.artworkName)

    Column(
        modifier = modifier
            .fillMaxWidth()
            .padding(horizontal = 12.dp)
            .clip(RoundedCornerShape(20.dp))
            .background(colors.surface)
            .border(1.dp, colors.stroke, RoundedCornerShape(20.dp))
            .padding(10.dp),
    ) {
        Row(verticalAlignment = Alignment.CenterVertically) {
            Box(
                contentAlignment = Alignment.Center,
                modifier = Modifier
                    .size(44.dp)
                    .clip(RoundedCornerShape(10.dp))
                    .background(colors.surfaceRaised),
            ) {
                if (artwork != null) {
                    Image(
                        bitmap = artwork,
                        contentDescription = null,
                        contentScale = ContentScale.Crop,
                        modifier = Modifier.size(44.dp).clip(RoundedCornerShape(10.dp)),
                    )
                } else {
                    Icon(Icons.Filled.GraphicEq, null, tint = colors.textTertiary, modifier = Modifier.size(20.dp))
                }
            }

            Column(
                modifier = Modifier
                    .weight(1f)
                    .clickable { onExpand() }
                    .padding(horizontal = 12.dp),
                verticalArrangement = Arrangement.spacedBy(2.dp),
            ) {
                Text(
                    text = vm.mixTitle,
                    color = colors.textPrimary,
                    fontSize = 14.sp,
                    fontWeight = FontWeight.SemiBold,
                    maxLines = 1,
                    overflow = TextOverflow.Ellipsis,
                )
                Text(
                    text = vm.mixSubtitle,
                    color = colors.textTertiary,
                    fontSize = 12.sp,
                    maxLines = 1,
                    overflow = TextOverflow.Ellipsis,
                )
                if (vm.isTimerActive) {
                    Spacer(Modifier.size(4.dp))
                    TimerChip(vm)
                }
            }

            PlayerMenuButton(vm, onSave, onSleep, onCountdown, onPomodoro)

            Box(
                contentAlignment = Alignment.Center,
                modifier = Modifier
                    .size(40.dp)
                    .clip(RoundedCornerShape(50))
                    .background(colors.textPrimary)
                    .clickable { vm.togglePlayPause() },
            ) {
                Icon(
                    imageVector = if (vm.isPlaying) Icons.Filled.Pause else Icons.Filled.PlayArrow,
                    contentDescription = if (vm.isPlaying) "Pause" else "Play",
                    tint = colors.background,
                    modifier = Modifier.size(22.dp),
                )
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
        )
    }
}

@Composable
private fun PlayerMenuButton(
    vm: AppViewModel,
    onSave: () -> Unit,
    onSleep: () -> Unit,
    onCountdown: () -> Unit,
    onPomodoro: () -> Unit,
) {
    val colors = Theme.colors
    var expanded by remember { mutableStateOf(false) }
    Box {
        Icon(
            imageVector = Icons.Filled.MoreVert,
            contentDescription = "More",
            tint = colors.accent,
            modifier = Modifier
                .size(38.dp)
                .clip(RoundedCornerShape(50))
                .clickable { expanded = true }
                .padding(8.dp),
        )
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

/** While a timer counts down, shows the remaining time with a ✕; once the alarm rings it
 *  becomes a prominent "Stop alarm" button. */
@Composable
private fun TimerChip(vm: AppViewModel) {
    val colors = Theme.colors
    val kind = vm.timerKind
    val ringing = vm.timerRinging

    when {
        kind != null -> Row(
            verticalAlignment = Alignment.CenterVertically,
            horizontalArrangement = Arrangement.spacedBy(6.dp),
            modifier = Modifier
                .clip(RoundedCornerShape(50))
                .background(colors.surfaceRaised)
                .border(1.dp, colors.stroke, RoundedCornerShape(50))
                .padding(start = 10.dp, end = 6.dp, top = 4.dp, bottom = 4.dp),
        ) {
            Icon(Icons.Filled.Timer, null, tint = colors.textSecondary, modifier = Modifier.size(12.dp))
            Text(vm.timerDisplay, color = colors.textPrimary, fontSize = 13.sp, fontWeight = FontWeight.SemiBold)
            Icon(
                Icons.Filled.Close,
                contentDescription = "Cancel timer",
                tint = colors.textSecondary,
                modifier = Modifier.size(16.dp).clickable { vm.cancelTimer() },
            )
        }

        ringing != null -> Row(
            verticalAlignment = Alignment.CenterVertically,
            horizontalArrangement = Arrangement.spacedBy(6.dp),
            modifier = Modifier
                .clip(RoundedCornerShape(50))
                .background(colors.accent)
                .clickable { vm.cancelTimer() }
                .padding(horizontal = 12.dp, vertical = 6.dp),
        ) {
            Icon(Icons.Filled.NotificationsActive, null, tint = colors.background, modifier = Modifier.size(13.dp))
            Text(Loc.get("Stop alarm"), color = colors.background, fontSize = 13.sp, fontWeight = FontWeight.SemiBold)
        }
    }
}
