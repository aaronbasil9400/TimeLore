import Testing
@testable import Breadcrumb

struct ReminderTagTests {
    @Test func trimsAndNormalizesNames() {
        let tag = ReminderTag(name: "  WORK \n")

        #expect(tag.name == "WORK")
        #expect(tag.normalizedName == "work")
    }

    @Test func equivalentNamesHaveTheSameNormalizedValue() {
        #expect(ReminderTag.normalizedName(from: "Work") == ReminderTag.normalizedName(from: " work "))
    }

    @Test func rejectsBlankAndLongNames() {
        #expect(ReminderTag.validationError(for: " \n") == "Enter a tag name.")
        #expect(ReminderTag.validationError(for: String(repeating: "a", count: 31)) != nil)
    }
}
