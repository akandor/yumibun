package com.toepper.rocks.yumibun.ui

import android.content.Intent
import android.net.Uri
import android.provider.Settings
import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.clickable
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
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Language
import androidx.compose.material.icons.filled.OpenInNew
import androidx.compose.material.icons.filled.PlayArrow
import androidx.compose.material.icons.filled.Stop
import androidx.compose.material3.HorizontalDivider
import androidx.compose.material3.Icon
import androidx.compose.material3.SegmentedButton
import androidx.compose.material3.SegmentedButtonColors
import androidx.compose.material3.SegmentedButtonDefaults
import androidx.compose.material3.SingleChoiceSegmentedButtonRow
import androidx.compose.material3.Switch
import androidx.compose.material3.SwitchDefaults
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.remember
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.platform.LocalConfiguration
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.text.font.FontFamily
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.Dp
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.toepper.rocks.yumibun.AppViewModel
import com.toepper.rocks.yumibun.data.Loc
import com.toepper.rocks.yumibun.ui.theme.AccentPalette
import com.toepper.rocks.yumibun.ui.theme.AppearanceMode
import com.toepper.rocks.yumibun.ui.theme.HomeStyle
import com.toepper.rocks.yumibun.ui.theme.Theme

@Composable
fun SettingsScreen(vm: AppViewModel, topPadding: Dp, bottomPadding: Dp) {
    val colors = Theme.colors

    Column(
        modifier = Modifier
            .fillMaxSize()
            .background(colors.background)
            .verticalScroll(rememberScrollState())
            .padding(top = topPadding),
    ) {
        ScreenTitle(Loc.get("Settings"))

        LogoHeader()

        Column(
            verticalArrangement = Arrangement.spacedBy(20.dp),
            modifier = Modifier.padding(horizontal = 20.dp, vertical = 8.dp),
        ) {
            // Appearance
            SettingsCard {
                CardHeader(Loc.get("Appearance"), Loc.get("System follows your device setting."))
                Spacer(Modifier.height(12.dp))
                SingleChoiceSegmentedButtonRow(Modifier.fillMaxWidth()) {
                    AppearanceMode.entries.forEachIndexed { i, mode ->
                        SegmentedButton(
                            selected = vm.appearance == mode,
                            onClick = { vm.chooseAppearance(mode) },
                            shape = SegmentedButtonDefaults.itemShape(i, AppearanceMode.entries.size),
                            colors = accentSegmentColors(),
                        ) { Text(Loc.get(mode.label)) }
                    }
                }
            }

            // Home style
            SettingsCard {
                CardHeader(Loc.get("Home Style"), Loc.get("Modern shows a photo hero; Simple uses the category strip."))
                Spacer(Modifier.height(12.dp))
                SingleChoiceSegmentedButtonRow(Modifier.fillMaxWidth()) {
                    HomeStyle.entries.forEachIndexed { i, style ->
                        SegmentedButton(
                            selected = vm.homeStyle == style,
                            onClick = { vm.chooseHomeStyle(style) },
                            shape = SegmentedButtonDefaults.itemShape(i, HomeStyle.entries.size),
                            colors = accentSegmentColors(),
                        ) { Text(Loc.get(style.label)) }
                    }
                }
            }

            // Accent
            SettingsCard {
                CardHeader(Loc.get("Accent"), Loc.get(vm.accent.label))
                Spacer(Modifier.height(14.dp))
                Row(horizontalArrangement = Arrangement.spacedBy(14.dp)) {
                    AccentPalette.entries.forEach { palette ->
                        AccentSwatch(
                            palette = palette,
                            selected = vm.accent == palette,
                            onClick = { vm.chooseAccent(palette) },
                        )
                    }
                }
            }

            // Language (deep-links to the system per-app language screen)
            LanguageCard()

            // Audio
            SettingsCard {
                Column(verticalArrangement = Arrangement.spacedBy(16.dp)) {
                    VolumeRow(Loc.get("Global Volume"), Loc.get("Scales every sound in the mix."), vm.masterVolume) {
                        vm.updateMasterVolume(it)
                    }
                    HorizontalDivider(color = colors.stroke)
                    Row(verticalAlignment = Alignment.CenterVertically) {
                        Column(Modifier.weight(1f)) {
                            VolumeRow(Loc.get("Alarm Volume"), Loc.get("Used by the timers."), vm.alarmVolume) {
                                vm.setAlarmVolume(it)
                            }
                        }
                        Box(
                            contentAlignment = Alignment.Center,
                            modifier = Modifier
                                .padding(start = 8.dp)
                                .size(30.dp)
                                .clip(CircleShape)
                                .background(colors.accent)
                                .clickable { vm.toggleAlarmPreview() },
                        ) {
                            Icon(
                                if (vm.isPreviewingAlarm) Icons.Filled.Stop else Icons.Filled.PlayArrow,
                                contentDescription = Loc.get("Preview alarm"),
                                tint = colors.background,
                                modifier = Modifier.size(16.dp),
                            )
                        }
                    }
                    HorizontalDivider(color = colors.stroke)
                    Row(verticalAlignment = Alignment.CenterVertically) {
                        Column(Modifier.weight(1f)) {
                            Text(Loc.get("Vibration"), color = colors.textPrimary, fontSize = 15.sp, fontWeight = FontWeight.Medium)
                            Text(Loc.get("Vibrate when the alarm sounds."), color = colors.textTertiary, fontSize = 12.sp)
                        }
                        Switch(
                            checked = vm.vibrationEnabled,
                            onCheckedChange = { vm.setVibration(it) },
                            colors = SwitchDefaults.colors(
                                checkedThumbColor = colors.background,
                                checkedTrackColor = colors.accent,
                            ),
                        )
                    }
                }
            }

            AboutSection()
            AttributionSection()
            LicenseSection()
            ArtworkSection()
        }

        Spacer(Modifier.height(bottomPadding + 16.dp))
    }
}

