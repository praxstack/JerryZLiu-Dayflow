//
//  DayflowCalendar.swift
//  Dayflow
//
//  Single source of truth for Dayflow's 4 AM day and Monday-4 AM week windows.
//  Compiled into the macOS app via the DayflowCalendar PBXFileSystemSynchronizedRootGroup
//  in Dayflow.xcodeproj (path: tools/dayflow-kernel/Sources/DayflowCalendar) and into
//  dayflow-cli via this SwiftPM package.
//

import Foundation

public struct DayWindow: Equatable, Sendable {
  public let dayKey: String
  public let start: Date
  public let end: Date

  public init(dayKey: String, start: Date, end: Date) {
    self.dayKey = dayKey
    self.start = start
    self.end = end
  }
}

public struct WeekWindow: Equatable, Sendable {
  public let start: Date
  public let end: Date

  public init(start: Date, end: Date) {
    self.start = start
    self.end = end
  }
}

public enum DayflowCalendar {
  public static let dayStartHour = 4

  /// Gregorian calendar with Monday as the first weekday, matching
  /// `WeeklyDateRange`'s production calendar.
  public static func mondayGregorian(timeZone: TimeZone = .autoupdatingCurrent) -> Calendar {
    var calendar = Calendar(identifier: .gregorian)
    calendar.timeZone = timeZone
    calendar.firstWeekday = 2
    calendar.minimumDaysInFirstWeek = 4
    return calendar
  }

  public static func dayKeyFormatter(timeZone: TimeZone) -> DateFormatter {
    let formatter = DateFormatter()
    formatter.dateFormat = "yyyy-MM-dd"
    formatter.locale = Locale(identifier: "en_US_POSIX")
    formatter.timeZone = timeZone
    return formatter
  }

  /// The Dayflow day containing `date`. Before 4 AM this resolves to the
  /// previous calendar day.
  public static func dayWindow(containing date: Date, calendar: Calendar = .current) -> DayWindow {
    let formatter = dayKeyFormatter(timeZone: calendar.timeZone)
    guard let fourAMToday = calendar.date(bySettingHour: dayStartHour, minute: 0, second: 0, of: date)
    else {
      let start = calendar.startOfDay(for: date)
      let end = calendar.date(byAdding: .day, value: 1, to: start) ?? start
      return DayWindow(dayKey: formatter.string(from: start), start: start, end: end)
    }

    let startOfDay: Date
    if date < fourAMToday {
      startOfDay = calendar.date(byAdding: .day, value: -1, to: fourAMToday) ?? fourAMToday
    } else {
      startOfDay = fourAMToday
    }
    let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay) ?? startOfDay
    return DayWindow(dayKey: formatter.string(from: startOfDay), start: startOfDay, end: endOfDay)
  }

  /// The Dayflow day for an explicit "YYYY-MM-DD" label. Returns nil for
  /// unparseable input. 4 AM on the named day through 4 AM the next day.
  public static func dayWindow(forKey key: String, calendar: Calendar = .current) -> DayWindow? {
    let formatter = dayKeyFormatter(timeZone: calendar.timeZone)
    guard let dayDate = formatter.date(from: key) else { return nil }
    var startComponents = calendar.dateComponents([.year, .month, .day], from: dayDate)
    startComponents.hour = dayStartHour
    startComponents.minute = 0
    startComponents.second = 0
    guard let start = calendar.date(from: startComponents),
      let end = calendar.date(byAdding: .day, value: 1, to: start)
    else { return nil }
    return DayWindow(dayKey: key, start: start, end: end)
  }

  /// The Dayflow week containing `date`. Weeks run Monday 4 AM to Monday 4 AM.
  /// Defaults to the app's Monday-first Gregorian calendar so CLI queries match
  /// the weekly UI rather than `Calendar.current`'s locale weekday.
  public static func weekWindow(containing date: Date, calendar: Calendar? = nil) -> WeekWindow {
    let calendar = calendar ?? mondayGregorian(timeZone: .autoupdatingCurrent)
    let baseWeekStart =
      calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: date))
      ?? date
    let mondayAtFourAM =
      calendar.date(bySettingHour: dayStartHour, minute: 0, second: 0, of: baseWeekStart)
      ?? baseWeekStart

    let start: Date
    if date < mondayAtFourAM {
      start = calendar.date(byAdding: .day, value: -7, to: mondayAtFourAM) ?? mondayAtFourAM
    } else {
      start = mondayAtFourAM
    }
    let end = calendar.date(byAdding: .day, value: 7, to: start) ?? start
    return WeekWindow(start: start, end: end)
  }
}

public struct DayflowCategoryRecord: Equatable, Sendable {
  public let name: String
  public let colorHex: String
  public let isSystem: Bool
  public let isIdle: Bool

  public init(name: String, colorHex: String, isSystem: Bool, isIdle: Bool) {
    self.name = name
    self.colorHex = colorHex
    self.isSystem = isSystem
    self.isIdle = isIdle
  }
}

public enum DayflowCategories {
  public static let defaultsDomain = "teleportlabs.com.Dayflow"
  public static let storageKey = "colorCategories"

  /// Matches CategoryPersistence.defaultCategories names/colors used by the CLI.
  public static let defaultCategories: [DayflowCategoryRecord] = [
    DayflowCategoryRecord(name: "Work", colorHex: "#B984FF", isSystem: false, isIdle: false),
    DayflowCategoryRecord(name: "Personal", colorHex: "#6AADFF", isSystem: false, isIdle: false),
    DayflowCategoryRecord(
      name: "Distraction", colorHex: "#FF5950", isSystem: false, isIdle: false),
    DayflowCategoryRecord(name: "Idle", colorHex: "#A0AEC0", isSystem: true, isIdle: true),
  ]

  public static func load(from data: Data?) -> [DayflowCategoryRecord] {
    struct StoredCategory: Decodable {
      let name: String
      let colorHex: String
      let order: Int?
      let isSystem: Bool?
      let isIdle: Bool?
    }

    guard let data,
      let stored = try? JSONDecoder().decode([StoredCategory].self, from: data),
      !stored.isEmpty
    else { return defaultCategories }

    return stored
      .sorted { ($0.order ?? 0) < ($1.order ?? 0) }
      .map {
        DayflowCategoryRecord(
          name: $0.name,
          colorHex: $0.colorHex,
          isSystem: $0.isSystem ?? false,
          isIdle: $0.isIdle ?? false
        )
      }
  }

  public static func load(from defaultsDomain: String = defaultsDomain) -> [DayflowCategoryRecord] {
    let data = UserDefaults(suiteName: defaultsDomain)?.data(forKey: storageKey)
    return load(from: data)
  }
}
