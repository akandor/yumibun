import SwiftUI

struct SettingsView: View {
    @EnvironmentObject private var mixer: SoundMixer
    @EnvironmentObject private var appearance: AppearanceSettings
    @EnvironmentObject private var alarm: AlarmSettings
    @EnvironmentObject private var language: LanguageSettings
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.background.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 28) {
                        logoSection
                        appearanceSection
                        homeStyleSection
                        accentSection
#if os(macOS)
                        // iOS gets a per-app language switch in the system Settings;
                        // macOS has no equivalent, so the app provides its own.
                        languageSection
#endif
                        audioSection
                        aboutSection
                        aboutTeopperSection
                        licenseSection
                        artworkSection
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 8)
                    .padding(.bottom, 32)
                }
            }
            .navigationTitle("Settings")
            .playerDock()
        }
    }

    // MARK: - Appearance

    private var appearanceSection: some View {
        SettingsCard {
            VStack(alignment: .leading, spacing: 12) {
                HStack(spacing: 10) {
                    Image(systemName: appearance.mode.icon)
                        .font(.system(size: 13))
                        .foregroundStyle(Theme.textSecondary)
                        .frame(width: 18)
                        .contentTransition(.symbolEffect(.replace))

                    VStack(alignment: .leading, spacing: 2) {
                        Text("Appearance")
                            .font(.system(size: 15, weight: .medium))
                            .foregroundStyle(Theme.textPrimary)
                        Text("System follows your device setting.")
                            .font(.system(size: 12))
                            .foregroundStyle(Theme.textTertiary)
                    }

                    Spacer(minLength: 8)

#if os(macOS)
                    // macOS: a compact dropdown on the trailing edge, matching the row
                    // controls, instead of a full-width segmented control below.
                    Picker("Appearance", selection: $appearance.mode) {
                        ForEach(AppearanceMode.allCases) { mode in
                            Text(mode.label).tag(mode)
                        }
                    }
                    .labelsHidden()
                    .pickerStyle(.menu)
                    .fixedSize()
#endif
                }

#if !os(macOS)
                Picker("Appearance", selection: $appearance.mode) {
                    ForEach(AppearanceMode.allCases) { mode in
                        Text(mode.label).tag(mode)
                    }
                }
                .pickerStyle(.segmented)
                .labelsHidden()
#endif
            }
        }
    }

    // MARK: - Home style

    private var homeStyleSection: some View {
        SettingsCard {
            VStack(alignment: .leading, spacing: 12) {
                HStack(spacing: 10) {
                    Image(systemName: appearance.homeStyle.icon)
                        .font(.system(size: 13))
                        .foregroundStyle(Theme.textSecondary)
                        .frame(width: 18)
                        .contentTransition(.symbolEffect(.replace))

                    VStack(alignment: .leading, spacing: 2) {
                        Text("Home Style")
                            .font(.system(size: 15, weight: .medium))
                            .foregroundStyle(Theme.textPrimary)
                        Text("Modern shows a photo hero; Simple uses the category strip.")
                            .font(.system(size: 12))
                            .foregroundStyle(Theme.textTertiary)
                    }

                    Spacer(minLength: 8)

#if os(macOS)
                    Picker("Home Style", selection: $appearance.homeStyle) {
                        ForEach(HomeStyle.allCases) { style in
                            Text(style.label).tag(style)
                        }
                    }
                    .labelsHidden()
                    .pickerStyle(.menu)
                    .fixedSize()
#endif
                }

#if !os(macOS)
                Picker("Home Style", selection: $appearance.homeStyle) {
                    ForEach(HomeStyle.allCases) { style in
                        Text(style.label).tag(style)
                    }
                }
                .pickerStyle(.segmented)
                .labelsHidden()
#endif
            }
        }
    }

    // MARK: - Accent

    private var accentSection: some View {
        SettingsCard {
            VStack(alignment: .leading, spacing: 14) {
                HStack(spacing: 10) {
                    Image(systemName: "paintpalette")
                        .font(.system(size: 13))
                        .foregroundStyle(Theme.textSecondary)
                        .frame(width: 18)

                    VStack(alignment: .leading, spacing: 2) {
                        Text("Accent")
                            .font(.system(size: 15, weight: .medium))
                            .foregroundStyle(Theme.textPrimary)
                        Text(appearance.accent.label)
                            .font(.system(size: 12))
                            .foregroundStyle(Theme.textTertiary)
                    }

                    Spacer(minLength: 8)
                }

                HStack(spacing: 14) {
                    ForEach(AccentPalette.allCases) { palette in
                        AccentSwatch(
                            palette: palette,
                            isSelected: appearance.accent == palette
                        ) {
                            appearance.accent = palette
                        }
                    }

                    Spacer(minLength: 0)
                }

                Text("Restart the app to apply the new accent.")
                    .font(.system(size: 12))
                    .foregroundStyle(Theme.textTertiary)
            }
        }
    }

    // MARK: - Language

