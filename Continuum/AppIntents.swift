//
//  AppIntents.swift
//  Continuum
//
//  Created by Claude on 29/12/2024.
//

import AppIntents
import SwiftData

struct GetTimeRemainingIntent: AppIntent {
  static var title: LocalizedStringResource = "Get Time Remaining"
  static var description = IntentDescription("Returns the percentage of waking day remaining.")

  static var openAppWhenRun: Bool = false

  func perform() async throws -> some IntentResult & ReturnsValue<Int> {
    let sharedUserDefaults = UserDefaults(suiteName: "group.systems.weekend.continuum")!
    let startTimeStr = sharedUserDefaults.string(forKey: "startTimeStr") ?? "09:00"
    let endTimeStr = sharedUserDefaults.string(forKey: "endTimeStr") ?? "23:00"

    let now = Date()
    let startToEndMins = DateStrings.clockwiseDistance(from: startTimeStr, to: endTimeStr) ?? 0
    let startToNowMins = DateStrings.clockwiseDistance(from: startTimeStr, to: now) ?? 0

    let isDay = startToNowMins <= startToEndMins
    if isDay && startToEndMins > 0 {
      let progress = Int((Double(startToNowMins) / Double(startToEndMins)) * 100)
      return .result(value: 100 - progress)
    } else {
      return .result(value: 0)
    }
  }
}

struct GetTodayJournalIntent: AppIntent {
  static var title: LocalizedStringResource = "Get Today's Journal"
  static var description = IntentDescription("Returns today's journal entry text, if any.")

  static var openAppWhenRun: Bool = false

  @MainActor
  func perform() async throws -> some IntentResult & ReturnsValue<String> {
    let container = try ModelContainer(for: JournalEntry.self)
    let context = container.mainContext

    let today = Calendar.current.startOfDay(for: Date())
    let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: today)!

    let predicate = #Predicate<JournalEntry> { entry in
      entry.date >= today && entry.date < tomorrow
    }

    let descriptor = FetchDescriptor<JournalEntry>(predicate: predicate)
    let entries = try context.fetch(descriptor)

    return .result(value: entries.first?.content ?? "")
  }
}

struct ContinuumShortcuts: AppShortcutsProvider {
  static var appShortcuts: [AppShortcut] {
    AppShortcut(
      intent: GetTimeRemainingIntent(),
      phrases: [
        "How much time left in \(.applicationName)",
        "Get time remaining in \(.applicationName)",
        "\(.applicationName) time left"
      ],
      shortTitle: "Time Remaining",
      systemImageName: "clock"
    )
    AppShortcut(
      intent: GetTodayJournalIntent(),
      phrases: [
        "Get today's journal from \(.applicationName)",
        "Read my \(.applicationName) journal"
      ],
      shortTitle: "Today's Journal",
      systemImageName: "book"
    )
  }
}