@Composable
private fun LogoHeader() {
    val colors = Theme.colors
    Column(
        horizontalAlignment = Alignment.CenterHorizontally,
        verticalArrangement = Arrangement.spacedBy(14.dp),
        modifier = Modifier.fillMaxWidth().padding(top = 8.dp, bottom = 16.dp),
    ) {
        LogoMark(size = 72.dp)
        Column(
            horizontalAlignment = Alignment.CenterHorizontally,
            verticalArrangement = Arrangement.spacedBy(6.dp),
        ) {
            Text("Yumibun", color = colors.textPrimary, fontSize = 28.sp, fontFamily = FontFamily.Serif)
            Text(
                Loc.get("Focus, relax & sleep\nYume (夢, dream) + Kibun (気分, mood) → Yumibun"),
                color = colors.textSecondary,
                fontSize = 14.sp,
                textAlign = TextAlign.Center,
                lineHeight = 20.sp,
            )
        }
    }
}

@Composable
private fun AboutSection() {
    val colors = Theme.colors
    val context = LocalContext.current
    val version = remember {
        runCatching {
            val info = context.packageManager.getPackageInfo(context.packageName, 0)
            "Version ${info.versionName} (${info.longVersionCode})"
        }.getOrDefault("")
    }
    Column(
        horizontalAlignment = Alignment.CenterHorizontally,
        verticalArrangement = Arrangement.spacedBy(14.dp),
        modifier = Modifier.fillMaxWidth(),
    ) {
        Text(Loc.get("Free and Open Source"), color = colors.textSecondary, fontSize = 13.sp, fontWeight = FontWeight.Medium)
        if (version.isNotEmpty()) Text(version, color = colors.textTertiary, fontSize = 12.sp)
        SettingsCard {
            Column {
                LinkRow("Toepper.Rocks", "https://toepper.rocks")
                HorizontalDivider(color = colors.stroke)
                LinkRow("akandor/yumibun", "https://github.com/akandor/yumibun")
            }
        }
    }
}

@Composable
private fun AttributionSection() {
    val colors = Theme.colors
    Column(
        horizontalAlignment = Alignment.CenterHorizontally,
        verticalArrangement = Arrangement.spacedBy(14.dp),
        modifier = Modifier.fillMaxWidth(),
    ) {
        Text(
            Loc.get("Yumibun is based on the Open-Source project Moodist"),
            color = colors.textSecondary,
            fontSize = 13.sp,
            fontWeight = FontWeight.Medium,
            textAlign = TextAlign.Center,
        )
        SettingsCard {
            Column {
                LinkRow("moodist.mvze.net", "https://moodist.mvze.net/")
                HorizontalDivider(color = colors.stroke)
                LinkRow("remvze/moodist", "https://github.com/remvze/moodist")
            }
        }
    }
}