#if os(macOS)
    private var languageSection: some View {
        SettingsCard {
            HStack(spacing: 10) {
                Image(systemName: "globe")
                    .font(.system(size: 13))
                    .foregroundStyle(Theme.textSecondary)
                    .frame(width: 18)

                VStack(alignment: .leading, spacing: 2) {
                    Text("Language")
                        .font(.system(size: 15, weight: .medium))
                        .foregroundStyle(Theme.textPrimary)
                    Text("System follows your Mac's language.")
                        .font(.system(size: 12))
                        .foregroundStyle(Theme.textTertiary)
                }

                Spacer(minLength: 8)

                Picker("Language", selection: $language.language) {
                    ForEach(AppLanguage.allCases) { lang in
                        Text(lang.label).tag(lang)
                    }
                }
                .labelsHidden()
                .pickerStyle(.menu)
                .fixedSize()
            }
        }
    }
#endif

    // MARK: - Audio

    private var audioSection: some View {
        SettingsCard {
            VStack(spacing: 20) {
                SettingsSlider(
                    title: Text("Global Volume"),
                    subtitle: Text("Scales every sound in the mix."),
                    icon: globalVolumeIcon,
                    value: $mixer.masterVolume
                )

                Divider().overlay(Theme.stroke)

                SettingsSlider(
                    title: Text("Alarm Volume"),
                    subtitle: Text("Used by the timers."),
                    icon: alarm.volume < 0.01 ? "bell.slash.fill" : "bell.fill",
                    value: $alarm.volume
                ) {
                    Button {
                        alarm.togglePreview()
                    } label: {
                        Image(systemName: alarm.isPreviewing ? "stop.fill" : "play.fill")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundStyle(Theme.background)
                            .frame(width: 26, height: 26)
                            .background(Circle().fill(Theme.accent))
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel(alarm.isPreviewing ? "Stop alarm preview" : "Preview alarm")
                }

#if os(iOS)
                // Vibration is an iPhone capability; Macs can't vibrate, so the row is
                // hidden there rather than offering a switch that does nothing.
                Divider().overlay(Theme.stroke)

                SettingsToggle(
                    title: Text("Vibration"),
                    subtitle: Text("Vibrate when the alarm sounds."),
                    icon: alarm.vibrationEnabled ? "iphone.gen3.radiowaves.left.and.right" : "iphone.gen3.slash",
                    isOn: $alarm.vibrationEnabled
                )
#endif
            }
        }
    }

    private var globalVolumeIcon: String {
        switch mixer.masterVolume {
        case ..<0.01: "speaker.slash.fill"
        case ..<0.5: "speaker.wave.1.fill"
        default: "speaker.wave.2.fill"
        }
    }

    // MARK: - About
    
    private var logoSection: some View {
        VStack(spacing: 22) {
            VStack(spacing: 14) {
                LogoMark(size: 72)

                VStack(spacing: 6) {
                    Text("Yumibun")
                        .font(.system(size: 28, design: .serif))
                        .foregroundStyle(Theme.textPrimary)

                    Text("Focus, relax & sleep\nYume (夢, dream) + Kibun (気分, mood) → Yumibun")
                        .font(.system(size: 14))
                        .foregroundStyle(Theme.textSecondary)
                        .multilineTextAlignment(.center)
                        .lineSpacing(2)
                }
            }
            .padding(.top, 4)
        }
    }

    private var aboutSection: some View {
        VStack(spacing: 22) {
            VStack(spacing: 4) {
                Text("Free and Open Source")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(Theme.textSecondary)

                Text(About.versionLine)
                    .font(.system(size: 12))
                    .foregroundStyle(Theme.textTertiary)
                    .accessibilityLabel(About.versionAccessibilityLabel)
            }

            SettingsCard(padding: 4) {
                VStack(spacing: 0) {
                    LinkRow(
                        title: "Toepper.Rocks",
                        icon: .symbol("globe"),
                        url: About.websiteToepperURL
                    )

                    Divider().overlay(Theme.stroke)

                    LinkRow(
                        title: "akandor/yumibun",
                        icon: .asset("github"),
                        url: About.repositoryToepperURL
                    )
                }
            }
        }
    }
}

