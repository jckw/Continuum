//
//  ScheduleItem.swift
//  Continuum
//

import Foundation

enum ScheduleItemType: String, Codable {
  case timeRange
  case duration
}

struct ScheduleItem: Identifiable, Codable, Equatable {
  var id: UUID
  var name: String
  var type: ScheduleItemType
  var startTimeStr: String?
  var endTimeStr: String?
  var durationMinutes: Int?
  var order: Int
  
  init(id: UUID = UUID(), name: String, type: ScheduleItemType, startTimeStr: String? = nil, endTimeStr: String? = nil, durationMinutes: Int? = nil, order: Int = 0) {
    self.id = id
    self.name = name
    self.type = type
    self.startTimeStr = startTimeStr
    self.endTimeStr = endTimeStr
    self.durationMinutes = durationMinutes
    self.order = order
  }
  
  var totalMinutes: Int {
    switch type {
    case .timeRange:
      guard let start = startTimeStr, let end = endTimeStr else { return 0 }
      return DateStrings.clockwiseDistance(from: start, to: end) ?? 0
    case .duration:
      return durationMinutes ?? 0
    }
  }
  
  func percentageOfWakingHours(wakingMinutes: Int) -> Int {
    guard wakingMinutes > 0 else { return 0 }
    return Int((Double(totalMinutes) / Double(wakingMinutes)) * 100)
  }
  
  var displayTimeInfo: String {
    switch type {
    case .timeRange:
      guard let start = startTimeStr, let end = endTimeStr else { return "" }
      return "\(start) - \(end)"
    case .duration:
      guard let mins = durationMinutes else { return "" }
      let hours = mins / 60
      let minutes = mins % 60
      if hours > 0 && minutes > 0 {
        return "\(hours)h \(minutes)m"
      } else if hours > 0 {
        return "\(hours)h"
      } else {
        return "\(minutes)m"
      }
    }
  }
}

class ScheduleManager: ObservableObject {
  static let shared = ScheduleManager()
  
  private let sharedUserDefaults = UserDefaults(suiteName: "group.systems.weekend.continuum")!
  private let storageKey = "scheduleItems"
  
  @Published var items: [ScheduleItem] = []
  
  init() {
    loadItems()
  }
  
  func loadItems() {
    guard let data = sharedUserDefaults.data(forKey: storageKey),
          let decoded = try? JSONDecoder().decode([ScheduleItem].self, from: data) else {
      items = []
      return
    }
    items = decoded.sorted { $0.order < $1.order }
  }
  
  func saveItems() {
    guard let encoded = try? JSONEncoder().encode(items) else { return }
    sharedUserDefaults.set(encoded, forKey: storageKey)
  }
  
  func addItem(_ item: ScheduleItem) {
    var newItem = item
    newItem.order = (items.map { $0.order }.max() ?? -1) + 1
    items.append(newItem)
    saveItems()
  }
  
  func updateItem(_ item: ScheduleItem) {
    if let index = items.firstIndex(where: { $0.id == item.id }) {
      items[index] = item
      saveItems()
    }
  }
  
  func deleteItem(_ item: ScheduleItem) {
    items.removeAll { $0.id == item.id }
    saveItems()
  }
  
  func moveItem(from source: IndexSet, to destination: Int) {
    items.move(fromOffsets: source, toOffset: destination)
    for (index, _) in items.enumerated() {
      items[index].order = index
    }
    saveItems()
  }
}
