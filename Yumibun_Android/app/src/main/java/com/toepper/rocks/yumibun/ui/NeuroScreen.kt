package com.toepper.rocks.yumibun.ui

import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.clickable
import androidx.compose.foundation.interaction.MutableInteractionSource
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.text.KeyboardOptions
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.GraphicEq
import androidx.compose.material.icons.filled.Headphones
import androidx.compose.material.icons.filled.PauseCircle
import androidx.compose.material.icons.filled.PlayCircle
import androidx.compose.material.icons.filled.Stop
import androidx.compose.material.icons.filled.Tune
import androidx.compose.material.icons.filled.VolumeUp
import androidx.compose.material3.AlertDialog
import androidx.compose.material3.Icon
import androidx.compose.material3.OutlinedTextField
import androidx.compose.material3.SegmentedButton
import androidx.compose.material3.SegmentedButtonDefaults
import androidx.compose.material3.SingleChoiceSegmentedButtonRow
import androidx.compose.material3.Slider
import androidx.compose.material3.SliderDefaults
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableFloatStateOf
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.input.KeyboardType
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.Dp
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.toepper.rocks.yumibun.AppViewModel
import com.toepper.rocks.yumibun.data.GeneratorPreset
import com.toepper.rocks.yumibun.data.Loc
import com.toepper.rocks.yumibun.data.GeneratorType
import com.toepper.rocks.yumibun.playback.GeneratorController
import com.toepper.rocks.yumibun.ui.theme.Theme

@Composable
fun NeuroScreen(vm: AppViewModel, topPadding: Dp, bottomPadding: Dp) {
    val colors = Theme.colors
    var type by remember { mutableStateOf(GeneratorType.Binaural) }
    var showCustom by remember { mutableStateOf(false) }

    Column(
        modifier = Modifier
            .fillMaxSize()
            .background(colors.background)
            .verticalScroll(rememberScrollState())
            .padding(top = topPadding),
    ) {
        ScreenTitle(Loc.get("Neuro Sounds"))

        // Type toggle
        SingleChoiceSegmentedButtonRow(
            Modifier.fillMaxWidth().padding(horizontal = 20.dp, vertical = 8.dp),
        ) {
            GeneratorType.entries.forEachIndexed { i, t ->
                SegmentedButton(
                    selected = type == t,
                    onClick = { type = t },
                    shape = SegmentedButtonDefaults.itemShape(i, GeneratorType.entries.size),
                    colors = SegmentedButtonDefaults.colors(
                        activeContainerColor = colors.accent.copy(alpha = 0.16f),
                        activeContentColor = colors.accent,
                        activeBorderColor = colors.accent.copy(alpha = 0.5f),
                        inactiveContainerColor = colors.surface,
                        inactiveContentColor = colors.textSecondary,
                        inactiveBorderColor = colors.stroke,
                    ),
                    icon = {},
                ) {
                    AutoSizeLabel(
                        text = t.title,
                        color = if (type == t) colors.accent else colors.textSecondary,
                        maxFontSize = 14.sp,
                        fontWeight = FontWeight.SemiBold,
                    )
                }
            }
        }

        Column(
            verticalArrangement = Arrangement.spacedBy(4.dp),
            modifier = Modifier.padding(horizontal = 20.dp, vertical = 8.dp),
        ) {
            GeneratorRow(
                vm = vm,
                preset = GeneratorPreset.custom,
                type = type,
                isCustom = true,
                onOpen = { showCustom = true },
            )
            GeneratorPreset.presets.forEach { preset ->
                GeneratorRow(vm = vm, preset = preset, type = type)
            }
        }

        Spacer(Modifier.height(bottomPadding + 16.dp))
    }

    if (showCustom) CustomToneDialog(vm.generator, type) { showCustom = false }
}

/** Mini-player for a running generator: a pill with a stop button, docked above the
 *  normal player bar (or alone when no mix plays). */
@Composable
fun GeneratorPill(vm: AppViewModel, modifier: Modifier = Modifier) {
    val colors = Theme.colors
    val active = vm.generator.active ?: return
    Row(
        verticalAlignment = Alignment.CenterVertically,
        horizontalArrangement = Arrangement.spacedBy(12.dp),
        modifier = modifier
            .fillMaxWidth()
            .padding(horizontal = 12.dp)
            .clip(RoundedCornerShape(50))
            .background(colors.surface)
            .border(1.dp, colors.stroke, RoundedCornerShape(50))
            .padding(horizontal = 10.dp, vertical = 8.dp),
    ) {
        Box(
            contentAlignment = Alignment.Center,
            modifier = Modifier.size(34.dp).clip(RoundedCornerShape(50)).background(colors.surfaceRaised),
        ) {
            Icon(
                if (active.type == GeneratorType.Binaural) Icons.Filled.Headphones else Icons.Filled.GraphicEq,
                null, tint = colors.accent, modifier = Modifier.size(16.dp),
            )
        }
        Column(Modifier.weight(1f)) {
            Text(active.name, color = colors.textPrimary, fontSize = 14.sp, fontWeight = FontWeight.SemiBold, maxLines = 1)
            Text(active.type.title, color = colors.textSecondary, fontSize = 11.sp, maxLines = 1)
        }
        Box(
            contentAlignment = Alignment.Center,
            modifier = Modifier
                .size(34.dp)
                .clip(RoundedCornerShape(50))
                .background(colors.surfaceRaised)
                .border(1.dp, colors.stroke, RoundedCornerShape(50))
                .clickable { vm.generator.stop() },
        ) {
            Icon(Icons.Filled.Stop, contentDescription = "Stop ${active.name}", tint = colors.textPrimary, modifier = Modifier.size(15.dp))
        }
    }
}

