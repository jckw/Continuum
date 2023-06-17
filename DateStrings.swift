//
//  DateStrings.swift
//  Continuum
//
//  Created by Jack on 12/06/2023.
//

import Foundation

struct DateStrings {
  static let formatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.dateFormat = "HH:mm"
    return formatter
  }()

  static func string(from date: Date) -> String {
    return formatter.string(from: date)
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
      fatalError(
        "Both the provided string '\(String(describing: string))' and the default string '\(defaultString)' do not convert to a valid date."
      )
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