// MARK: - About

private var aboutTeopperSection: some View {
    VStack(spacing: 22) {
        VStack(spacing: 4) {
            Text("Yumibun is based on the Open-Source project Moodist")
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(Theme.textSecondary)
        }

        SettingsCard(padding: 4) {
            VStack(spacing: 0) {
                LinkRow(
                    title: "moodist.mvze.net",
                    icon: .symbol("globe"),
                    url: About.websiteURL
                )

                Divider().overlay(Theme.stroke)

                LinkRow(
                    title: "remvze/moodist",
                    icon: .asset("github"),
                    url: About.repositoryURL
                )
            }
        }
    }
}

private var licenseSection: some View {
    VStack(spacing: 22) {
        VStack(spacing: 4) {
            Text("License")
                .font(.system(size: 16, weight: .medium))
                .foregroundStyle(Theme.textSecondary)
            
            Text("Moodist and Yumibun are licensed under the MIT License")
                .font(.system(size: 14))
                .foregroundStyle(Theme.textSecondary)
                .multilineTextAlignment(.center)
                .lineSpacing(2)
        }
        
        SettingsCard(padding: 4) {
            VStack(spacing: 0) {
                LinkRow(
                    title: "Moodist License",
                    icon: .symbol("book.pages.fill"),
                    url: About.moodistLicenseURL
                )

                Divider().overlay(Theme.stroke)

                LinkRow(
                    title: "Yumibun License",
                    icon: .symbol("book.pages.fill"),
                    url: About.moodistiOSLicenseURL
                )
            }
        }
        
        VStack(spacing: 4) {
            Text("Some sounds used in this project are sourced from third-party providers and are subject to different licenses:")
                .font(.system(size: 14))
                .foregroundStyle(Theme.textSecondary)
                .multilineTextAlignment(.center)
                .lineSpacing(2)
        }
        
        SettingsCard(padding: 4) {
            VStack(spacing: 0) {
                LinkRow(
                    title: "Pixabay Content License",
                    icon: .symbol("book.pages.fill"),
                    url: About.pixabayLicenseURL
                )

                Divider().overlay(Theme.stroke)

                LinkRow(
                    title: "Creative Commons Zero License",
                    icon: .symbol("book.pages.fill"),
                    url: About.cc0LicenseURL
                )
            }
        }
    }
}

