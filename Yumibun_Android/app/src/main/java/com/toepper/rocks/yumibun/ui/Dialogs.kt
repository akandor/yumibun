package com.toepper.rocks.yumibun.ui

import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.clickable
import androidx.compose.foundation.gestures.snapping.rememberSnapFlingBehavior
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.PaddingValues
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.itemsIndexed
import androidx.compose.foundation.lazy.rememberLazyListState
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material3.AlertDialog
import androidx.compose.material3.OutlinedTextField
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.derivedStateOf
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableIntStateOf
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.Dp
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.toepper.rocks.yumibun.AppViewModel
import com.toepper.rocks.yumibun.data.Loc
import com.toepper.rocks.yumibun.ui.theme.Theme
import kotlin.math.abs

/** The timer the player menu asked to configure. */
enum class TimerPick(val title: String, val subtitle: String) {
    Sleep("Sleep timer", "Stop sounds after a while."),
    Countdown("Countdown timer", "A simple countdown."),
    Pomodoro("Pomodoro", "Focus, then a chime."),
}

@Composable
fun TimerDialog(vm: AppViewModel, pick: TimerPick, onDismiss: () -> Unit) {
    val colors = Theme.colors

    var hours by remember { mutableIntStateOf(0) }
    var minutes by remember { mutableIntStateOf(if (pick == TimerPick.Sleep) 30 else if (pick == TimerPick.Pomodoro) 25 else 0) }
    var seconds by remember { mutableIntStateOf(0) }

    val totalSeconds = hours * 3600 + minutes * 60 + (if (pick == TimerPick.Countdown) seconds else 0)

    AlertDialog(
        onDismissRequest = onDismiss,
        containerColor = colors.surface,
        title = { Text(Loc.get(pick.title), color = colors.textPrimary) },
        text = {
            Column {
                Text(Loc.get(pick.subtitle), color = colors.textSecondary, fontSize = 13.sp)

                if (pick == TimerPick.Pomodoro) {
                    Row(
                        horizontalArrangement = Arrangement.spacedBy(8.dp),
                        modifier = Modifier
                            .fillMaxWidth()
                            .padding(top = 16.dp),
                    ) {
                        PomodoroChip("Pomodoro", isSelected = hours == 0 && minutes == 25, modifier = Modifier.weight(1f)) {
                            hours = 0; minutes = 25
                        }
                        PomodoroChip("Break", isSelected = hours == 0 && minutes == 5, modifier = Modifier.weight(1f)) {
                            hours = 0; minutes = 5
                        }
                        PomodoroChip("Long Break", isSelected = hours == 0 && minutes == 15, modifier = Modifier.weight(1f)) {
                            hours = 0; minutes = 15
                        }
                    }
                }

                Row(
                    horizontalArrangement = Arrangement.Center,
                    modifier = Modifier
                        .fillMaxWidth()
                        .padding(top = 16.dp),
                ) {
                    WheelPicker(range = 0..23, suffix = "h", selected = hours, onSelected = { hours = it })
                    WheelPicker(range = 0..59, suffix = "m", selected = minutes, onSelected = { minutes = it })
                    if (pick == TimerPick.Countdown) {
                        WheelPicker(range = 0..59, suffix = "s", selected = seconds, onSelected = { seconds = it })
                    }
                }
            }
        },
        confirmButton = {
            TextButton(
                enabled = totalSeconds > 0,
                onClick = {
                    when (pick) {
                        TimerPick.Sleep -> vm.startSleepTimer(totalSeconds)
                        TimerPick.Countdown -> vm.startCountdownTimer(totalSeconds)
                        TimerPick.Pomodoro -> vm.startPomodoro(totalSeconds)
                    }
                    onDismiss()
                },
            ) {
                Text(
                    Loc.get("Start"),
                    color = if (totalSeconds > 0) colors.accent else colors.textTertiary,
                    fontWeight = FontWeight.SemiBold,
                )
            }
        },
        dismissButton = { TextButton(onClick = onDismiss) { Text(Loc.get("Cancel"), color = colors.textSecondary) } },
    )
}

