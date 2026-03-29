import Foundation

enum ScreenshotDateFilter: String, CaseIterable, Identifiable {
    case all
    case today
    case yesterday
    case thisWeek
    case thisMonth
    case older

    var id: String { rawValue }

    var title: String {
        switch self {
        case .all:
            return "All"
        case .today:
            return "Today"
        case .yesterday:
            return "Yesterday"
        case .thisWeek:
            return "This Week"
        case .thisMonth:
            return "This Month"
        case .older:
            return "Older"
        }
    }

    func matches(_ item: ScreenshotItem, calendar: Calendar = .current) -> Bool {
        switch self {
        case .all:
            return true
        case .today:
            return calendar.isDateInToday(item.createdAt)
        case .yesterday:
            return calendar.isDateInYesterday(item.createdAt)
        case .thisWeek:
            return ScreenshotSection.section(for: item.createdAt, calendar: calendar) == .thisWeek
        case .thisMonth:
            return ScreenshotSection.section(for: item.createdAt, calendar: calendar) == .thisMonth
        case .older:
            return ScreenshotSection.section(for: item.createdAt, calendar: calendar) == .older
        }
    }
}