private var artworkSection: some View {
    VStack(spacing: 22) {
        VStack(spacing: 4) {
            Text("Artwork")
                .font(.system(size: 16, weight: .medium))
                .foregroundStyle(Theme.textSecondary)

            Text("Category artwork is sourced from Wikimedia Commons and dedicated to the public domain (CC0).")
                .font(.system(size: 14))
                .foregroundStyle(Theme.textSecondary)
                .multilineTextAlignment(.center)
                .lineSpacing(2)
        }

        SettingsCard(padding: 4) {
            VStack(spacing: 0) {
                ForEach(Array(About.artworkCredits.enumerated()), id: \.element.category) { index, credit in
                    if index > 0 {
                        Divider().overlay(Theme.stroke)
                    }

                    LinkRow(
                        title: credit.category,
                        icon: .symbol("photo.fill"),
                        url: credit.url
                    )
                }
            }
        }
    }
}

// MARK: - About metadata

enum About {
    static let websiteURL = URL(string: "https://moodist.mvze.net/")!
    static let repositoryURL = URL(string: "https://github.com/remvze/moodist")!
    
    static let websiteToepperURL = URL(string: "https://toepper.rocks")!
    static let repositoryToepperURL = URL(string: "https://github.com/akandor/yumibun")!
    
    static let moodistLicenseURL = URL(string: "https://github.com/remvze/moodist/blob/main/LICENSE")!
    static let moodistiOSLicenseURL = URL(string: "https://github.com/akandor/yumibun/blob/main/LICENSE")!
    static let pixabayLicenseURL = URL(string: "https://pixabay.com/service/license-summary/")!
    static let cc0LicenseURL = URL(string: "https://creativecommons.org/publicdomain/zero/1.0/")!

    /// Category hero images, all CC0 from Wikimedia Commons. Mirrors ATTRIBUTION.md.
    struct ArtworkCredit {
        let category: String
        let url: URL
    }

    static let artworkCredits: [ArtworkCredit] = [
        credit("Nature", "File:Creek_in_the_dark_forest_(Unsplash).jpg"),
        credit("Rain", "File:Foggy_glass_unsplash_2.jpg"),
        credit("Animals", "File:Deer,_Watching_(Unsplash).jpg"),
        credit("Urban", "File:Cityscape_and_traffic_light_trails_(Unsplash).jpg"),
        credit("Places", "File:Empty_coffee_shop_interior_with_wooden_table_and_water_skis.jpg"),
        credit("Transport", "File:Outdoor_train_railway_(Unsplash).jpg"),
        credit("Things", "File:Typewriter_(Unsplash).jpg"),
        credit("Noise", "File:Fog_covered_mountain_forest_(Unsplash).jpg"),
    ]

    private static func credit(_ category: String, _ file: String) -> ArtworkCredit {
        let base = "https://commons.wikimedia.org/wiki/"
        let encoded = file.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? file
        return ArtworkCredit(category: category, url: URL(string: base + encoded)!)
    }

    /// Reads the values Xcode generates from MARKETING_VERSION / CURRENT_PROJECT_VERSION.
    static var versionLine: String {
        "Version \(shortVersion) (\(build))"
    }

    static var versionAccessibilityLabel: String {
        "Version \(shortVersion), build \(build)"
    }

    private static var shortVersion: String {
        Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "—"
    }

    private static var build: String {
        Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? "—"
    }
}

// MARK: - Building blocks

private struct SettingsCard<Content: View>: View {
    var padding: CGFloat = 16
    @ViewBuilder var content: Content

    var body: some View {
        content
            .padding(padding)
            .frame(maxWidth: .infinity)
            .background(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(Theme.surface)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .strokeBorder(Theme.stroke, lineWidth: 1)
            )
    }
}

private struct SettingsSlider<Accessory: View>: View {
    let title: Text
    let subtitle: Text
    let icon: String
    @Binding var value: Double
    @ViewBuilder var accessory: Accessory

