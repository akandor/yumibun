package com.toepper.rocks.yumibun.ui

import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.clickable
import androidx.compose.foundation.horizontalScroll
import androidx.compose.foundation.interaction.MutableInteractionSource
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Shuffle
import androidx.compose.material3.Icon
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.remember
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
import com.toepper.rocks.yumibun.data.Category
import com.toepper.rocks.yumibun.data.Loc
import com.toepper.rocks.yumibun.data.SoundCatalog
import com.toepper.rocks.yumibun.ui.theme.Theme

/** The original "Simple" home: a circular category strip, a header, and the sound grid. */
@Composable
fun SimpleHomeScreen(
    vm: AppViewModel,
    selectedCategoryId: String,
    onSelectCategory: (String) -> Unit,
    topPadding: Dp,
    bottomPadding: Dp,
    columns: Int = 2,
) {
    val colors = Theme.colors
    val category = SoundCatalog.category(selectedCategoryId) ?: SoundCatalog.categories.first()

    Column(
        modifier = Modifier
            .fillMaxWidth()
            .background(colors.background)
            .verticalScroll(rememberScrollState())
            .padding(top = topPadding),
    ) {
        // Circular category strip
        Row(
            horizontalArrangement = Arrangement.spacedBy(4.dp),
            modifier = Modifier
                .horizontalScroll(rememberScrollState())
                .padding(horizontal = 16.dp, vertical = 12.dp),
        ) {
            CircleChip(
                icon = { Icon(Icons.Filled.Shuffle, null, tint = colors.accent, modifier = Modifier.size(20.dp)) },
                label = Loc.get("Shuffle"),
                selected = false,
                onClick = { vm.shuffle() },
            )
            SoundCatalog.categories.forEach { cat ->
                CircleChip(
                    icon = {
                        Icon(
                            iconForSymbol(cat.symbol),
                            null,
                            tint = if (cat.id == selectedCategoryId) colors.accent else colors.textSecondary,
                            modifier = Modifier.size(20.dp),
                        )
                    },
                    label = cat.title,
                    selected = cat.id == selectedCategoryId,
                    onClick = { onSelectCategory(cat.id) },
                )
            }
        }

        // Header
        Column(
            horizontalAlignment = Alignment.CenterHorizontally,
            verticalArrangement = Arrangement.spacedBy(10.dp),
            modifier = Modifier.fillMaxWidth().padding(top = 8.dp, bottom = 18.dp),
        ) {
            Box(
                contentAlignment = Alignment.Center,
                modifier = Modifier
                    .size(62.dp)
                    .clip(CircleShape)
                    .border(1.dp, colors.stroke, CircleShape),
            ) {
                Icon(iconForSymbol(category.symbol), null, tint = colors.textPrimary, modifier = Modifier.size(24.dp))
            }
            Text(category.title, color = colors.textPrimary, fontSize = 28.sp, fontFamily = FontFamily.Serif)
        }

        // Grid
        Column(
            verticalArrangement = Arrangement.spacedBy(12.dp),
            modifier = Modifier.padding(horizontal = 20.dp),
        ) {
            category.sounds.chunked(columns).forEach { row ->
                Row(horizontalArrangement = Arrangement.spacedBy(12.dp)) {
                    row.forEach { sound ->
                        SoundCard(sound = sound, vm = vm, modifier = Modifier.weight(1f))
                    }
                    repeat(columns - row.size) { Spacer(Modifier.weight(1f)) }
                }
            }
        }

        Spacer(Modifier.height(bottomPadding + 16.dp))
    }
}

@Composable
private fun CircleChip(
    icon: @Composable () -> Unit,
    label: String,
    selected: Boolean,
    onClick: () -> Unit,
) {
    val colors = Theme.colors
    Column(
        horizontalAlignment = Alignment.CenterHorizontally,
        verticalArrangement = Arrangement.spacedBy(8.dp),
        modifier = Modifier
            .width(72.dp)
            .clickable(
                interactionSource = remember { MutableInteractionSource() },
                indication = null,
            ) { onClick() },
    ) {
        Box(
            contentAlignment = Alignment.Center,
            modifier = Modifier
                .size(56.dp)
                .clip(CircleShape)
                .background(if (selected) colors.accent.copy(alpha = 0.16f) else colors.surface)
                .border(
                    if (selected) 1.5.dp else 1.dp,
                    if (selected) colors.accent else colors.stroke,
                    CircleShape,
                ),
        ) { icon() }
        Text(
            text = label,
            color = if (selected) colors.textPrimary else colors.textTertiary,
            fontSize = 13.sp,
            fontWeight = FontWeight.Medium,
            textAlign = TextAlign.Center,
            maxLines = 2,
            modifier = Modifier.height(32.dp),
        )
    }
}
