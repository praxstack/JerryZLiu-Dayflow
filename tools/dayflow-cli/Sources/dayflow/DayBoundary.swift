//
//  DayBoundary.swift
//  dayflow-cli
//
//  Thin wrappers around DayflowCalendar, the shared 4 AM day / Monday week
//  kernel. SwiftPM imports the DayflowCalendar module; the Xcode `dayflow-cli`
//  tool compiles the same kernel sources into this target, so the import is
//  gated on canImport.
//

import Foundation
#if canImport(DayflowCalendar)
@_exported import DayflowCalendar
#endif

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
