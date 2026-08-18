import SwiftUI

struct ReminderTagChip: View {
    let name: String
    var isSelected = false

    var body: some View {
        Text(name)
            .font(.caption.weight(.medium))
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .foregroundStyle(isSelected ? Color.white : Color.accentColor)
            .background(isSelected ? Color.accentColor : Color.accentColor.opacity(0.12))
            .clipShape(Capsule())
    }
}
