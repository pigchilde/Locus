import SwiftUI

enum LocusDesign {
    static let panelWidth: CGFloat = 368
    static let panelHeight: CGFloat = 580
    static let pagePadding: CGFloat = 14
    static let sectionSpacing: CGFloat = 16
    static let headerHeight: CGFloat = 58
    static let brandMarkSize: CGFloat = 32
    static let standardRowHeight: CGFloat = 43
    static let detailedRowHeight: CGFloat = 52
    static let bottomBarHeight: CGFloat = 52
    static let cardRadius: CGFloat = 11
    static let buttonRadius: CGFloat = 7

    static func surface(_ scheme: ColorScheme) -> Color {
        scheme == .dark ? Color.white.opacity(0.055) : Color.white.opacity(0.72)
    }
}

/// A menu-bar panel may be visible without becoming the key window. Keep the
/// track tied to the binding instead of AppKit's inactive-window tint, while
/// exposing the standard Toggle to VoiceOver and keyboard users.
struct LocusSwitchStyle: ToggleStyle {
    @Environment(\.isEnabled) private var isEnabled
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.colorScheme) private var colorScheme

    func makeBody(configuration: Configuration) -> some View {
        Button {
            configuration.isOn.toggle()
        } label: {
            Capsule()
                .fill(configuration.isOn ? Color.blue : Color.secondary.opacity(0.28))
                .overlay {
                    Circle()
                        .fill(.white)
                        .frame(width: 14, height: 14)
                        .shadow(color: .black.opacity(0.12), radius: 1, y: 0.5)
                        .offset(x: configuration.isOn ? 6 : -6)
                }
                .overlay {
                    Capsule().strokeBorder(.primary.opacity(colorScheme == .dark ? 0.1 : 0.04), lineWidth: 0.5)
                }
                .frame(width: 30, height: 18)
                .padding(.vertical, 5)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .opacity(isEnabled ? 1 : 0.4)
        .animation(reduceMotion ? nil : .easeOut(duration: 0.14), value: configuration.isOn)
        .accessibilityRepresentation {
            Toggle(isOn: Binding(
                get: { configuration.isOn },
                set: { configuration.isOn = $0 }
            )) {
                configuration.label
            }
            .toggleStyle(.switch)
        }
    }
}

struct LocusPanelBackground: View {
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        ZStack {
            (colorScheme == .dark
                ? Color(red: 0.157, green: 0.176, blue: 0.20)
                : Color(red: 0.937, green: 0.953, blue: 0.957))
            Rectangle().fill(.regularMaterial).opacity(0.12)
        }
        .ignoresSafeArea()
    }
}

struct MenuBarHeader<Trailing: View>: View {
    let title: String
    let onBack: (() -> Void)?
    @ViewBuilder let trailing: Trailing

    init(title: String, onBack: (() -> Void)? = nil, @ViewBuilder trailing: () -> Trailing) {
        self.title = title
        self.onBack = onBack
        self.trailing = trailing()
    }

    var body: some View {
        HStack(spacing: 8) {
            if let onBack {
                Button(action: onBack) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 13, weight: .medium))
                        .frame(width: 22, height: 28)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .foregroundStyle(.secondary)
                .accessibilityLabel("返回")
            }
            Text(title)
                .font(.system(size: 14, weight: .semibold))
                .lineLimit(1)
                .help(title)
            Spacer(minLength: 8)
            trailing
        }
        .frame(height: LocusDesign.headerHeight)
        .padding(.horizontal, LocusDesign.pagePadding)
    }
}

extension MenuBarHeader where Trailing == EmptyView {
    init(title: String, onBack: (() -> Void)? = nil) {
        self.init(title: title, onBack: onBack) { EmptyView() }
    }
}

struct MenuBarSection<Content: View>: View {
    let title: String
    @ViewBuilder let content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 7) {
            Text(title)
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(.secondary)
                .padding(.horizontal, 4)
            content
        }
    }
}

struct LocusCard<Content: View>: View {
    @Environment(\.colorScheme) private var colorScheme
    @ViewBuilder let content: Content

    var body: some View {
        content
            .padding(.horizontal, 12)
            .background(LocusDesign.surface(colorScheme), in: RoundedRectangle(cornerRadius: LocusDesign.cardRadius))
            .overlay {
                RoundedRectangle(cornerRadius: LocusDesign.cardRadius)
                    .strokeBorder(colorScheme == .dark ? Color.white.opacity(0.025) : Color.black.opacity(0.015), lineWidth: 0.5)
                    .allowsHitTesting(false)
            }
    }
}

/// Secondary symbols stay unboxed; only the current network has an accent disc.
struct LocusIconTile: View {
    let symbol: String
    var color: Color = .secondary
    var size: CGFloat = 20

    var body: some View {
        Image(systemName: symbol)
            .font(.system(size: 14, weight: .regular))
            .foregroundStyle(color)
            .frame(width: size, height: size)
            .accessibilityHidden(true)
    }
}

