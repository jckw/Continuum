//
//  NotificationManager.swift
//  Continuum
//
//  Created by Claude on 29/12/2024.
//

import Foundation
import UserNotifications

struct NotificationSettings: Codable {
  var enabled: Bool = false
  var thresholds: Set<Int> = []

  static let availableThresholds = [90, 75, 50, 25, 10]
}

@MainActor
class NotificationManager: ObservableObject {
  static let shared = NotificationManager()

  @Published var settings: NotificationSettings {
    didSet {
      saveSettings()
      Task {
        await rescheduleNotifications()
      }
    }
  }

  private let sharedUserDefaults = UserDefaults(suiteName: "group.systems.weekend.continuum")!

  private init() {
    if let data = sharedUserDefaults.data(forKey: "notificationSettings"),
      let decoded = try? JSONDecoder().decode(NotificationSettings.self, from: data)
    {
      settings = decoded
    } else {
      settings = NotificationSettings()
    }
  }

  private func saveSettings() {
    if let encoded = try? JSONEncoder().encode(settings) {
      sharedUserDefaults.set(encoded, forKey: "notificationSettings")
    }
  }

  func requestPermission() async -> Bool {
    let center = UNUserNotificationCenter.current()
    do {
      let granted = try await center.requestAuthorization(options: [.alert, .sound])
      return granted
    } catch {
      return false
    }
  }

  func rescheduleNotifications() async {
    let center = UNUserNotificationCenter.current()
    center.removeAllPendingNotificationRequests()

    guard settings.enabled, !settings.thresholds.isEmpty else { return }

    let startTimeStr = sharedUserDefaults.string(forKey: "startTimeStr") ?? "09:00"
    let endTimeStr = sharedUserDefaults.string(forKey: "endTimeStr") ?? "23:00"

    guard let wakingMinutes = DateStrings.clockwiseDistance(from: startTimeStr, to: endTimeStr),
      wakingMinutes > 0
    else { return }

    let now = Date()

    for threshold in settings.thresholds.sorted(by: >) {
      let percentElapsed = 100 - threshold
      let minutesFromStart = Int(Double(wakingMinutes) * Double(percentElapsed) / 100.0)

      let notificationTime = calculateNotificationTime(
        startTimeStr: startTimeStr,
        minutesFromStart: minutesFromStart,
        from: now
      )

      guard notificationTime > now else { continue }

      let content = UNMutableNotificationContent()
      content.title = "Continuum"
      content.body = "\(threshold)% of your day remaining"
      content.sound = .default

      let components = Calendar.current.dateComponents(
        [.year, .month, .day, .hour, .minute],
        from: notificationTime
      )
      let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)

      let request = UNNotificationRequest(
        identifier: "continuum-\(threshold)-\(components.day ?? 0)",
        content: content,
        trigger: trigger
      )

      try? await center.add(request)
    }
  }

  private func calculateNotificationTime(
    startTimeStr: String,
    minutesFromStart: Int,
    from baseDate: Date
  ) -> Date {
    let startDate = DateStrings.relativeDate(time: startTimeStr, direction: .next, from: baseDate)
    return Calendar.current.date(byAdding: .minute, value: minutesFromStart, to: startDate)
      ?? baseDate
  }
}
