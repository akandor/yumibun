package com.toepper.rocks.yumibun.ui

import androidx.compose.foundation.Image
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
import androidx.compose.foundation.layout.WindowInsets
import androidx.compose.foundation.layout.asPaddingValues
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.statusBars
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
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
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.layout.ContentScale
import androidx.compose.ui.text.font.FontFamily
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.toepper.rocks.yumibun.AppViewModel
import com.toepper.rocks.yumibun.data.Category
import com.toepper.rocks.yumibun.data.Loc
import com.toepper.rocks.yumibun.data.SoundCatalog
import com.toepper.rocks.yumibun.ui.theme.Theme

@Composable
fun HomeScreen(
    vm: AppViewModel,
    selectedCategoryId: String,
    onSelectCategory: (String) -> Unit,
    bottomPadding: androidx.compose.ui.unit.Dp,
    columns: Int = 2,
) {
    val colors = Theme.colors
    val category = SoundCatalog.category(selectedCategoryId) ?: SoundCatalog.categories.first()

    Column(
        modifier = Modifier
            .fillMaxWidth()
            .background(colors.background)
            .verticalScroll(rememberScrollState()),
    ) {
        CategoryHero(category = category, onShuffle = { vm.shuffle() })

        Spacer(Modifier.height(18.dp))

        CategoryPills(
            selectedId = selectedCategoryId,
            onSelect = onSelectCategory,
        )

        Spacer(Modifier.height(18.dp))

        // Two-column grid (small lists — no need for lazy).
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
private fun CategoryHero(category: Category, onShuffle: () -> Unit) {
    val colors = Theme.colors
    val artwork = rememberArtwork(category.artworkName)
    val topInset = WindowInsets.statusBars.asPaddingValues().calculateTopPadding()
    val heroHeight = 300.dp + topInset

    Box(modifier = Modifier.fillMaxWidth().height(heroHeight)) {
        if (artwork != null) {
            Image(
                bitmap = artwork,
                contentDescription = null,
                contentScale = ContentScale.Crop,
                modifier = Modifier.fillMaxWidth().height(heroHeight),
            )
        } else {
            Box(Modifier.fillMaxWidth().height(heroHeight).background(colors.surfaceRaised))
        }

        // Legibility scrim
        Box(
            Modifier.fillMaxWidth().height(heroHeight).background(
                Brush.verticalGradient(
                    0f to Color.Transparent,
                    0.55f to Color.Black.copy(alpha = 0.25f),
                    1f to Color.Black.copy(alpha = 0.62f),
                )
            )
        )
        // Blend to background at the very bottom
        Box(
            Modifier.fillMaxWidth().height(heroHeight).background(
                Brush.verticalGradient(
                    0.72f to Color.Transparent,
                    0.9f to colors.background.copy(alpha = 0.55f),
                    1f to colors.background,
                )
            )
        )

        // Content, bottom-start
        Column(
            verticalArrangement = Arrangement.spacedBy(10.dp),
            modifier = Modifier
                .align(Alignment.BottomStart)
                .padding(horizontal = 24.dp)
                .padding(bottom = 34.dp),
        ) {
            Box(
                contentAlignment = Alignment.Center,
                modifier = Modifier
                    .size(52.dp)
                    .clip(CircleShape)
                    .background(Color.Black.copy(alpha = 0.3f)),
            ) {
                Icon(
                    imageVector = iconForSymbol(category.symbol),
                    contentDescription = null,
                    tint = colors.accentPalette.colorOnDark,
                    modifier = Modifier.size(22.dp),
                )
            }
            Text(
                text = category.title,
                color = Color.White,
                fontSize = 44.sp,
                fontFamily = FontFamily.Serif,
            )
            Text(
                text = Loc.get("%lld relaxing sounds", category.sounds.size),
                color = colors.accentPalette.colorOnDark,
                fontSize = 17.sp,
                fontWeight = FontWeight.SemiBold,
            )
            Text(
                text = category.sounds.take(3).joinToString("  •  ") { it.label },
                color = Color.White.copy(alpha = 0.82f),
                fontSize = 15.sp,
                fontWeight = FontWeight.Medium,
            )
        }

        // Shuffle button, top-end
        Box(
            contentAlignment = Alignment.Center,
            modifier = Modifier
                .align(Alignment.TopEnd)
                .padding(top = topInset + 8.dp, end = 20.dp)
                .size(44.dp)
                .clip(CircleShape)
                .background(Color.Black.copy(alpha = 0.3f))
                .clickable { onShuffle() },
        ) {
            Icon(
                imageVector = Icons.Filled.Shuffle,
                contentDescription = "Shuffle sounds",
                tint = Color.White,
                modifier = Modifier.size(18.dp),
            )
        }
    }
}

@Composable
private fun CategoryPills(selectedId: String, onSelect: (String) -> Unit) {
    Row(
        horizontalArrangement = Arrangement.spacedBy(10.dp),
        modifier = Modifier
            .fillMaxWidth()
            .horizontalScroll(rememberScrollState())
            .padding(horizontal = 20.dp),
    ) {
        SoundCatalog.categories.forEach { category ->
            CategoryPill(
                category = category,
                selected = category.id == selectedId,
                onClick = { onSelect(category.id) },
            )
        }
    }
}

@Composable
private fun CategoryPill(category: Category, selected: Boolean, onClick: () -> Unit) {
    val colors = Theme.colors
    Row(
        verticalAlignment = Alignment.CenterVertically,
        horizontalArrangement = Arrangement.spacedBy(8.dp),
        modifier = Modifier
            .clip(RoundedCornerShape(50))
            .background(if (selected) colors.accent.copy(alpha = 0.16f) else colors.surface)
            .border(
                1.dp,
                if (selected) colors.accent.copy(alpha = 0.5f) else colors.stroke,
                RoundedCornerShape(50),
            )
            .clickable(
                interactionSource = remember { MutableInteractionSource() },
                indication = null,
            ) { onClick() }
            .padding(horizontal = 18.dp, vertical = 12.dp),
    ) {
        Icon(
            imageVector = iconForSymbol(category.symbol),
            contentDescription = null,
            tint = if (selected) colors.accent else colors.textSecondary,
            modifier = Modifier.size(18.dp),
        )
        Text(
            text = category.title,
            color = if (selected) colors.accent else colors.textSecondary,
            fontSize = 15.sp,
            fontWeight = FontWeight.Medium,
        )
    }
}
