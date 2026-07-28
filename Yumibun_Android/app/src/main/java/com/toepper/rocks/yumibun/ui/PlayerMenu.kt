package com.toepper.rocks.yumibun.ui

import android.content.Intent
import androidx.compose.foundation.layout.size
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.AddCircle
import androidx.compose.material.icons.filled.Bedtime
import androidx.compose.material.icons.filled.DeleteOutline
import androidx.compose.material.icons.filled.Share
import androidx.compose.material.icons.filled.Timelapse
import androidx.compose.material.icons.filled.Timer
import androidx.compose.material3.DropdownMenu
import androidx.compose.material3.DropdownMenuItem
import androidx.compose.material3.HorizontalDivider
import androidx.compose.material3.Icon
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.unit.dp
import com.toepper.rocks.yumibun.AppViewModel
import com.toepper.rocks.yumibun.data.Loc
import com.toepper.rocks.yumibun.ui.theme.Theme

/** The shared player action menu (add preset / share / reset / timers), used by both the
 *  player bar and the full-screen player. Share and Reset are handled internally. */
@Composable
fun PlayerActionsDropdown(
    expanded: Boolean,
    onDismiss: () -> Unit,
    vm: AppViewModel,
    onSave: () -> Unit,
    onSleep: () -> Unit,
    onCountdown: () -> Unit,
    onPomodoro: () -> Unit,
) {
    val colors = Theme.colors
    val context = LocalContext.current
    DropdownMenu(expanded = expanded, onDismissRequest = onDismiss) {
        MenuRow(Loc.get("Add to presets"), Icons.Filled.AddCircle) { onDismiss(); onSave() }
        MenuRow(Loc.get("Share"), Icons.Filled.Share) {
            onDismiss()
            vm.shareUrl()?.let { url ->
                val send = Intent(Intent.ACTION_SEND).apply {
                    type = "text/plain"
                    putExtra(Intent.EXTRA_TEXT, url)
                }
                context.startActivity(Intent.createChooser(send, Loc.get("Share")))
            }
        }
        MenuRow(Loc.get("Reset"), Icons.Filled.DeleteOutline, tint = colors.danger) { onDismiss(); vm.resetMix() }
        HorizontalDivider(color = colors.stroke)
        MenuRow(Loc.get("Sleep timer"), Icons.Filled.Bedtime) { onDismiss(); onSleep() }
        MenuRow(Loc.get("Countdown timer"), Icons.Filled.Timer) { onDismiss(); onCountdown() }
        MenuRow(Loc.get("Pomodoro"), Icons.Filled.Timelapse) { onDismiss(); onPomodoro() }
    }
}

@Composable
private fun MenuRow(label: String, icon: ImageVector, tint: Color = Theme.colors.textPrimary, onClick: () -> Unit) {
    DropdownMenuItem(
        text = { Text(label, color = tint) },
        leadingIcon = { Icon(icon, null, tint = tint, modifier = Modifier.size(20.dp)) },
        onClick = onClick,
    )
}
