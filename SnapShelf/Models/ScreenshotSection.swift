import Foundation

enum ScreenshotSection: String, CaseIterable, Identifiable {
    case today
    case yesterday
    case older

    var id: String { rawValue }

    var title: String {
        switch self {
        case .today:
            return "Today"
        case .yesterday:
            return "Yesterday"
        case .older:
            return "Older"
        }
    }

    static func section(for date: Date, calendar: Calendar = .current) -> Self {
        if calendar.isDateInToday(date) {
            return .today
        }

        if calendar.isDateInYesterday(date) {
            return .yesterday
        }

        return .older
    }
}
