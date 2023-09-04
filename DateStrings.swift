//
//  DateStrings.swift
//  Continuum
//
//  Created by Jack on 12/06/2023.
//

import Foundation

enum TimeDirection {
  case next
  case previous
}

struct DateStrings {
  static let formatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.dateFormat = "HH:mm"
    return formatter
  }()

  static func string(from date: Date) -> String {
    return formatter.string(from: date)
  }

  static func relativeDate(
    time string: String, direction: TimeDirection, default defaultStringOptional: String? = nil,
    from baseDate: Date? = nil
  ) -> Date {
    let now = baseDate ?? Date()

    let nowComponents = Calendar.current.dateComponents([.hour, .minute], from: now)
    let nowHour = nowComponents.hour!
    let nowMinute = nowComponents.minute!

    let defaultString = defaultStringOptional ?? string
    let dayAgnosticDate = date(from: string, default: defaultString)
    let dayAgnosticDateComponents = Calendar.current.dateComponents(
      [.hour, .minute], from: dayAgnosticDate)

    let hour = dayAgnosticDateComponents.hour!
    let mins = dayAgnosticDateComponents.minute!

    if direction == .next {
      // Get the next date that the clock will read the string
      let nextDate: Date

      if hour > nowHour
        || (hour == nowHour && mins > nowMinute)
      {
        // The time is after now, so we can just use today's date
        nextDate = Calendar.current.date(
          bySettingHour: hour, minute: mins, second: 0, of: now)!
      } else {
        // The time is before now, so we need to use tomorrow's date
        nextDate = Calendar.current.date(
          bySettingHour: hour, minute: mins, second: 0, of: now)!
          .addingTimeInterval(24 * 60 * 60)
      }

      return nextDate
    } else if direction == .previous {
      // Get the previous date that the clock will read the string
      let previousDate: Date

      if hour < nowHour
        || (hour == nowHour && mins < nowMinute)
      {
        // The time is before now, so we can just use today's date
        previousDate = Calendar.current.date(
          bySettingHour: hour, minute: mins, second: 0, of: now)!
      } else {
        // The time is after now, so we need to use yesterday's date
        previousDate = Calendar.current.date(
          bySettingHour: hour, minute: mins, second: 0, of: now)!
          .addingTimeInterval(-24 * 60 * 60)
      }

      return previousDate
    }

    fatalError("Invalid time direction")
  }

  static func date(from string: String) -> Date? {
    return formatter.date(from: string)
  }

  static func date(from string: String?, default defaultString: String) -> Date {
    let dateString = string ?? defaultString
    if let date = formatter.date(from: dateString) {
      return date
    } else if let defaultDate = formatter.date(from: defaultString) {
      return defaultDate
    } else {
      assertionFailure(
        "Both the provided string '\(String(describing: string))' and the default string '\(defaultString)' do not convert to a valid date."
      )
      return Date()
    }
  }

  static func clockwiseDistance(from datedDate1: Date, to datedDate2: Date) -> Int? {
    let date1 = date(from: string(from: datedDate1))!
    let date2 = date(from: string(from: datedDate2))!

    let calendar = Calendar.current
    var components = calendar.dateComponents([.minute], from: date1, to: date2)

    // If time2 is earlier than time1, calculate the time as if the clock were moving forward
    if let minute = components.minute, minute < 0 {
      components = calendar.dateComponents(
        [.minute], from: date1, to: calendar.date(byAdding: .day, value: 1, to: date2)!)
    }

    return components.minute
  }
  static func clockwiseDistance(from time1: String, to time2: String) -> Int? {
    guard let date1 = date(from: time1),
      let date2 = date(from: time2)
    else {
      return nil
    }

    return clockwiseDistance(from: date1, to: date2)
  }
  static func clockwiseDistance(from time1: String, to date2: Date) -> Int? {
    guard let date1 = date(from: time1)
    else {
      return nil
    }

    return clockwiseDistance(from: date1, to: date2)
  }
}

extension Date {
  var zeroSeconds: Date? {
    let calendar = Calendar.current
    let dateComponents = calendar.dateComponents([.year, .month, .day, .hour, .minute], from: self)
    return calendar.date(from: dateComponents)
  }
}
