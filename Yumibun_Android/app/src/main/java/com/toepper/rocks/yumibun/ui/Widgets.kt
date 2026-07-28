package com.toepper.rocks.yumibun.ui

import androidx.compose.foundation.text.BasicText
import androidx.compose.foundation.text.TextAutoSize
import androidx.compose.runtime.Composable
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.text.TextStyle
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.TextUnit
import androidx.compose.ui.unit.sp

/**
 * A single-line label that shrinks its font to fit the available width instead of
 * wrapping or truncating — used for long localized strings (nav labels, segmented
 * buttons) where e.g. German words don't fit at the design size.
 */
@Composable
fun AutoSizeLabel(
    text: String,
    color: Color,
    maxFontSize: TextUnit,
    modifier: Modifier = Modifier,
    minFontSize: TextUnit = 8.sp,
    fontWeight: FontWeight = FontWeight.Medium,
) {
    BasicText(
        text = text,
        modifier = modifier,
        maxLines = 1,
        softWrap = false,
        style = TextStyle(color = color, fontWeight = fontWeight, textAlign = TextAlign.Center),
        autoSize = TextAutoSize.StepBased(minFontSize = minFontSize, maxFontSize = maxFontSize),
    )
}
