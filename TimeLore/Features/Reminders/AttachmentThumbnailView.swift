import QuickLookThumbnailing
import SwiftUI
import UIKit

/// Renders a local attachment thumbnail without requiring network access.
struct AttachmentThumbnailView: View {
    let payloadURL: URL?
    let kind: ReminderAttachmentKind

    @State private var thumbnail: UIImage?

    var body: some View {
        Group {
            if let thumbnail {
                Image(uiImage: thumbnail)
                    .resizable()
                    .scaledToFill()
            } else {
                Image(systemName: kind.symbolName)
                    .font(.title3)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Color(uiColor: .tertiarySystemFill))
            }
        }
        .frame(width: 48, height: 48)
        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
        .accessibilityHidden(true)
        .task(id: payloadURL) {
            await loadThumbnail()
        }
    }

    @MainActor
    private func loadThumbnail() async {
        thumbnail = nil
        guard let payloadURL else { return }

        if kind == .photo, let image = UIImage(contentsOfFile: payloadURL.path) {
            thumbnail = image
            return
        }

        let request = QLThumbnailGenerator.Request(
            fileAt: payloadURL,
            size: CGSize(width: 144, height: 144),
            scale: UIScreen.main.scale,
            representationTypes: .thumbnail
        )
        guard let representation = try? await QLThumbnailGenerator.shared.generateBestRepresentation(for: request),
              !Task.isCancelled else {
            return
        }
        thumbnail = representation.uiImage
    }
}
