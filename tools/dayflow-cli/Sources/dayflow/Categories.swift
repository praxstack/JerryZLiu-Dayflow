//
//  Categories.swift
//  dayflow-cli
//
//  Categories live in the app's preferences (the `colorCategories` key in
//  teleportlabs.com.Dayflow). Loading is shared with DayflowCategories in
//  the calendar kernel.
//

#if canImport(DayflowCalendar)
import DayflowCalendar
#endif
import Foundation

struct Category {
  let name: String
  let colorHex: String
  let isSystem: Bool
  let isIdle: Bool
}

func loadCategories() -> [Category] {
  DayflowCategories.load(from: DayflowCategories.defaultsDomain).map {
    Category(name: $0.name, colorHex: $0.colorHex, isSystem: $0.isSystem, isIdle: $0.isIdle)
  }
}
