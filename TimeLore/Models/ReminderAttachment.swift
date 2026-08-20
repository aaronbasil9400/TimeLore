import Foundation
import SwiftData
import UniformTypeIdentifiers

enum ReminderAttachmentKind: String, Codable, CaseIterable, Sendable {
    case photo
    case file
    case contactCard

    var title: String {
        switch self {
        case .photo: "Photo"
        case .file: "File"
        case .contactCard: "Contact card"
        }
    }

    var symbolName: String {
        switch self {
        case .photo: "photo"
        case .file: "doc"
        case .contactCard: "person.crop.rectangle"
        }
    }
}

struct ReminderAttachmentDraft: Identifiable, Equatable, Sendable {
    let id: UUID
    let kind: ReminderAttachmentKind
    let displayName: String
    let contentTypeIdentifier: String
    let byteCount: Int64
    let stagingRelativePath: String
}

@Model
final class ReminderAttachment {
    @Attribute(.unique) var id: UUID
    var kindRawValue: String
    var displayName: String
    var contentTypeIdentifier: String
    var byteCount: Int64
    /// Relative to the app-owned Application Support attachment directory.
    var payloadRelativePath: String
    var createdAt: Date
    var reminder: Reminder?
    var series: ReminderSeries?

    init(draft: ReminderAttachmentDraft, payloadRelativePath: String, createdAt: Date = .now) {
        id = draft.id
        kindRawValue = draft.kind.rawValue
        displayName = draft.displayName
        contentTypeIdentifier = draft.contentTypeIdentifier
        byteCount = draft.byteCount
        self.payloadRelativePath = payloadRelativePath
        self.createdAt = createdAt
    }

    var kind: ReminderAttachmentKind {
        ReminderAttachmentKind(rawValue: kindRawValue) ?? .file
    }

    var contentType: UTType? {
        UTType(contentTypeIdentifier)
    }
}
