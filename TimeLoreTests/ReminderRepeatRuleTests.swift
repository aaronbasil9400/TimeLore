import Foundation
import Testing
@testable import TimeLore

struct ReminderRepeatRuleTests {
    private var calendar: Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "America/Los_Angeles")!
        return calendar
    }

    @Test func weeklyRuleKeepsTheChosenWeekdayAndLocalTimeAcrossDaylightSaving() {
        let rule = ReminderRepeatRule(frequency: .weekly, weekday: 1, dayOfMonth: nil, month: nil, hour: 9, minute: 15)
        let beforeDST = calendar.date(from: DateComponents(year: 2026, month: 3, day: 7, hour: 9, minute: 15))!

        let next = rule.nextDate(after: beforeDST, calendar: calendar)
        let components = calendar.dateComponents([.weekday, .hour, .minute], from: next!)

        #expect(components.weekday == 1)
        #expect(components.hour == 9)
        #expect(components.minute == 15)
    }

    @Test func monthlyRuleUsesTheLastDayWhenTheChosenDayDoesNotExist() {
        let rule = ReminderRepeatRule(frequency: .monthly, dayOfMonth: 31, hour: 9, minute: 0)
        let january = calendar.date(from: DateComponents(year: 2027, month: 1, day: 31, hour: 9))!

        let next = rule.nextDate(after: january, calendar: calendar)
        let components = calendar.dateComponents([.year, .month, .day, .hour], from: next!)

        #expect(components.year == 2027)
        #expect(components.month == 2)
        #expect(components.day == 28)
        #expect(components.hour == 9)
    }

    @Test func yearlyRuleUsesTheChosenMonthAndTheDueDateDay() {
        let rule = ReminderRepeatRule(frequency: .yearly, dayOfMonth: 29, month: 2, hour: 8, minute: 30)
        let reference = calendar.date(from: DateComponents(year: 2027, month: 2, day: 28, hour: 8, minute: 30))!

        let next = rule.nextDate(after: reference, calendar: calendar)
        let components = calendar.dateComponents([.year, .month, .day, .hour, .minute], from: next!)

        #expect(components.year == 2028)
        #expect(components.month == 2)
        #expect(components.day == 29)
        #expect(components.hour == 8)
        #expect(components.minute == 30)
    }
}