@Composable
private fun GeneratorRow(
    vm: AppViewModel,
    preset: GeneratorPreset,
    type: GeneratorType,
    isCustom: Boolean = false,
    onOpen: () -> Unit = {},
) {
    val colors = Theme.colors
    val generator = vm.generator
    val playing = generator.isPlaying(preset, type)
    var volume by remember { mutableFloatStateOf(0.5f) }

    fun togglePlay() = generator.toggle(preset, type, volume.toDouble())

    Column(
        verticalArrangement = Arrangement.spacedBy(12.dp),
        modifier = Modifier
            .fillMaxWidth()
            .padding(vertical = 8.dp),
    ) {
        Row(verticalAlignment = Alignment.CenterVertically, horizontalArrangement = Arrangement.spacedBy(12.dp)) {
            Row(
                verticalAlignment = Alignment.CenterVertically,
                horizontalArrangement = Arrangement.spacedBy(12.dp),
                modifier = Modifier
                    .weight(1f)
                    .clickable(
                        interactionSource = remember { MutableInteractionSource() },
                        indication = null,
                    ) { if (isCustom) onOpen() else togglePlay() },
            ) {
                Box(
                    contentAlignment = Alignment.Center,
                    modifier = Modifier
                        .size(48.dp)
                        .clip(RoundedCornerShape(12.dp))
                        .background(colors.surface),
                ) {
                    Icon(
                        imageVector = when {
                            isCustom -> Icons.Filled.Tune
                            type == GeneratorType.Binaural -> Icons.Filled.Headphones
                            else -> Icons.Filled.GraphicEq
                        },
                        contentDescription = null,
                        tint = colors.accent,
                        modifier = Modifier.size(22.dp),
                    )
                }
                Column(Modifier.weight(1f), verticalArrangement = Arrangement.spacedBy(3.dp)) {
                    Text(preset.displayName, color = colors.textPrimary, fontSize = 16.sp, fontWeight = FontWeight.SemiBold, maxLines = 1)
                    Text(preset.subtitle(type), color = colors.textSecondary, fontSize = 12.sp, maxLines = 1)
                }
            }

            Icon(
                imageVector = if (playing) Icons.Filled.PauseCircle else Icons.Filled.PlayCircle,
                contentDescription = if (playing) "Stop ${preset.displayName}" else "Play ${preset.displayName}",
                tint = colors.accent,
                modifier = Modifier
                    .size(34.dp)
                    .clickable(
                        interactionSource = remember { MutableInteractionSource() },
                        indication = null,
                    ) { togglePlay() },
            )
        }

        Row(verticalAlignment = Alignment.CenterVertically, horizontalArrangement = Arrangement.spacedBy(10.dp)) {
            Icon(Icons.Filled.VolumeUp, null, tint = colors.textTertiary, modifier = Modifier.size(14.dp))
            Slider(
                value = volume,
                onValueChange = {
                    volume = it
                    if (playing) generator.setVolume(it.toDouble())
                },
                valueRange = 0f..1f,
                colors = SliderDefaults.colors(
                    thumbColor = colors.accent,
                    activeTrackColor = colors.accent,
                    inactiveTrackColor = colors.stroke,
                ),
                modifier = Modifier.weight(1f),
            )
            Text("${(volume * 100).toInt()}%", color = colors.textSecondary, fontSize = 11.sp, modifier = Modifier.width(34.dp))
        }
    }
}

@Composable
private fun CustomToneDialog(generator: GeneratorController, type: GeneratorType, onDismiss: () -> Unit) {
    val colors = Theme.colors
    var base by remember { mutableStateOf(generator.customCarrier.toInt().toString()) }
    var beat by remember { mutableStateOf(generator.customBeat.toInt().toString()) }

    fun apply() {
        generator.customCarrier = base.toDoubleOrNull() ?: 200.0
        generator.customBeat = beat.toDoubleOrNull() ?: 10.0
        generator.retuneCustomIfPlaying(type)
    }

    AlertDialog(
        onDismissRequest = onDismiss,
        containerColor = colors.surface,
        title = { Text("${Loc.get("Custom")} · ${type.title}", color = colors.textPrimary) },
        text = {
            Column(verticalArrangement = Arrangement.spacedBy(14.dp)) {
                OutlinedTextField(
                    value = base,
                    onValueChange = { base = it; apply() },
                    label = { Text("Base Frequency (Hz)") },
                    singleLine = true,
                    keyboardOptions = KeyboardOptions(keyboardType = KeyboardType.Number),
                    modifier = Modifier.fillMaxWidth(),
                )
                OutlinedTextField(
                    value = beat,
                    onValueChange = { beat = it; apply() },
                    label = { Text(type.beatLabel) },
                    singleLine = true,
                    keyboardOptions = KeyboardOptions(keyboardType = KeyboardType.Number),
                    modifier = Modifier.fillMaxWidth(),
                )
            }
        },
        confirmButton = {
            TextButton(onClick = { apply(); onDismiss() }) {
                Text(Loc.get("Done"), color = colors.accent, fontWeight = FontWeight.SemiBold)
            }
        },
    )
}
