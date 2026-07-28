package com.toepper.rocks.yumibun.data

/** Binaural beats vs. isochronic tones — the two synthesis modes. */
enum class GeneratorType(val titleKey: String) {
    Binaural("Binaural Beats"),
    Isochronic("Isochronic Tones");

    val title: String get() = Loc.get(titleKey)

    /** The label for the second frequency field, which differs by type. */
    val beatLabel: String
        get() = Loc.get(if (this == Binaural) "Beat Frequency (Hz)" else "Tone Frequency (Hz)")
}

/**
 * A named brainwave preset. The same five presets apply to both modes — only what the
 * beat frequency drives differs. `frequency == null` is the editable Custom preset.
 */
data class GeneratorPreset(
    val id: String,
    val name: String,
    val state: String,
    val frequency: Double?,
) {
    val isCustom: Boolean get() = frequency == null

    /** Localized display name (Greek band names pass through unchanged). */
    val displayName: String get() = Loc.get(name)

    fun subtitle(type: GeneratorType): String {
        val f = frequency ?: return Loc.get("Set your own frequencies")
        val hz = if (f % 1.0 == 0.0) f.toInt().toString() else f.toString()
        return "${Loc.get(state)} · $hz Hz"
    }

    companion object {
        val presets: List<GeneratorPreset> = listOf(
            GeneratorPreset("delta", "Delta", "Deep Sleep", 2.0),
            GeneratorPreset("theta", "Theta", "Meditation", 5.0),
            GeneratorPreset("alpha", "Alpha", "Relaxation", 10.0),
            GeneratorPreset("beta", "Beta", "Focus", 20.0),
            GeneratorPreset("gamma", "Gamma", "Cognition", 40.0),
        )
        val custom = GeneratorPreset("custom", "Custom", "", null)
    }
}
