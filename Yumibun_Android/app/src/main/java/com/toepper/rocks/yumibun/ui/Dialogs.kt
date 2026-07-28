package com.toepper.rocks.yumibun.ui

import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.ExperimentalLayoutApi
import androidx.compose.foundation.layout.FlowRow
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material3.AlertDialog
import androidx.compose.material3.OutlinedTextField
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.toepper.rocks.yumibun.AppViewModel
import com.toepper.rocks.yumibun.data.Loc
import com.toepper.rocks.yumibun.ui.theme.Theme

/** The timer the player menu asked to configure. */
enum class TimerPick(val title: String, val subtitle: String) {
    Sleep("Sleep timer", "Stop sounds after a while."),
    Countdown("Countdown timer", "A simple countdown."),
    Pomodoro("Pomodoro", "Focus, then a chime."),
}

private data class DurationOption(val label: String, val seconds: Int)

private fun optionsFor(pick: TimerPick): List<DurationOption> = when (pick) {
    TimerPick.Sleep -> listOf(
        DurationOption("15 min", 15 * 60),
        DurationOption("30 min", 30 * 60),
        DurationOption("45 min", 45 * 60),
        DurationOption("1 hour", 60 * 60),
        DurationOption("1.5 hours", 90 * 60),
    )
    TimerPick.Countdown -> listOf(
        DurationOption("1 min", 60),
        DurationOption("5 min", 5 * 60),
        DurationOption("10 min", 10 * 60),
        DurationOption("15 min", 15 * 60),
        DurationOption("20 min", 20 * 60),
        DurationOption("30 min", 30 * 60),
    )
    TimerPick.Pomodoro -> listOf(
        DurationOption("Pomodoro · 25 min", 25 * 60),
        DurationOption("Break · 5 min", 5 * 60),
        DurationOption("Long Break · 15 min", 15 * 60),
    )
}

@OptIn(ExperimentalLayoutApi::class)
@Composable
fun TimerDialog(vm: AppViewModel, pick: TimerPick, onDismiss: () -> Unit) {
    val colors = Theme.colors
    AlertDialog(
        onDismissRequest = onDismiss,
        containerColor = colors.surface,
        title = { Text(Loc.get(pick.title), color = colors.textPrimary) },
        text = {
            Column {
                Text(Loc.get(pick.subtitle), color = colors.textSecondary, fontSize = 13.sp)
                FlowRow(
                    horizontalArrangement = Arrangement.spacedBy(10.dp),
                    verticalArrangement = Arrangement.spacedBy(10.dp),
                    modifier = Modifier.padding(top = 16.dp),
                ) {
                    optionsFor(pick).forEach { option ->
                        Text(
                            text = option.label,
                            color = colors.textPrimary,
                            fontSize = 14.sp,
                            fontWeight = FontWeight.Medium,
                            modifier = Modifier
                                .clip(RoundedCornerShape(50))
                                .background(colors.surfaceRaised)
                                .border(1.dp, colors.stroke, RoundedCornerShape(50))
                                .clickable {
                                    when (pick) {
                                        TimerPick.Sleep -> vm.startSleepTimer(option.seconds)
                                        TimerPick.Countdown -> vm.startCountdownTimer(option.seconds)
                                        TimerPick.Pomodoro -> vm.startPomodoro(option.seconds)
                                    }
                                    onDismiss()
                                }
                                .padding(horizontal = 16.dp, vertical = 10.dp),
                        )
                    }
                }
            }
        },
        confirmButton = {},
        dismissButton = { TextButton(onClick = onDismiss) { Text(Loc.get("Cancel"), color = colors.textSecondary) } },
    )
}

@Composable
fun SavePresetDialog(vm: AppViewModel, onDismiss: () -> Unit) {
    val colors = Theme.colors
    var name by remember { mutableStateOf(vm.suggestedPresetName()) }
    AlertDialog(
        onDismissRequest = onDismiss,
        containerColor = colors.surface,
        title = { Text(Loc.get("Save preset"), color = colors.textPrimary) },
        text = {
            OutlinedTextField(
                value = name,
                onValueChange = { name = it },
                singleLine = true,
                label = { Text(Loc.get("Preset name")) },
                modifier = Modifier.fillMaxWidth(),
            )
        },
        confirmButton = {
            TextButton(onClick = { vm.savePreset(name); onDismiss() }) {
                Text(Loc.get("Save"), color = colors.accent, fontWeight = FontWeight.SemiBold)
            }
        },
        dismissButton = { TextButton(onClick = onDismiss) { Text(Loc.get("Cancel"), color = colors.textSecondary) } },
    )
}

@Composable
fun SharedMixDialog(vm: AppViewModel) {
    val colors = Theme.colors
    val mix = vm.incomingSharedMix ?: return
    AlertDialog(
        onDismissRequest = { vm.dismissSharedMix() },
        containerColor = colors.surface,
        title = { Text(Loc.get("New Sound Mix"), color = colors.textPrimary) },
        text = {
            Text(
                Loc.get("Someone shared a mix with you:\n%lld sounds. Load it and replace your current selection?", mix.size),
                color = colors.textSecondary,
                fontSize = 14.sp,
            )
        },
        confirmButton = {
            TextButton(onClick = { vm.loadIncomingSharedMix() }) {
                Text(Loc.get("Load Mix"), color = colors.accent, fontWeight = FontWeight.SemiBold)
            }
        },
        dismissButton = { TextButton(onClick = { vm.dismissSharedMix() }) { Text("Cancel", color = colors.textSecondary) } },
    )
}
