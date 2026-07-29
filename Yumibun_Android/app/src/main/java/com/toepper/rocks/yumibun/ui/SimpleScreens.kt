package com.toepper.rocks.yumibun.ui

import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.PaddingValues
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.ArrowDownward
import androidx.compose.material.icons.filled.ArrowUpward
import androidx.compose.material.icons.filled.Delete
import androidx.compose.material.icons.filled.Edit
import androidx.compose.material.icons.filled.Favorite
import androidx.compose.material.icons.filled.MoreVert
import androidx.compose.material.icons.filled.MusicNote
import androidx.compose.material.icons.filled.PlayArrow
import androidx.compose.material.icons.filled.PlayCircle
import androidx.compose.material.icons.filled.QueueMusic
import androidx.compose.material3.AlertDialog
import androidx.compose.material3.DropdownMenu
import androidx.compose.material3.DropdownMenuItem
import androidx.compose.material3.HorizontalDivider
import androidx.compose.material3.Icon
import androidx.compose.material3.OutlinedTextField
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.text.font.FontFamily
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.Dp
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.toepper.rocks.yumibun.AppViewModel
import com.toepper.rocks.yumibun.data.Loc
import com.toepper.rocks.yumibun.data.Preset
import com.toepper.rocks.yumibun.ui.theme.Theme

@Composable
fun ScreenTitle(text: String) {
    Text(
        text = text,
        color = Theme.colors.textPrimary,
        fontSize = 28.sp,
        fontFamily = FontFamily.Serif,
        modifier = Modifier.padding(horizontal = 20.dp, vertical = 12.dp),
    )
}

@Composable
fun FavoritesScreen(vm: AppViewModel, topPadding: Dp, bottomPadding: Dp, columns: Int = 2) {
    val colors = Theme.colors
    val favorites = vm.favoriteSounds

    Column(
        modifier = Modifier
            .fillMaxSize()
            .background(colors.background)
            .verticalScroll(rememberScrollState())
            .padding(top = topPadding),
    ) {
        ScreenTitle(Loc.get("Favorites"))
        if (favorites.isEmpty()) {
            EmptyState(
                icon = { Icon(Icons.Filled.Favorite, null, tint = colors.textTertiary, modifier = Modifier.size(40.dp)) },
                title = Loc.get("No Favorites Yet"),
                subtitle = Loc.get("Tap the heart on any sound to keep it here."),
            )
        } else {
            Column(
                verticalArrangement = Arrangement.spacedBy(12.dp),
                modifier = Modifier.padding(horizontal = 20.dp),
            ) {
                favorites.chunked(columns).forEach { row ->
                    Row(horizontalArrangement = Arrangement.spacedBy(12.dp)) {
                        row.forEach { sound ->
                            SoundCard(sound = sound, vm = vm, modifier = Modifier.weight(1f))
                        }
                        repeat(columns - row.size) { Spacer(Modifier.weight(1f)) }
                    }
                }
            }
        }
        Spacer(Modifier.height(bottomPadding + 16.dp))
    }
}

@Composable
fun PresetsScreen(vm: AppViewModel, topPadding: Dp, bottomPadding: Dp) {
    val colors = Theme.colors
    var renaming by remember { mutableStateOf<Preset?>(null) }

    Column(
        modifier = Modifier
            .fillMaxSize()
            .background(colors.background)
            .verticalScroll(rememberScrollState())
            .padding(top = topPadding),
    ) {
        Row(
            verticalAlignment = Alignment.CenterVertically,
            modifier = Modifier.fillMaxWidth().padding(end = 20.dp),
        ) {
            ScreenTitle(Loc.get("Presets"))
            Spacer(Modifier.weight(1f))
            if (vm.hasSelection) {
                Text(
                    text = Loc.get("Save mix"),
                    color = colors.accent,
                    fontSize = 15.sp,
                    fontWeight = FontWeight.SemiBold,
                    modifier = Modifier
                        .clip(RoundedCornerShape(50))
                        .background(colors.accent.copy(alpha = 0.16f))
                        .clickable { vm.savePreset(vm.suggestedPresetName()) }
                        .padding(horizontal = 14.dp, vertical = 8.dp),
                )
            }
        }

        if (vm.presets.isEmpty()) {
            EmptyState(
                icon = { Icon(Icons.Filled.QueueMusic, null, tint = colors.textTertiary, modifier = Modifier.size(40.dp)) },
                title = Loc.get("No Presets Yet"),
                subtitle = Loc.get("Pick some sounds, then tap ... in the player and select 'Add to presets' to save the mix as a preset."),
            )
        } else {
            // Play All
            Row(
                horizontalArrangement = Arrangement.Center,
                verticalAlignment = Alignment.CenterVertically,
                modifier = Modifier
                    .fillMaxWidth()
                    .padding(horizontal = 20.dp, vertical = 8.dp)
                    .clip(RoundedCornerShape(50))
                    .background(colors.accent)
                    .clickable { vm.playAllPresets() }
                    .padding(vertical = 15.dp),
            ) {
                Icon(Icons.Filled.PlayArrow, null, tint = colors.background, modifier = Modifier.size(20.dp))
                Spacer(Modifier.size(8.dp))
                Text(Loc.get("Play All"), color = colors.background, fontSize = 16.sp, fontWeight = FontWeight.SemiBold)
            }

            Column(
                verticalArrangement = Arrangement.spacedBy(10.dp),
                modifier = Modifier.padding(horizontal = 20.dp, vertical = 4.dp),
            ) {
                vm.presets.forEach { preset ->
                    PresetRow(vm, preset, onRename = { renaming = preset })
                }
            }
        }
        Spacer(Modifier.height(bottomPadding + 16.dp))
    }

    renaming?.let { preset ->
        RenamePresetDialog(
            initial = preset.name,
            onDismiss = { renaming = null },
            onSave = { vm.renamePreset(preset, it); renaming = null },
        )
    }
}

