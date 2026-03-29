import Foundation

enum ScreenshotDateFilter: String, CaseIterable, Identifiable {
    case all
    case today
    case yesterday
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
        case .older:
            return ScreenshotSection.section(for: item.createdAt, calendar: calendar) == .older
        }
    }
}
