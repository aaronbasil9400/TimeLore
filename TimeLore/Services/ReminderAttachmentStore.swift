import Foundation
import SwiftData
import UniformTypeIdentifiers

enum ReminderAttachmentStoreError: LocalizedError, Equatable {
    case attachmentLimitReached
    case totalSizeLimitReached
    case emptyPayload
    case missingPayload
    case importFailed

    var errorDescription: String? {
        switch self {
        case .attachmentLimitReached:
            "A reminder can have up to 6 attachments."
        case .totalSizeLimitReached:
            "Attachments for one reminder can use up to 15 MB in total."
        case .emptyPayload:
            "That attachment did not contain any data."
        case .missingPayload:
            "That attachment is no longer available on this device."
        case .importFailed:
            "Could not import that attachment. Try again or remove it."
        }
    }
}

struct ReminderAttachmentStore {
    static let maximumAttachmentCount = 6
    static let maximumTotalByteCount: Int64 = 15 * 1_024 * 1_024

    private let fileManager: FileManager
    let rootURL: URL

    init(fileManager: FileManager = .default, rootURL: URL? = nil) {
        self.fileManager = fileManager
        self.rootURL = rootURL ?? fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("TimeLore", isDirectory: true)
            .appendingPathComponent("ReminderAttachments", isDirectory: true)
    }

    func stage(
        data: Data,
        kind: ReminderAttachmentKind,
        displayName: String,
        contentTypeIdentifier: String,
        existingCount: Int,
        existingByteCount: Int64
    ) throws -> ReminderAttachmentDraft {
        guard !data.isEmpty else { throw ReminderAttachmentStoreError.emptyPayload }
        guard existingCount < Self.maximumAttachmentCount else { throw ReminderAttachmentStoreError.attachmentLimitReached }
        let byteCount = Int64(data.count)
        guard existingByteCount + byteCount <= Self.maximumTotalByteCount else {
            throw ReminderAttachmentStoreError.totalSizeLimitReached
        }

        try ensureDirectories()
        let id = UUID()
        let fileExtension = resolvedFileExtension(
            contentTypeIdentifier: contentTypeIdentifier,
            displayName: displayName,
            kind: kind
        )
        let relativePath = "Staging/\(id.uuidString)\(fileExtension.map { ".\($0)" } ?? "")"
        let url = rootURL.appendingPathComponent(relativePath)
        do {
            try data.write(to: url, options: .atomic)
        } catch {
            throw ReminderAttachmentStoreError.importFailed
        }
        return ReminderAttachmentDraft(
            id: id,
            kind: kind,
            displayName: displayName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? kind.title : displayName,
            contentTypeIdentifier: contentTypeIdentifier,
            byteCount: byteCount,
            stagingRelativePath: relativePath
        )
    }

    func stage(
        fileAt sourceURL: URL,
        kind: ReminderAttachmentKind = .file,
        displayName: String? = nil,
        contentTypeIdentifier: String,
        existingCount: Int,
        existingByteCount: Int64
    ) throws -> ReminderAttachmentDraft {
        let didAccess = sourceURL.startAccessingSecurityScopedResource()
        defer {
            if didAccess { sourceURL.stopAccessingSecurityScopedResource() }
        }
        guard fileManager.fileExists(atPath: sourceURL.path) else { throw ReminderAttachmentStoreError.missingPayload }
        guard let data = try? Data(contentsOf: sourceURL, options: .mappedIfSafe) else {
            throw ReminderAttachmentStoreError.importFailed
        }
        return try stage(
            data: data,
            kind: kind,
            displayName: displayName ?? sourceURL.lastPathComponent,
            contentTypeIdentifier: contentTypeIdentifier,
            existingCount: existingCount,
            existingByteCount: existingByteCount
        )
    }

    func commit(_ drafts: [ReminderAttachmentDraft]) throws -> [ReminderAttachment] {
        try ensureDirectories()
        var committed: [ReminderAttachment] = []
        do {
            for draft in drafts {
                let sourceURL = rootURL.appendingPathComponent(draft.stagingRelativePath)
                guard fileManager.fileExists(atPath: sourceURL.path) else { throw ReminderAttachmentStoreError.missingPayload }
                let relativePayloadPath = "Payloads/\(sourceURL.lastPathComponent)"
                let destinationURL = rootURL.appendingPathComponent(relativePayloadPath)
                try fileManager.moveItem(at: sourceURL, to: destinationURL)
                committed.append(ReminderAttachment(draft: draft, payloadRelativePath: relativePayloadPath))
            }
            return committed
        } catch let error as ReminderAttachmentStoreError {
            throw error
        } catch {
            throw ReminderAttachmentStoreError.importFailed
        }
    }

    /// Commits payloads and explicitly persists their inverse relationship.
    /// A recurring occurrence owns attachments through its series.
    func commit(
        _ drafts: [ReminderAttachmentDraft],
        attachingTo reminder: Reminder,
        in modelContext: ModelContext
    ) throws -> [ReminderAttachment] {
        let attachments = try commit(drafts)
        for attachment in attachments {
            modelContext.insert(attachment)
            if let series = reminder.recurrenceSeries {
                attachment.series = series
            } else {
                attachment.reminder = reminder
            }
        }
        return attachments
    }

    func discard(_ drafts: [ReminderAttachmentDraft]) {
        for draft in drafts {
            try? fileManager.removeItem(at: rootURL.appendingPathComponent(draft.stagingRelativePath))
        }
    }

    func removePayload(for attachment: ReminderAttachment) {
        try? fileManager.removeItem(at: rootURL.appendingPathComponent(attachment.payloadRelativePath))
    }

    func payloadURL(for attachment: ReminderAttachment) -> URL? {
        let url = rootURL.appendingPathComponent(attachment.payloadRelativePath)
        return fileManager.fileExists(atPath: url.path) ? url : nil
    }

    func stagingURL(for draft: ReminderAttachmentDraft) -> URL? {
        let url = rootURL.appendingPathComponent(draft.stagingRelativePath)
        return fileManager.fileExists(atPath: url.path) ? url : nil
    }

    private func ensureDirectories() throws {
        try fileManager.createDirectory(at: rootURL.appendingPathComponent("Staging", isDirectory: true), withIntermediateDirectories: true)
        try fileManager.createDirectory(at: rootURL.appendingPathComponent("Payloads", isDirectory: true), withIntermediateDirectories: true)
    }

    private func resolvedFileExtension(
        contentTypeIdentifier: String,
        displayName: String,
        kind: ReminderAttachmentKind
    ) -> String? {
        let typeExtension = UTType(contentTypeIdentifier)?.preferredFilenameExtension
        let nameExtension = URL(fileURLWithPath: displayName).pathExtension
        let fallbackExtension: String
        switch kind {
        case .photo: fallbackExtension = "jpg"
        case .file: fallbackExtension = "dat"
        case .contactCard: fallbackExtension = "vcf"
        }
        let candidate = typeExtension ?? (nameExtension.isEmpty ? fallbackExtension : nameExtension)
        return candidate.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
    }
}
