//
//  DateStrings.swift
//  Continuum
//
//  Created by Jack on 12/06/2023.
//

import Foundation

struct DateStrings {
  static func string(from date: Date) -> String {
    let formatter = DateFormatter()
    formatter.dateFormat = "HH:mm"
    return formatter.string(from: date)
  }

  static func date(from string: String) -> Date {
    let formatter = DateFormatter()
    formatter.dateFormat = "HH:mm"
    return formatter.date(from: string)!
  }
}
