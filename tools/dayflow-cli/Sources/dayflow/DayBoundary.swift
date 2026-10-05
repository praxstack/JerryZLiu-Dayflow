//
//  DayBoundary.swift
//  dayflow-cli
//
//  Thin wrappers around DayflowCalendar, the shared 4 AM day / Monday week
//  kernel also compiled into the macOS app.
//

import Foundation
@_exported import DayflowCalendar

let dayKeyFormatter: DateFormatter = {
  DayflowCalendar.dayKeyFormatter(timeZone: Calendar.current.timeZone)
}()

func dayWindow(containing date: Date) -> DayWindow {
  DayflowCalendar.dayWindow(containing: date)
}

func dayWindow(forKey key: String) -> DayWindow? {
  DayflowCalendar.dayWindow(forKey: key)
}

func weekWindow(containing date: Date) -> WeekWindow {
  DayflowCalendar.weekWindow(containing: date)
}

func formatDuration(minutes: Int) -> String {
  let hours = minutes / 60
  let mins = minutes % 60
  if hours == 0 { return "\(mins)m" }
  if mins == 0 { return "\(hours)h" }
  return "\(hours)h \(String(format: "%02d", mins))m"
}