@Composable
private fun LicenseSection() {
    val colors = Theme.colors
    Column(
        horizontalAlignment = Alignment.CenterHorizontally,
        verticalArrangement = Arrangement.spacedBy(14.dp),
        modifier = Modifier.fillMaxWidth(),
    ) {
        Text(Loc.get("License"), color = colors.textSecondary, fontSize = 16.sp, fontWeight = FontWeight.Medium)
        Text(
            Loc.get("Moodist and Yumibun are licensed under the MIT License"),
            color = colors.textSecondary,
            fontSize = 14.sp,
            textAlign = TextAlign.Center,
        )
        SettingsCard {
            Column {
                LinkRow(Loc.get("Moodist License"), "https://github.com/remvze/moodist/blob/main/LICENSE")
                HorizontalDivider(color = colors.stroke)
                LinkRow(Loc.get("Yumibun License"), "https://github.com/akandor/yumibun/blob/main/LICENSE")
            }
        }
        Text(
            Loc.get("Some sounds are sourced from third-party providers under different licenses:"),
            color = colors.textSecondary,
            fontSize = 14.sp,
            textAlign = TextAlign.Center,
        )
        SettingsCard {
            Column {
                LinkRow(Loc.get("Pixabay Content License"), "https://pixabay.com/service/license-summary/")
                HorizontalDivider(color = colors.stroke)
                LinkRow(Loc.get("Creative Commons Zero License"), "https://creativecommons.org/publicdomain/zero/1.0/")
            }
        }
    }
}

private data class ArtworkCredit(val category: String, val url: String)

private val artworkCredits = listOf(
    ArtworkCredit("Nature", "https://commons.wikimedia.org/wiki/File:Creek_in_the_dark_forest_(Unsplash).jpg"),
    ArtworkCredit("Rain", "https://commons.wikimedia.org/wiki/File:Foggy_glass_unsplash_2.jpg"),
    ArtworkCredit("Animals", "https://commons.wikimedia.org/wiki/File:Deer,_Watching_(Unsplash).jpg"),
    ArtworkCredit("Urban", "https://commons.wikimedia.org/wiki/File:Cityscape_and_traffic_light_trails_(Unsplash).jpg"),
    ArtworkCredit("Places", "https://commons.wikimedia.org/wiki/File:Empty_coffee_shop_interior_with_wooden_table_and_water_skis.jpg"),
    ArtworkCredit("Transport", "https://commons.wikimedia.org/wiki/File:Outdoor_train_railway_(Unsplash).jpg"),
    ArtworkCredit("Things", "https://commons.wikimedia.org/wiki/File:Typewriter_(Unsplash).jpg"),
    ArtworkCredit("Noise", "https://commons.wikimedia.org/wiki/File:Fog_covered_mountain_forest_(Unsplash).jpg"),
)

@Composable
private fun ArtworkSection() {
    val colors = Theme.colors
    Column(
        horizontalAlignment = Alignment.CenterHorizontally,
        verticalArrangement = Arrangement.spacedBy(14.dp),
        modifier = Modifier.fillMaxWidth(),
    ) {
        Text(Loc.get("Artwork"), color = colors.textSecondary, fontSize = 16.sp, fontWeight = FontWeight.Medium)
        Text(
            Loc.get("Category artwork is sourced from Wikimedia Commons and dedicated to the public domain (CC0)."),
            color = colors.textSecondary,
            fontSize = 14.sp,
            textAlign = TextAlign.Center,
        )
        SettingsCard {
            Column {
                artworkCredits.forEachIndexed { index, credit ->
                    if (index > 0) HorizontalDivider(color = colors.stroke)
                    LinkRow(credit.category, credit.url)
                }
            }
        }
    }
}

@Composable
private fun LinkRow(title: String, url: String) {
    val colors = Theme.colors
    val context = LocalContext.current
    Row(
        horizontalArrangement = Arrangement.Center,
        verticalAlignment = Alignment.CenterVertically,
        modifier = Modifier
            .fillMaxWidth()
            .clickable {
                runCatching { context.startActivity(Intent(Intent.ACTION_VIEW, Uri.parse(url))) }
            }
            .padding(vertical = 12.dp),
    ) {
        Text(title, color = colors.textPrimary, fontSize = 14.sp, fontWeight = FontWeight.Medium)
        Spacer(Modifier.size(6.dp))
        Icon(Icons.Filled.OpenInNew, contentDescription = null, tint = colors.textTertiary, modifier = Modifier.size(13.dp))
    }
}