    init(
        title: Text,
        subtitle: Text,
        icon: String,
        value: Binding<Double>,
        @ViewBuilder accessory: () -> Accessory = { EmptyView() }
    ) {
        self.title = title
        self.subtitle = subtitle
        self.icon = icon
        self._value = value
        self.accessory = accessory()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 8) {
                VStack(alignment: .leading, spacing: 2) {
                    title
                        .font(.system(size: 15, weight: .medium))
                        .foregroundStyle(Theme.textPrimary)
                    subtitle
                        .font(.system(size: 12))
                        .foregroundStyle(Theme.textTertiary)
                }

                Spacer(minLength: 8)

                Text("\(Int((value * 100).rounded()))%")
                    .font(.system(size: 12, weight: .medium).monospacedDigit())
                    .foregroundStyle(Theme.textSecondary)

                accessory
            }

            HStack(spacing: 10) {
                Image(systemName: icon)
                    .font(.system(size: 13))
                    .foregroundStyle(Theme.textSecondary)
                    .frame(width: 18)
                    .contentTransition(.symbolEffect(.replace))

                MusicSlider(value: $value)
                    .accessibilityLabel(title)
            }
        }
    }
}

private struct SettingsToggle: View {
    let title: Text
    let subtitle: Text
    let icon: String
    @Binding var isOn: Bool

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .font(.system(size: 13))
                .foregroundStyle(Theme.textSecondary)
                .frame(width: 18)
                .contentTransition(.symbolEffect(.replace))

            VStack(alignment: .leading, spacing: 2) {
                title
                    .font(.system(size: 15, weight: .medium))
                    .foregroundStyle(Theme.textPrimary)
                subtitle
                    .font(.system(size: 12))
                    .foregroundStyle(Theme.textTertiary)
            }

            Spacer(minLength: 8)

            Toggle("", isOn: $isOn)
                .labelsHidden()
                .tint(Theme.accent)
                .accessibilityLabel(title)
        }
    }
}

/// A tappable accent color, shown as a filled circle that grows a ring when it's the
/// selected palette. `Pure` reads as a monochrome swatch (black on light, white on dark).
private struct AccentSwatch: View {
    let palette: AccentPalette
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Circle()
                .fill(palette.color)
                .frame(width: 30, height: 30)
                .overlay(
                    Circle().strokeBorder(Theme.stroke, lineWidth: 1)
                )
                .overlay(
                    Circle()
                        .strokeBorder(Theme.textPrimary, lineWidth: 2)
                        .padding(-4)
                        .opacity(isSelected ? 1 : 0)
                )
                .animation(.snappy(duration: 0.15), value: isSelected)
                .contentShape(Circle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(Text(palette.label))
        .accessibilityAddTraits(isSelected ? [.isSelected] : [])
    }
}

/// A link row's icon is either an SF Symbol or a bundled template asset — the
/// GitHub mark has no SF Symbol equivalent.
private enum RowIcon {
    case symbol(String)
    case asset(String)
}

/// Centred to sit under the centred about column, and kept to a single line —
/// the URLs already say "website" and "source code".
private struct LinkRow: View {
    let title: String
    let icon: RowIcon
    let url: URL

    var body: some View {
        Link(destination: url) {
            HStack(spacing: 8) {
                iconView
                    .frame(width: 15, height: 15)
                    .foregroundStyle(Theme.textSecondary)

                Text(title)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(Theme.textPrimary)

                Image(systemName: "arrow.up.right")
                    .font(.system(size: 9, weight: .semibold))
                    .foregroundStyle(Theme.textTertiary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .contentShape(Rectangle())
        }
        .accessibilityHint("Opens in your browser")
    }

    @ViewBuilder
    private var iconView: some View {
        switch icon {
        case let .symbol(name):
            Image(systemName: name)
                .font(.system(size: 17))
        case let .asset(name):
            Image(name)
                .renderingMode(.template)
                .resizable()
                .scaledToFit()
        }
    }
}

#Preview {
    SettingsView()
        .environmentObject(SoundMixer())
        .environmentObject(AppearanceSettings())
        .environmentObject(AlarmSettings())
        .environmentObject(LanguageSettings())
}
