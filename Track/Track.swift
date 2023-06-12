//
//  Track.swift
//  Track
//
//  Created by Jack on 10/06/2023.
//

import Intents
import SwiftUI
import WidgetKit

struct Provider: TimelineProvider {
  let sharedUserDefaults = UserDefaults(suiteName: "group.xyz.jackw.continuum")!

  func placeholder(in context: Context) -> SimpleEntry {
    SimpleEntry(date: Date(), progress: 20, mode: .day)
  }

  static func calculateProgressAndMode(now: Date, startTime: Date, endTime: Date) -> (
    progress: Int, mode: Mode
  ) {
    var endMins =
      Calendar.current.component(.hour, from: endTime) * 60
      + Calendar.current.component(.minute, from: endTime)
    let startMins =
      Calendar.current.component(.hour, from: startTime) * 60
      + Calendar.current.component(.minute, from: startTime)
    var currentMins =
      Calendar.current.component(.hour, from: now) * 60
      + Calendar.current.component(.minute, from: now)

    if endMins < startMins {
      endMins += 24 * 60
    }

    if currentMins < startMins {
      currentMins += 24 * 60
    }

    if currentMins == endMins {
      return (0, .day)
    }

    let progress: Int
    let mode: Mode
    if currentMins > endMins {
      progress = Int(
        (Double(currentMins - endMins) / Double(24 * 60 - (endMins - startMins))) * 100)
      mode = .night
    } else {
      progress = Int((Double(currentMins - startMins) / Double(endMins - startMins)) * 100)
      mode = .day
    }

    return (progress, mode)
  }

  func getStartEndTime() -> (startTime: Date, endTime: Date) {
    let startTimeStr = sharedUserDefaults.string(forKey: "startTimeStr") ?? "09:00"
    let endTimeStr = sharedUserDefaults.string(forKey: "endTimeStr") ?? "23:00"

    let startTime = DateStrings.date(from: startTimeStr)
    let endTime = DateStrings.date(from: endTimeStr)

    return (startTime, endTime)
  }

  func getSnapshot(in context: Context, completion: @escaping (SimpleEntry) -> Void) {
    let (startTime, endTime) = getStartEndTime()
    let currentDate = Date()
    let (progress, mode) = Provider.calculateProgressAndMode(
      now: currentDate, startTime: startTime, endTime: endTime)

    completion(SimpleEntry(date: Date(), progress: progress, mode: mode))
  }

  func getTimeline(in context: Context, completion: @escaping (Timeline<Entry>) -> Void) {
    var entries: [SimpleEntry] = []
    let (startTime, endTime) = getStartEndTime()
    let currentDate = Date()
    for minuteOffset in 0..<1440 {
      let entryDate = Calendar.current.date(
        byAdding: .minute, value: minuteOffset, to: currentDate)!
      let (progress, mode) = Provider.calculateProgressAndMode(
        now: entryDate, startTime: startTime, endTime: endTime)
      let entry = SimpleEntry(date: entryDate, progress: progress, mode: mode)
      entries.append(entry)
    }

    let timeline = Timeline(entries: entries, policy: .atEnd)
    completion(timeline)
  }
}

enum Mode {
  case day
  case night

  var name: String {
    switch self {
    case .day: return "day"
    case .night: return "night"
    }
  }
}

struct SimpleEntry: TimelineEntry {
  let date: Date
  let progress: Int
  let mode: Mode
}

struct TrackEntryView: View {
  var entry: Provider.Entry

  var body: some View {
    VStack {
      HStack {
        Image(systemName: entry.mode == .day ? "sun.min" : "moon").font(.caption2)
        Text(entry.date, style: .time).font(.system(.caption2, design: .rounded).bold())

      }.padding(.leading).padding(.top).frame(maxWidth: .infinity, alignment: .leading)
      Spacer()
      Text("\(entry.progress)%").font(.system(.largeTitle, design: .rounded)).fontWeight(.bold)
      Text("through the \(entry.mode.name)")
      Spacer()
      Text("\( 100 - entry.progress)% remaining").font(Font.system(.caption, design: .rounded))
        .padding(.top, 8).padding(.bottom)
    }.environment(\.font, Font.system(.body, design: .rounded))

  }
}

struct Track: Widget {
  let kind: String = "Track"

  var body: some WidgetConfiguration {
    StaticConfiguration(kind: kind, provider: Provider()) { entry in
      TrackEntryView(entry: entry)
    }
    .configurationDisplayName("Continuum Clock")
    .description("See how much time you have at a glance.")
    .supportedFamilies([.systemSmall])
  }
}

struct Track_Previews: PreviewProvider {
  static var previews: some View {
    let (progress, mode) = Provider.calculateProgressAndMode(
      now: DateStrings.date(from: "17:00"),
      startTime: DateStrings.date(from: "09:00"),
      endTime: DateStrings.date(from: "00:00")
    )
    TrackEntryView(
      entry: SimpleEntry(
        date: DateStrings.date(from: "17:00"), progress: progress, mode: mode)
    )
    .previewContext(WidgetPreviewContext(family: .systemSmall))
  }
}
