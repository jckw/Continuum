//
//  Widget.swift
//  Widget
//
//  Created by Jack on 10/06/2023.
//

import SwiftUI
import WidgetKit

struct Provider: TimelineProvider {
  let sharedUserDefaults = UserDefaults(suiteName: "group.G2Q4VASTYV.xyz.jackw.continuum")!

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
    var entries: [SimpleEntry] = []
    let (startTimeStr, endTimeStr) = getStartEndTimeStr()
    let currentDate = Date()

    // TODO: Consider only rendering % increases
    // Watch out here: increasing the number of entries rendered can cause the widget to exceed 30MB memory and crash it
    for minuteOffset in 0..<6 * 60 {
      let entryDate = Calendar.current.date(
        byAdding: .minute, value: minuteOffset, to: currentDate)!.zeroSeconds!
      let entry = SimpleEntry(date: entryDate, startTimeStr: startTimeStr, endTimeStr: endTimeStr)
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
  let startTimeStr: String
  let endTimeStr: String
}

struct WidgetEntryView: View {
  var entry: Provider.Entry

  func calculateProgressAndMode(now: Date) -> (
    progress: Int, mode: Mode
  ) {
    let startToEndMins =
      DateStrings.clockwiseDistance(from: entry.startTimeStr, to: entry.endTimeStr) ?? 0
    let startToNowMins =
      DateStrings.clockwiseDistance(from: entry.startTimeStr, to: now) ?? 0
    let endToNowMins = DateStrings.clockwiseDistance(from: entry.endTimeStr, to: now) ?? 0

    let progress: Int
    let mode: Mode

    if startToEndMins == 0 {
      return (0, .day)
    }

    if startToNowMins <= startToEndMins {
      // We're within the start-to-end period, i.e. the day
      progress = Int((Double(startToNowMins) / Double(startToEndMins)) * 100)
      mode = .day
    } else {
      // We're within the end-to-next-start period, i.e. the night
      let endToNextStartMins = (24 * 60) - startToEndMins
      progress = Int((Double(endToNowMins) / Double(endToNextStartMins)) * 100)
      mode = .night
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
      Text("\(100 - progress)% remaining").font(.system(.caption, design: .rounded))
        .padding(.top, 8).padding(.bottom)
    }

  }
}

struct ContinuumWidget: Widget {
  let kind: String = "Widget"

  var body: some WidgetConfiguration {
    StaticConfiguration(
      kind: kind,
      provider: Provider()
    ) { entry in
      WidgetEntryView(entry: entry)
    }
    .configurationDisplayName("Continuum Clock")
    .description("See how much time you have at a glance.")
    .supportedFamilies([.systemSmall])
  }
}

struct Widget_Previews: PreviewProvider {
  static var previews: some View {
    WidgetEntryView(
      entry: SimpleEntry(
        date: Date(),
        startTimeStr: "09:00",
        endTimeStr: "23:30"
      )
    )
    .previewContext(WidgetPreviewContext(family: .systemSmall))
  }
}
