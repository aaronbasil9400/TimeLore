import Foundation
import Testing
@testable import TimeLore

struct ReminderAttachmentStoreTests {
    @Test func stagedPayloadCommitsToAppOwnedStorageAndCanBeRemoved() throws {
        let rootURL = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString, isDirectory: true)
        defer { try? FileManager.default.removeItem(at: rootURL) }
        let store = ReminderAttachmentStore(rootURL: rootURL)
        let draft = try store.stage(
            data: Data("offline context".utf8),
            kind: .file,
            displayName: "context.txt",
            contentTypeIdentifier: "public.plain-text",
            existingCount: 0,
            existingByteCount: 0
        )

        let attachment = try #require(store.commit([draft]).first)
        #expect(store.payloadURL(for: attachment) != nil)
        #expect(attachment.payloadRelativePath.hasPrefix("Payloads/"))

        store.removePayload(for: attachment)
        #expect(store.payloadURL(for: attachment) == nil)
    }

    @Test func enforcesTheSixAttachmentAndFifteenMegabyteLimits() throws {
        let rootURL = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString, isDirectory: true)
        defer { try? FileManager.default.removeItem(at: rootURL) }
        let store = ReminderAttachmentStore(rootURL: rootURL)

        #expect(throws: ReminderAttachmentStoreError.attachmentLimitReached) {
            try store.stage(
                data: Data([1]),
                kind: .file,
                displayName: "seven.txt",
                contentTypeIdentifier: "public.data",
                existingCount: 6,
                existingByteCount: 0
            )
        }
        #expect(throws: ReminderAttachmentStoreError.totalSizeLimitReached) {
            try store.stage(
                data: Data(repeating: 1, count: 2),
                kind: .file,
                displayName: "over-limit.bin",
                contentTypeIdentifier: "public.data",
                existingCount: 0,
                existingByteCount: ReminderAttachmentStore.maximumTotalByteCount - 1
            )
        }
    }
}
