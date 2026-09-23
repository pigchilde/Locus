import SwiftUI

enum LocusDesign {
    static let panelWidth: CGFloat = 368
    static let panelHeight: CGFloat = 580
    static let pagePadding: CGFloat = 18
    static let sectionSpacing: CGFloat = 18
    static let headerHeight: CGFloat = 50
    static let standardRowHeight: CGFloat = 48
    static let detailedRowHeight: CGFloat = 54
    static let bottomBarHeight: CGFloat = 58
    static let cardRadius: CGFloat = 13
    static let iconRadius: CGFloat = 9
    static let buttonRadius: CGFloat = 9
}

struct LocusPanelBackground: View {
    @Environment(\.colorScheme) private var colorScheme
    var body: some View {
        (colorScheme == .dark
            ? Color(nsColor: .windowBackgroundColor)
            : Color(red: 0.965, green: 0.976, blue: 0.988))
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
        HStack(spacing: 7) {
            if let onBack {
                Button(action: onBack) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(.secondary)
                        .frame(width: 30, height: 32)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel("返回")
            }
            Text(title)
                .font(.system(size: onBack == nil ? 17 : 16, weight: .bold))
                .tracking(-0.2)
                .lineLimit(1)
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
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.system(size: 11.5, weight: .semibold))
                .foregroundStyle(.secondary)
            content
        }
    }
}

struct LocusCard<Content: View>: View {
    @ViewBuilder let content: Content
    var body: some View {
        content
            .padding(.horizontal, 11)
            .background(
                RoundedRectangle(cornerRadius: LocusDesign.cardRadius, style: .continuous)
                    .fill(Color(nsColor: .controlBackgroundColor))
                    .shadow(color: Color.black.opacity(0.035), radius: 8, y: 3)
            )
            .overlay(
                RoundedRectangle(cornerRadius: LocusDesign.cardRadius, style: .continuous)
                    .stroke(Color(nsColor: .separatorColor).opacity(0.16), lineWidth: 0.5)
            )
    }
}

struct LocusIconTile: View {
    let symbol: String
    var color: Color = .secondary
    var size: CGFloat = 34
    var body: some View {
        Image(systemName: symbol)
            .font(.system(size: 14, weight: .semibold))
            .foregroundStyle(color)
            .frame(width: size, height: size)
            .background(
                RoundedRectangle(cornerRadius: LocusDesign.iconRadius, style: .continuous)
                    .fill(color.opacity(0.075))
            )
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
        HStack(spacing: 10) {
            if let icon { LocusIconTile(symbol: icon, color: iconColor) }
            VStack(alignment: .leading, spacing: 2) {
                Text(title).font(.system(size: 13, weight: .semibold)).lineLimit(1)
                if let subtitle {
                    Text(subtitle).font(.system(size: 11)).foregroundStyle(.secondary).lineLimit(2)
                }
            }
            Spacer(minLength: 8)
            trailing
        }
        .frame(minHeight: subtitle == nil ? LocusDesign.standardRowHeight : LocusDesign.detailedRowHeight)
        .contentShape(Rectangle())
    }
}

struct LocusPrimaryButtonStyle: ButtonStyle {
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.isEnabled) private var isEnabled
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 12, weight: .semibold))
            .foregroundStyle(colorScheme == .dark ? Color.black : Color.white)
            .padding(.horizontal, 15).frame(height: 32)
            .background(RoundedRectangle(cornerRadius: LocusDesign.buttonRadius).fill(colorScheme == .dark ? Color.white : Color(nsColor: .labelColor)))
            .opacity(isEnabled ? (configuration.isPressed ? 0.78 : 1) : 0.3)
    }
}

struct LocusAccentButtonStyle: ButtonStyle {
    @Environment(\.isEnabled) private var isEnabled
    func makeBody(configuration: Configuration) -> some View {
        configuration.label.font(.system(size: 12, weight: .semibold)).foregroundStyle(.white)
            .padding(.horizontal, 15).frame(height: 32)
            .background(RoundedRectangle(cornerRadius: LocusDesign.buttonRadius).fill(Color.accentColor))
            .opacity(isEnabled ? (configuration.isPressed ? 0.78 : 1) : 0.3)
    }
}

struct LocusSecondaryButtonStyle: ButtonStyle {
    @Environment(\.isEnabled) private var isEnabled
    func makeBody(configuration: Configuration) -> some View {
        configuration.label.font(.system(size: 11.5, weight: .semibold)).foregroundStyle(.primary)
            .padding(.horizontal, 12).frame(height: 30)
            .background(RoundedRectangle(cornerRadius: LocusDesign.buttonRadius).fill(Color(nsColor: .controlBackgroundColor)))
            .overlay(RoundedRectangle(cornerRadius: LocusDesign.buttonRadius).stroke(Color(nsColor: .separatorColor).opacity(0.45), lineWidth: 0.5))
            .opacity(isEnabled ? (configuration.isPressed ? 0.68 : 1) : 0.35)
    }
}

struct LocusDangerButtonStyle: ButtonStyle {
    @Environment(\.isEnabled) private var isEnabled
    func makeBody(configuration: Configuration) -> some View {
        configuration.label.font(.system(size: 11.5, weight: .semibold)).foregroundStyle(.red)
            .padding(.horizontal, 12).frame(height: 32)
            .background(RoundedRectangle(cornerRadius: LocusDesign.buttonRadius).fill(Color.red.opacity(configuration.isPressed ? 0.14 : 0.07)))
            .overlay(RoundedRectangle(cornerRadius: LocusDesign.buttonRadius).stroke(Color.red.opacity(0.22), lineWidth: 0.6))
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
                .background(RoundedRectangle(cornerRadius: 8).fill(Color.accentColor.opacity(isHovered ? 0.055 : 0)))
                .opacity(configuration.isPressed ? 0.82 : 1)
                .onHover { isHovered = $0 }
        }
    }
}

func locusRelativeTime(from date: Date, now: Date = Date()) -> String {
    let seconds = max(Int(now.timeIntervalSince(date)), 0)
    if seconds < 60 { return "0 秒" }
    if seconds < 3_600 {
        let m = seconds / 60, s = seconds % 60
        return s == 0 ? "\(m) 分钟" : "\(m) 分钟 \(s) 秒"
    }
    if seconds < 86_400 {
        let h = seconds / 3_600, m = (seconds % 3_600) / 60
        return m == 0 ? "\(h) 小时" : "\(h) 小时 \(m) 分钟"
    }
    if seconds < 172_800 { return "1 天" }
    return date.formatted(.dateTime.month().day())
}