@Composable
private fun PresetRow(vm: AppViewModel, preset: Preset, onRename: () -> Unit) {
    val colors = Theme.colors
    val artwork = rememberArtwork(preset.artworkName)
    var menu by remember { mutableStateOf(false) }

    Row(
        verticalAlignment = Alignment.CenterVertically,
        modifier = Modifier
            .fillMaxWidth()
            .clip(RoundedCornerShape(16.dp))
            .background(colors.surface)
            .border(1.dp, colors.stroke, RoundedCornerShape(16.dp))
            .padding(12.dp),
    ) {
        Box(
            contentAlignment = Alignment.Center,
            modifier = Modifier.size(52.dp).clip(RoundedCornerShape(12.dp)).background(colors.surfaceRaised),
        ) {
            if (artwork != null) {
                androidx.compose.foundation.Image(
                    bitmap = artwork,
                    contentDescription = null,
                    contentScale = androidx.compose.ui.layout.ContentScale.Crop,
                    modifier = Modifier.size(52.dp).clip(RoundedCornerShape(12.dp)),
                )
            } else {
                Icon(Icons.Filled.MusicNote, null, tint = colors.textTertiary, modifier = Modifier.size(22.dp))
            }
        }

        Column(Modifier.weight(1f).padding(horizontal = 12.dp)) {
            Text(preset.name, color = colors.textPrimary, fontSize = 16.sp, fontWeight = FontWeight.SemiBold, maxLines = 1)
            Text(preset.subtitle, color = colors.textSecondary, fontSize = 12.sp, maxLines = 1)
        }

        Icon(
            Icons.Filled.PlayCircle,
            contentDescription = "Play ${preset.name}",
            tint = colors.accent,
            modifier = Modifier.size(38.dp).clickable { vm.restore(preset) },
        )

        Box {
            Icon(
                Icons.Filled.MoreVert,
                contentDescription = "More",
                tint = colors.textSecondary,
                modifier = Modifier.size(36.dp).clip(RoundedCornerShape(50)).clickable { menu = true }.padding(7.dp),
            )
            DropdownMenu(expanded = menu, onDismissRequest = { menu = false }) {
                DropdownMenuItem(
                    text = { Text(Loc.get("Rename"), color = colors.textPrimary) },
                    leadingIcon = { Icon(Icons.Filled.Edit, null, tint = colors.textPrimary, modifier = Modifier.size(20.dp)) },
                    onClick = { menu = false; onRename() },
                )
                DropdownMenuItem(
                    text = { Text(Loc.get("Move Up"), color = if (vm.canMoveUp(preset)) colors.textPrimary else colors.textTertiary) },
                    leadingIcon = { Icon(Icons.Filled.ArrowUpward, null, tint = colors.textSecondary, modifier = Modifier.size(20.dp)) },
                    enabled = vm.canMoveUp(preset),
                    onClick = { menu = false; vm.movePresetUp(preset) },
                )
                DropdownMenuItem(
                    text = { Text(Loc.get("Move Down"), color = if (vm.canMoveDown(preset)) colors.textPrimary else colors.textTertiary) },
                    leadingIcon = { Icon(Icons.Filled.ArrowDownward, null, tint = colors.textSecondary, modifier = Modifier.size(20.dp)) },
                    enabled = vm.canMoveDown(preset),
                    onClick = { menu = false; vm.movePresetDown(preset) },
                )
                HorizontalDivider(color = colors.stroke)
                DropdownMenuItem(
                    text = { Text(Loc.get("Delete"), color = colors.danger) },
                    leadingIcon = { Icon(Icons.Filled.Delete, null, tint = colors.danger, modifier = Modifier.size(20.dp)) },
                    onClick = { menu = false; vm.deletePreset(preset) },
                )
            }
        }
    }
}

@Composable
private fun RenamePresetDialog(initial: String, onDismiss: () -> Unit, onSave: (String) -> Unit) {
    val colors = Theme.colors
    var name by remember { mutableStateOf(initial) }
    AlertDialog(
        onDismissRequest = onDismiss,
        containerColor = colors.surface,
        title = { Text(Loc.get("Rename Preset"), color = colors.textPrimary) },
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
            TextButton(onClick = { onSave(name) }) {
                Text(Loc.get("Save"), color = colors.accent, fontWeight = FontWeight.SemiBold)
            }
        },
        dismissButton = { TextButton(onClick = onDismiss) { Text(Loc.get("Cancel"), color = colors.textSecondary) } },
    )
}

@Composable
internal fun EmptyState(icon: @Composable () -> Unit, title: String, subtitle: String) {
    val colors = Theme.colors
    Column(
        horizontalAlignment = Alignment.CenterHorizontally,
        verticalArrangement = Arrangement.spacedBy(10.dp),
        modifier = Modifier.fillMaxWidth().padding(40.dp),
    ) {
        Box(
            contentAlignment = Alignment.Center,
            modifier = Modifier.size(72.dp).clip(CircleShape).background(colors.surface),
        ) { icon() }
        Text(title, color = colors.textPrimary, fontSize = 24.sp, fontWeight = FontWeight.SemiBold)
        Text(subtitle, color = colors.textSecondary, fontSize = 18.sp,
            textAlign = TextAlign.Center)
    }
}
