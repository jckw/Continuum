//
//  JournalEntry.swift
//  Continuum
//
//  Created by Claude on 29/12/2024.
//

import Foundation
import SwiftData

@Model
class JournalEntry {
  @Attribute(.unique) var id: UUID
  var date: Date
  var createdAt: Date
  var updatedAt: Date
  var content: String

  init(date: Date, content: String = "") {
    self.id = UUID()
    self.date = date  // Keep exact date/time for multiple entries per day
    self.createdAt = Date()
    self.updatedAt = Date()
    self.content = content
  }

  static func normalizedDate(for date: Date) -> Date {
    Calendar.current.startOfDay(for: date)
  }
  
  var displayTime: String {
    let formatter = DateFormatter()
    formatter.timeStyle = .short
    return formatter.string(from: createdAt)
  }
  
  var preview: String {
    let trimmed = content.trimmingCharacters(in: .whitespacesAndNewlines)
    return trimmed.count > 150 ? String(trimmed.prefix(150)) + "..." : trimmed
  }
}
