//
//  Track.swift
//  Track
//
//  Created by Jack on 10/06/2023.
//

import SwiftUI
import WidgetKit

struct Provider: TimelineProvider {
  let sharedUserDefaults = UserDefaults(suiteName: "G2Q4VASTYV.group.xyz.jackw.continuum")!

  func placeholder(in context: Context) -> SimpleEntry {
    SimpleEntry(date: Date(), startTimeStr: "09:00", endTimeStr: "23:00")
  }

  func getStartEndTimeStr() -> (startTimeStr: String, endTimeStr: String) {
    let startTimeStr = sharedUserDefaults.string(forKey: "startTimeStr") ?? "09:00"
    let endTimeStr = sharedUserDefaults.string(forKey: "endTimeStr") ?? "23:00"

    return (startTimeStr, endTimeStr)
  }

  func getSnapshot(in context: Context, completion: @escaping (SimpleEntry) -> Void) {
    let (startTimeStr, endTimeStr) = getStartEndTimeStr()
    completion(SimpleEntry(date: Date(), startTimeStr: startTimeStr, endTimeStr: endTimeStr))
  }

  func getTimeline(in context: Context, completion: @escaping (Timeline<Entry>) -> Void) {
      print("Timelines are being recalculated...!!!")
    var entries: [SimpleEntry] = []
    let (startTimeStr, endTimeStr) = getStartEndTimeStr()
    let currentDate = Date()

    for minuteOffset in 0..<24 * 60 {
      let entryDate = Calendar.current.date(
        byAdding: .minute, value: minuteOffset, to: currentDate)!
      let entry = SimpleEntry(date: entryDate, startTimeStr: startTimeStr, endTimeStr: endTimeStr)
      entries.append(entry)
    }

    let timeline = Timeline(entries: entries, policy: .atEnd)
      print(entries)
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
  let startTimeStr: String
  let endTimeStr: String
}

struct TrackEntryView: View {
  var entry: Provider.Entry

  func calculateProgressAndMode(now: Date) -> (
    progress: Int, mode: Mode
  ) {
    let (endH, endM) = DateStrings.splitTimeStr(entry.endTimeStr)!
    let (startH, startM) = DateStrings.splitTimeStr(entry.startTimeStr)!
    var endMins = endH * 60 + endM
    let startMins = startH * 60 + startM
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

  var body: some View {
    let (progress, mode) = self.calculateProgressAndMode(now: entry.date)

    VStack {
      HStack {
        Image(systemName: mode == .day ? "sun.min" : "moon").font(.caption2)
        Text(entry.date, style: .time).font(.system(.caption2, design: .rounded).bold())

      }.padding(.leading).padding(.top).frame(maxWidth: .infinity, alignment: .leading)
      Spacer()
      Text("\(progress)%").font(.system(.largeTitle, design: .rounded)).fontWeight(.bold)
      Text("through the \(mode.name)")
      Spacer()
      Text("\( 100 - progress)% remaining").font(Font.system(.caption, design: .rounded))
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
    TrackEntryView(
      entry: SimpleEntry(
        date: Date(),
        startTimeStr: "09:00",
        endTimeStr: "23:30"
      )
    )
    .previewContext(WidgetPreviewContext(family: .systemSmall))
  }
}