@Composable
private fun PomodoroChip(label: String, isSelected: Boolean, modifier: Modifier = Modifier, onClick: () -> Unit) {
    val colors = Theme.colors
    Text(
        text = Loc.get(label),
        color = colors.textPrimary,
        fontSize = 13.sp,
        fontWeight = FontWeight.SemiBold,
        maxLines = 1,
        textAlign = androidx.compose.ui.text.style.TextAlign.Center,
        modifier = modifier
            .clip(RoundedCornerShape(16.dp))
            .background(if (isSelected) colors.surfaceRaised else colors.surface)
            .border(
                1.dp,
                if (isSelected) colors.accent.copy(alpha = 0.45f) else colors.stroke,
                RoundedCornerShape(16.dp),
            )
            .clickable(onClick = onClick)
            .padding(vertical = 12.dp),
    )
}

/**
 * A scrollable wheel-style number picker that mirrors the iOS `.wheel` pickers in the
 * timer sheets. Numbers snap to the center; the centered value is reported via [onSelected].
 */
@Composable
private fun WheelPicker(
    range: IntRange,
    suffix: String,
    selected: Int,
    onSelected: (Int) -> Unit,
    modifier: Modifier = Modifier,
    visibleCount: Int = 5,
    itemHeight: Dp = 34.dp,
) {
    val colors = Theme.colors
    val values = remember(range) { range.toList() }
    val listState = rememberLazyListState(
        initialFirstVisibleItemIndex = (selected - range.first).coerceIn(0, values.lastIndex),
    )
    val flingBehavior = rememberSnapFlingBehavior(lazyListState = listState)
    val sidePadding = itemHeight * (visibleCount / 2)

    val centerIndex by remember {
        derivedStateOf {
            val info = listState.layoutInfo
            val viewportCenter = (info.viewportStartOffset + info.viewportEndOffset) / 2f
            info.visibleItemsInfo.minByOrNull { abs((it.offset + it.size / 2f) - viewportCenter) }
                ?.index ?: 0
        }
    }

    // Report the centered value only once scrolling settles, so an animated jump to a
    // preset (chip tap) doesn't spray intermediate values back into the parent.
    LaunchedEffect(listState.isScrollInProgress) {
        if (!listState.isScrollInProgress) {
            values.getOrNull(centerIndex)?.let { if (it != selected) onSelected(it) }
        }
    }

    // Follow external changes to `selected` (e.g. a Pomodoro chip) by scrolling the wheel.
    LaunchedEffect(selected) {
        if (!listState.isScrollInProgress && values.getOrNull(centerIndex) != selected) {
            listState.animateScrollToItem((selected - range.first).coerceIn(0, values.lastIndex))
        }
    }

    Box(
        modifier = modifier.width(70.dp),
        contentAlignment = Alignment.Center,
    ) {
        // Center band that highlights the selected row.
        Box(
            modifier = Modifier
                .fillMaxWidth()
                .height(itemHeight)
                .clip(RoundedCornerShape(8.dp))
                .background(colors.surfaceRaised.copy(alpha = 0.5f)),
        )
        LazyColumn(
            state = listState,
            flingBehavior = flingBehavior,
            horizontalAlignment = Alignment.CenterHorizontally,
            contentPadding = PaddingValues(vertical = sidePadding),
            modifier = Modifier.height(itemHeight * visibleCount),
        ) {
            itemsIndexed(values) { index, value ->
                val isSelected = index == centerIndex
                Box(
                    modifier = Modifier
                        .height(itemHeight)
                        .fillMaxWidth(),
                    contentAlignment = Alignment.Center,
                ) {
                    Text(
                        text = "$value $suffix",
                        color = if (isSelected) colors.textPrimary else colors.textTertiary,
                        fontSize = if (isSelected) 19.sp else 15.sp,
                        fontWeight = if (isSelected) FontWeight.SemiBold else FontWeight.Normal,
                    )
                }
            }
        }
    }
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
