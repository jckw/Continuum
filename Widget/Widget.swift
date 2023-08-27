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
    let (progress, mode) = Provider.calculateProgressAndMode(
      at: Date(), startTimeStr: "09:00", endTimeStr: "23:00")
    return SimpleEntry(date: Date(), progress: progress, mode: mode)
  }

  func getStartEndTimeStr() -> (startTimeStr: String, endTimeStr: String) {
    let startTimeStr = sharedUserDefaults.string(forKey: "startTimeStr") ?? "09:00"
    let endTimeStr = sharedUserDefaults.string(forKey: "endTimeStr") ?? "23:00"

    return (startTimeStr, endTimeStr)
  }

  static func calculateProgressAndMode(at now: Date, startTimeStr: String, endTimeStr: String) -> (
    progress: Int, mode: Mode
  ) {

    let startToEndMins =
      DateStrings.clockwiseDistance(from: startTimeStr, to: endTimeStr) ?? 0
    let startToNowMins =
      DateStrings.clockwiseDistance(from: startTimeStr, to: now) ?? 0
    let endToNowMins = DateStrings.clockwiseDistance(from: endTimeStr, to: now) ?? 0

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

  func getSnapshot(in context: Context, completion: @escaping (SimpleEntry) -> Void) {
    let (startTimeStr, endTimeStr) = getStartEndTimeStr()
    let (progress, mode) = Provider.calculateProgressAndMode(
      at: Date(), startTimeStr: startTimeStr, endTimeStr: endTimeStr)
    completion(SimpleEntry(date: Date(), progress: progress, mode: mode))
  }

  func getTimeline(in context: Context, completion: @escaping (Timeline<Entry>) -> Void) {
    var entries: [SimpleEntry] = []
    let currentDate = Date()
    let (startTimeStr, endTimeStr) = getStartEndTimeStr()

    let startToEndMins = DateStrings.clockwiseDistance(from: startTimeStr, to: endTimeStr) ?? 0
    let stepSizeInMinutes = Double(startToEndMins) / 100.0

    // Watch out here: increasing the number of entries rendered can cause the widget to
    // exceed 30MB memory and crash it
    for percentage in 0..<150 {
      let currentOffset = Double(percentage) * stepSizeInMinutes
      let entryDate = Calendar.current.date(
        byAdding: .minute, value: Int(currentOffset), to: currentDate)!.zeroSeconds!
      let (progress, mode) = Provider.calculateProgressAndMode(
        at: entryDate, startTimeStr: startTimeStr, endTimeStr: endTimeStr)
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

struct WidgetEntryView: View {
  @Environment(\.widgetFamily) var widgetFamily

  var entry: Provider.Entry

  var body: some View {
    switch widgetFamily {
    case .accessoryCircular:
      Gauge(value: Double(entry.progress) / 100.0) {
        VStack {
          Image(systemName: entry.mode == .day ? "sun.min" : "moon").font(.caption2)
          Text("\(entry.progress)%")
        }

      }
      .gaugeStyle(.accessoryCircularCapacity)

    case .systemSmall:
      VStack {
        HStack {
          Image(systemName: entry.mode == .day ? "sun.min" : "moon").font(.caption2)
          Text(Date(), style: .time).font(.system(.caption2, design: .rounded).bold())
        }.padding(.leading).padding(.top).frame(maxWidth: .infinity, alignment: .leading)
        Spacer()
        Text("\(entry.progress)%").font(.system(.largeTitle, design: .rounded)).fontWeight(.bold)
        Text("through the \(entry.mode.name)")
        Spacer()
        Text("\(100 - entry.progress)% remaining").font(.system(.caption, design: .rounded))
          .padding(.top, 8).padding(.bottom)
      }

    default:
      Text("Not yet implemented")
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
    .supportedFamilies([.systemSmall, .accessoryCircular])
  }
}

struct Widget_Previews: PreviewProvider {
  static var previews: some View {
    let (progress, mode) = Provider.calculateProgressAndMode(
      at: Date(), startTimeStr: "09:00", endTimeStr: "23:00")

    WidgetEntryView(
      entry: SimpleEntry(date: Date(), progress: progress, mode: mode)
    )
    .previewContext(WidgetPreviewContext(family: .systemSmall))
  }
}
