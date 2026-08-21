import SwiftUI

struct ReminderTagChip: View {
    enum Style {
        case compact
        case filter
    }

    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.colorSchemeContrast) private var colorSchemeContrast

    let name: String
    var isSelected = false
    var colorToken: ReminderTagColorToken?
    var symbol: String?
    var tint: Color?
    var style: Style = .compact

    init(
        name: String,
        isSelected: Bool = false,
        colorToken: ReminderTagColorToken? = nil,
        symbol: String? = nil,
        tint: Color? = nil,
        style: Style = .compact
    ) {
        self.name = name
        self.isSelected = isSelected
        self.colorToken = colorToken
        self.symbol = symbol
        self.tint = tint
        self.style = style
    }

    init(tag: ReminderTag, isSelected: Bool = false, style: Style = .compact) {
        self.init(
            name: tag.name,
            isSelected: isSelected,
            colorToken: tag.colorToken,
            symbol: tag.resolvedSymbolName,
            style: style
        )
    }

    private var presentation: ReminderTagPresentation {
        ReminderTagPresentation.forTag(named: name)
    }

    private var foreground: Color {
        tint ?? colorToken.map(ReminderTagPresentation.color(for:)) ?? presentation.color
    }

    private var horizontalPadding: CGFloat {
        style == .filter ? 14 : 10
    }

    private var verticalPadding: CGFloat {
        style == .filter ? 9 : 6
    }

    private var unselectedFillOpacity: Double {
        let base = colorScheme == .dark ? 0.24 : 0.12
        return colorSchemeContrast == .increased ? base + 0.08 : base
    }

    var body: some View {
        Label(name, systemImage: symbol ?? presentation.symbol)
            .font(style == .filter ? .subheadline.weight(isSelected ? .semibold : .medium) : .caption.weight(isSelected ? .semibold : .medium))
            .imageScale(style == .filter ? .medium : .small)
            .lineLimit(1)
            .fixedSize(horizontal: true, vertical: false)
            .padding(.horizontal, horizontalPadding)
            .padding(.vertical, verticalPadding)
            .frame(minHeight: style == .filter ? 44 : nil)
            .foregroundStyle(isSelected ? Color.white : foreground)
            .background {
                Capsule()
                    .fill(isSelected ? foreground : foreground.opacity(unselectedFillOpacity))
            }
            .overlay {
                Capsule()
                    .strokeBorder(
                        foreground.opacity(isSelected ? 0 : (colorSchemeContrast == .increased ? 0.5 : 0.18)),
                        lineWidth: 1
                    )
            }
            .contentShape(Capsule())
    }
}
