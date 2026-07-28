package com.toepper.rocks.yumibun.ui

import androidx.compose.foundation.background
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.WindowInsets
import androidx.compose.foundation.layout.asPaddingValues
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxHeight
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.statusBars
import androidx.compose.foundation.layout.widthIn
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Favorite
import androidx.compose.material.icons.filled.Home
import androidx.compose.material.icons.filled.Psychology
import androidx.compose.material.icons.filled.QueueMusic
import androidx.compose.material.icons.filled.Settings
import androidx.compose.material3.Icon
import androidx.compose.material3.NavigationBar
import androidx.compose.material3.NavigationBarItem
import androidx.compose.material3.NavigationBarItemDefaults
import androidx.compose.material3.NavigationRail
import androidx.compose.material3.NavigationRailItem
import androidx.compose.material3.NavigationRailItemDefaults
import androidx.compose.material3.Scaffold
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.saveable.rememberSaveable
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.platform.LocalConfiguration
import androidx.compose.ui.unit.Dp
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.toepper.rocks.yumibun.AppViewModel
import com.toepper.rocks.yumibun.data.Loc
import com.toepper.rocks.yumibun.data.SoundCatalog
import com.toepper.rocks.yumibun.ui.theme.HomeStyle
import com.toepper.rocks.yumibun.ui.theme.Theme

private enum class Tab(val label: String, val icon: ImageVector) {
    Home("Home", Icons.Filled.Home),
    Presets("Presets", Icons.Filled.QueueMusic),
    Favorites("Favorites", Icons.Filled.Favorite),
    Neuro("Neuro", Icons.Filled.Psychology),
    Settings("Settings", Icons.Filled.Settings),
}

@Composable
fun App(vm: AppViewModel) {
    val colors = Theme.colors
    var tab by rememberSaveable { mutableStateOf(Tab.Home) }
    var categoryId by rememberSaveable { mutableStateOf(SoundCatalog.categories.first().id) }
    var showSaveDialog by remember { mutableStateOf(false) }
    var timerPick by remember { mutableStateOf<TimerPick?>(null) }
    var showFullPlayer by remember { mutableStateOf(false) }

    // Tablets (>=600dp) get a side rail + multi-column grids, like the iPad layout.
    val widthDp = LocalConfiguration.current.screenWidthDp
    val wide = widthDp >= 600
    val columns = if (wide) ((widthDp - 88) / 230).coerceIn(2, 5) else 2

    val playerDock: @Composable () -> Unit = {
        Column {
            GeneratorPill(vm, Modifier.padding(bottom = 8.dp))
            PlayerBar(
                vm = vm,
                onSave = { showSaveDialog = true },
                onSleep = { timerPick = TimerPick.Sleep },
                onCountdown = { timerPick = TimerPick.Countdown },
                onPomodoro = { timerPick = TimerPick.Pomodoro },
                onExpand = { showFullPlayer = true },
                modifier = Modifier.padding(bottom = 8.dp),
            )
        }
    }

    val content: @Composable (Dp, Dp) -> Unit = { bottomPadding, topInset ->
        Box(Modifier.fillMaxSize().background(colors.background)) {
            when (tab) {
                Tab.Home -> when (vm.homeStyle) {
                    HomeStyle.Modern -> HomeScreen(vm, categoryId, { categoryId = it }, bottomPadding, columns)
                    HomeStyle.Simple -> SimpleHomeScreen(vm, categoryId, { categoryId = it }, topInset, bottomPadding, columns)
                }
                Tab.Presets -> Constrained(wide) { PresetsScreen(vm, topInset, bottomPadding) }
                Tab.Favorites -> FavoritesScreen(vm, topInset, bottomPadding, columns)
                Tab.Neuro -> Constrained(wide) { NeuroScreen(vm, topInset, bottomPadding) }
                Tab.Settings -> Constrained(wide) { SettingsScreen(vm, topInset, bottomPadding) }
            }
        }
    }

    Box(Modifier.fillMaxSize()) {
        if (wide) {
            Row(Modifier.fillMaxSize().background(colors.background)) {
                AppRail(tab, colors) { tab = it }
                Box(Modifier.weight(1f)) {
                    Scaffold(containerColor = colors.background, bottomBar = playerDock) { pad ->
                        content(pad.calculateBottomPadding(), WindowInsets.statusBars.asPaddingValues().calculateTopPadding())
                    }
                }
            }
        } else {
            Scaffold(
                containerColor = colors.background,
                bottomBar = {
                    Column {
                        playerDock()
                        AppBottomBar(tab, colors) { tab = it }
                    }
                },
            ) { pad ->
                content(pad.calculateBottomPadding(), WindowInsets.statusBars.asPaddingValues().calculateTopPadding())
            }
        }

        if (showFullPlayer && vm.hasSelection) {
            FullPlayer(
                vm = vm,
                onClose = { showFullPlayer = false },
                onSave = { showSaveDialog = true },
                onSleep = { timerPick = TimerPick.Sleep },
                onCountdown = { timerPick = TimerPick.Countdown },
                onPomodoro = { timerPick = TimerPick.Pomodoro },
            )
        }
    }

    if (showSaveDialog) SavePresetDialog(vm) { showSaveDialog = false }
    timerPick?.let { pick -> TimerDialog(vm, pick) { timerPick = null } }
    SharedMixDialog(vm)
}