@Composable
private fun VolumeRow(title: String, subtitle: String, value: Float, onChange: (Float) -> Unit) {
    val colors = Theme.colors
    Column(verticalArrangement = Arrangement.spacedBy(4.dp)) {
        Text(title, color = colors.textPrimary, fontSize = 15.sp, fontWeight = FontWeight.Medium)
        Text(subtitle, color = colors.textTertiary, fontSize = 12.sp)
        MusicSlider(
            value = value,
            onValueChange = onChange,
        )
    }
}

@Composable
private fun accentSegmentColors(): SegmentedButtonColors {
    val colors = Theme.colors
    return SegmentedButtonDefaults.colors(
        activeContainerColor = colors.accent.copy(alpha = 0.16f),
        activeContentColor = colors.accent,
        activeBorderColor = colors.accent.copy(alpha = 0.5f),
        inactiveContainerColor = colors.surface,
        inactiveContentColor = colors.textSecondary,
        inactiveBorderColor = colors.stroke,
    )
}

@Composable
private fun SettingsCard(content: @Composable () -> Unit) {
    val colors = Theme.colors
    Column(
        modifier = Modifier
            .fillMaxWidth()
            .clip(RoundedCornerShape(18.dp))
            .background(colors.surface)
            .border(1.dp, colors.stroke, RoundedCornerShape(18.dp))
            .padding(16.dp),
    ) { content() }
}

@Composable
private fun LanguageCard() {
    val colors = Theme.colors
    val context = LocalContext.current
    val locale = LocalConfiguration.current.locales[0]
    val currentLanguage = remember(locale) {
        locale.getDisplayName(locale).replaceFirstChar { it.uppercase(locale) }
    }
    SettingsCard {
        CardHeader(Loc.get("Language"), Loc.get("Set a language just for Yumibun."))
        Spacer(Modifier.height(12.dp))
        Row(
            verticalAlignment = Alignment.CenterVertically,
            modifier = Modifier
                .fillMaxWidth()
                .clip(RoundedCornerShape(12.dp))
                .clickable {
                    val appLocale = Intent(Settings.ACTION_APP_LOCALE_SETTINGS)
                        .setData(Uri.fromParts("package", context.packageName, null))
                    val details = Intent(Settings.ACTION_APPLICATION_DETAILS_SETTINGS)
                        .setData(Uri.fromParts("package", context.packageName, null))
                    runCatching { context.startActivity(appLocale) }
                        .onFailure { runCatching { context.startActivity(details) } }
                }
                .padding(vertical = 6.dp),
        ) {
            Icon(Icons.Filled.Language, contentDescription = null, tint = colors.textSecondary, modifier = Modifier.size(20.dp))
            Spacer(Modifier.size(12.dp))
            Text(
                currentLanguage,
                color = colors.textPrimary,
                fontSize = 15.sp,
                fontWeight = FontWeight.Medium,
                modifier = Modifier.weight(1f),
            )
            Icon(Icons.Filled.OpenInNew, contentDescription = null, tint = colors.textTertiary, modifier = Modifier.size(16.dp))
        }
    }
}

@Composable
private fun CardHeader(title: String, subtitle: String) {
    val colors = Theme.colors
    Column(verticalArrangement = Arrangement.spacedBy(2.dp)) {
        Text(title, color = colors.textPrimary, fontSize = 15.sp, fontWeight = FontWeight.Medium)
        Text(subtitle, color = colors.textTertiary, fontSize = 12.sp)
    }
}

@Composable
private fun AccentSwatch(palette: AccentPalette, selected: Boolean, onClick: () -> Unit) {
    val colors = Theme.colors
    Box(
        contentAlignment = Alignment.Center,
        modifier = Modifier
            .size(38.dp)
            .clip(CircleShape)
            .clickable { onClick() },
    ) {
        Box(
            modifier = Modifier
                .size(30.dp)
                .clip(CircleShape)
                .background(palette.color(colors.isDark))
                .border(1.dp, colors.stroke, CircleShape),
        )
        if (selected) {
            Box(
                modifier = Modifier
                    .size(38.dp)
                    .clip(CircleShape)
                    .border(2.dp, colors.textPrimary, CircleShape),
            )
        }
    }
}
