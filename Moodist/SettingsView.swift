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
#if os(macOS)
                        // iOS gets a per-app language switch in the system Settings;
                        // macOS has no equivalent, so the app provides its own.
                        languageSection
#endif
                        audioSection
                        aboutSection
                        aboutTeopperSection
                        licenseSection
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

                Divider().overlay(Theme.stroke)

                SettingsToggle(
                    title: Text("Vibration"),
                    subtitle: Text("Vibrate when the alarm sounds."),
                    icon: alarm.vibrationEnabled ? "iphone.gen3.radiowaves.left.and.right" : "iphone.gen3.slash",
                    isOn: $alarm.vibrationEnabled
                )
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
                    Text("Moodist")
                        .font(.system(size: 28, design: .serif))
                        .foregroundStyle(Theme.textPrimary)

                    Text("Ambient Sounds\nFor Focus and Calm")
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
                        title: "moodist.tpk.pw",
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
}

// MARK: - About

private var aboutTeopperSection: some View {
    VStack(spacing: 22) {
        VStack(spacing: 4) {
            Text("iOS App brought to you by")
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(Theme.textSecondary)
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
                    title: "akandor/moodist_ios",
                    icon: .asset("github"),
                    url: About.repositoryToepperURL
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
            
            Text("Moodist and Moodist iOS App are licensed under the MIT License")
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
                    title: "Moodist iOS License",
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

// MARK: - About metadata

enum About {
    static let websiteURL = URL(string: "https://moodist.tpk.pw")!
    static let repositoryURL = URL(string: "https://github.com/remvze/moodist")!
    
    static let websiteToepperURL = URL(string: "https://toepper.rocks")!
    static let repositoryToepperURL = URL(string: "https://github.com/akandor/moodist_ios")!
    
    static let moodistLicenseURL = URL(string: "https://github.com/remvze/moodist/blob/main/LICENSE")!
    static let moodistiOSLicenseURL = URL(string: "https://github.com/akandor/moodist_ios/blob/main/LICENSE")!
    static let pixabayLicenseURL = URL(string: "https://pixabay.com/service/license-summary/")!
    static let cc0LicenseURL = URL(string: "https://creativecommons.org/publicdomain/zero/1.0/")!

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

                Slider(value: $value, in: 0...1)
                    .tint(Theme.accent)
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