/** Centers content within a readable max width on wide (tablet) layouts. */
@Composable
private fun Constrained(wide: Boolean, content: @Composable () -> Unit) {
    if (wide) {
        Box(Modifier.fillMaxSize(), contentAlignment = Alignment.TopCenter) {
            Box(Modifier.widthIn(max = 720.dp).fillMaxSize()) { content() }
        }
    } else {
        content()
    }
}

@Composable
private fun AppBottomBar(tab: Tab, colors: com.toepper.rocks.yumibun.ui.theme.YumibunColors, onSelect: (Tab) -> Unit) {
    NavigationBar(containerColor = colors.surface) {
        Tab.entries.forEach { t ->
            NavigationBarItem(
                selected = tab == t,
                onClick = { onSelect(t) },
                icon = { Icon(t.icon, contentDescription = Loc.get(t.label)) },
                label = {
                    AutoSizeLabel(
                        text = Loc.get(t.label),
                        color = if (tab == t) colors.accent else colors.textSecondary,
                        maxFontSize = 12.sp,
                    )
                },
                colors = NavigationBarItemDefaults.colors(
                    selectedIconColor = colors.accent,
                    selectedTextColor = colors.accent,
                    indicatorColor = colors.accent.copy(alpha = 0.16f),
                    unselectedIconColor = colors.textSecondary,
                    unselectedTextColor = colors.textSecondary,
                ),
            )
        }
    }
}

@Composable
private fun AppRail(tab: Tab, colors: com.toepper.rocks.yumibun.ui.theme.YumibunColors, onSelect: (Tab) -> Unit) {
    NavigationRail(
        containerColor = colors.surface,
        modifier = Modifier.fillMaxHeight(),
    ) {
        Column(
            modifier = Modifier.fillMaxHeight().padding(vertical = 8.dp),
            verticalArrangement = Arrangement.Center,
            horizontalAlignment = Alignment.CenterHorizontally,
        ) {
            Tab.entries.forEach { t ->
                NavigationRailItem(
                    selected = tab == t,
                    onClick = { onSelect(t) },
                    icon = { Icon(t.icon, contentDescription = Loc.get(t.label)) },
                    label = { AutoSizeLabel(Loc.get(t.label), if (tab == t) colors.accent else colors.textSecondary, 12.sp) },
                    colors = NavigationRailItemDefaults.colors(
                        selectedIconColor = colors.accent,
                        selectedTextColor = colors.accent,
                        indicatorColor = colors.accent.copy(alpha = 0.16f),
                        unselectedIconColor = colors.textSecondary,
                        unselectedTextColor = colors.textSecondary,
                    ),
                )
            }
        }
    }
}
