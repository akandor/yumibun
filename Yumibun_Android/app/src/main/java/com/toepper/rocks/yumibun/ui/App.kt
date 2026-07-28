package com.toepper.rocks.yumibun.ui

import androidx.compose.foundation.background
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.PaddingValues
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.WindowInsets
import androidx.compose.foundation.layout.asPaddingValues
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.statusBars
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
import androidx.compose.material3.Scaffold
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.saveable.rememberSaveable
import androidx.compose.runtime.setValue
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.text.style.TextOverflow
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

    Box(Modifier.fillMaxSize()) {
    Scaffold(
        containerColor = colors.background,
        bottomBar = {
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
                NavigationBar(containerColor = colors.surface) {
                    Tab.entries.forEach { t ->
                        NavigationBarItem(
                            selected = tab == t,
                            onClick = { tab = t },
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
        },
    ) { innerPadding ->
        val bottomPadding = innerPadding.calculateBottomPadding()
        val topInset = WindowInsets.statusBars.asPaddingValues().calculateTopPadding()

        Box(Modifier.fillMaxSize().background(colors.background)) {
            when (tab) {
                Tab.Home -> when (vm.homeStyle) {
                    HomeStyle.Modern -> HomeScreen(
                        vm = vm,
                        selectedCategoryId = categoryId,
                        onSelectCategory = { categoryId = it },
                        bottomPadding = bottomPadding,
                    )
                    HomeStyle.Simple -> SimpleHomeScreen(
                        vm = vm,
                        selectedCategoryId = categoryId,
                        onSelectCategory = { categoryId = it },
                        topPadding = topInset,
                        bottomPadding = bottomPadding,
                    )
                }
                Tab.Presets -> PresetsScreen(vm, topInset, bottomPadding)
                Tab.Favorites -> FavoritesScreen(vm, topInset, bottomPadding)
                Tab.Neuro -> NeuroScreen(vm, topInset, bottomPadding)
                Tab.Settings -> SettingsScreen(vm, topInset, bottomPadding)
            }
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