struct MenuBarRow<Trailing: View>: View {
    let title: String
    let subtitle: String?
    let icon: String?
    let iconColor: Color
    @ViewBuilder let trailing: Trailing

    init(title: String, subtitle: String? = nil, icon: String? = nil, iconColor: Color = .secondary, @ViewBuilder trailing: () -> Trailing) {
        self.title = title
        self.subtitle = subtitle
        self.icon = icon
        self.iconColor = iconColor
        self.trailing = trailing()
    }

    var body: some View {
        HStack(spacing: 9) {
            if let icon { LocusIconTile(symbol: icon, color: iconColor) }
            VStack(alignment: .leading, spacing: 3) {
                Text(title).font(.system(size: 12, weight: .medium)).lineLimit(1)
                if let subtitle {
                    Text(subtitle)
                        .font(.system(size: 10))
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            Spacer(minLength: 8)
            trailing
        }
        .frame(minHeight: subtitle == nil ? LocusDesign.standardRowHeight : LocusDesign.detailedRowHeight)
        .contentShape(Rectangle())
    }
}

/// The same native menu treatment is shared by rule and settings forms.
struct LocusMenuPickerStyle: ViewModifier {
    func body(content: Content) -> some View {
        content
            .labelsHidden()
            .pickerStyle(.menu)
            .controlSize(.small)
            .font(.system(size: 11))
            .tint(.primary)
            .frame(maxWidth: 174)
    }
}

struct LocusVolumeEditor: View {
    @Binding var value: Double
    var onEditingChanged: (Bool) -> Void = { _ in }

    var body: some View {
        VStack(spacing: 8) {
            HStack {
                Text("目标音量").font(.system(size: 12, weight: .medium))
                Spacer()
                Text(value, format: .percent.precision(.fractionLength(0)))
                    .font(.system(size: 11))
                    .monospacedDigit()
                    .foregroundStyle(.secondary)
            }
            HStack(spacing: 9) {
                Image(systemName: "speaker.fill")
                Slider(value: $value, in: 0...1, onEditingChanged: onEditingChanged)
                    .controlSize(.small)
                    .accessibilityLabel("目标音量")
                Image(systemName: "speaker.wave.2.fill")
            }
            .font(.system(size: 10))
            .foregroundStyle(.secondary)
        }
        .padding(.vertical, 12)
    }
}

struct LocusPrimaryButtonStyle: ButtonStyle {
    @Environment(\.isEnabled) private var isEnabled

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 12, weight: .medium))
            .foregroundStyle(.white)
            .padding(.horizontal, 13)
            .frame(height: 30)
            .background(Color.accentColor, in: RoundedRectangle(cornerRadius: LocusDesign.buttonRadius))
            .opacity(isEnabled ? (configuration.isPressed ? 0.72 : 1) : 0.35)
    }
}

typealias LocusAccentButtonStyle = LocusPrimaryButtonStyle

struct LocusSecondaryButtonStyle: ButtonStyle {
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.isEnabled) private var isEnabled

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 11, weight: .medium))
            .foregroundStyle(.primary)
            .padding(.horizontal, 11)
            .frame(height: 28)
            .background(LocusDesign.surface(colorScheme), in: RoundedRectangle(cornerRadius: LocusDesign.buttonRadius))
            .overlay {
                RoundedRectangle(cornerRadius: LocusDesign.buttonRadius)
                    .strokeBorder(.primary.opacity(0.1), lineWidth: 0.5)
            }
            .opacity(isEnabled ? (configuration.isPressed ? 0.7 : 1) : 0.35)
    }
}

struct LocusDangerButtonStyle: ButtonStyle {
    @Environment(\.isEnabled) private var isEnabled

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 11, weight: .medium))
            .foregroundStyle(.red)
            .padding(.horizontal, 11)
            .frame(height: 30)
            .background(Color.red.opacity(configuration.isPressed ? 0.12 : 0.065), in: RoundedRectangle(cornerRadius: LocusDesign.buttonRadius))
            .opacity(isEnabled ? 1 : 0.35)
    }
}

struct LocusRowButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View { RowButtonBody(configuration: configuration) }

    private struct RowButtonBody: View {
        let configuration: Configuration
        @State private var isHovered = false

        var body: some View {
            configuration.label
                .background(.primary.opacity(isHovered ? 0.035 : 0), in: RoundedRectangle(cornerRadius: 5))
                .opacity(configuration.isPressed ? 0.7 : 1)
                .onHover { isHovered = $0 }
        }
    }
}

func locusRelativeTime(from date: Date, now: Date = Date()) -> String {
    let seconds = max(Int(now.timeIntervalSince(date)), 0)
    if seconds < 60 { return "刚刚" }
    if seconds < 3_600 { return "\(seconds / 60) 分钟前" }
    if seconds < 86_400 { return "\(seconds / 3_600) 小时前" }
    if seconds < 172_800 { return "昨天" }
    return date.formatted(.dateTime.month().day())
}
