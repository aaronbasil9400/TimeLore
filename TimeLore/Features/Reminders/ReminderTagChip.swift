import SwiftUI

struct ReminderTagChip: View {
    let name: String
    var isSelected = false
    var symbol: String?
    var tint: Color?

    private var presentation: ReminderTagPresentation {
        ReminderTagPresentation.forTag(named: name)
    }

    private var foreground: Color {
        tint ?? presentation.color
    }

    var body: some View {
        Label(name, systemImage: symbol ?? presentation.symbol)
            .font(.caption.weight(isSelected ? .semibold : .medium))
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .foregroundStyle(isSelected ? Color.white : foreground)
            .background(isSelected ? foreground : foreground.opacity(0.14))
            .clipShape(Capsule())
    }
}
