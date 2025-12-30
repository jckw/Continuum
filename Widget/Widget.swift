//
//  Widget.swift
//  Widget
//
//  Created by Jack on 10/06/2023.
//

import SwiftUI
import WidgetKit

struct Provider: TimelineProvider {
  let sharedUserDefaults = UserDefaults(suiteName: "group.systems.weekend.continuum")!

  func placeholder(in context: Context) -> SimpleEntry {
    let (progress, mode) = Provider.calculateProgressAndMode(
      at: Date(), startTimeStr: "09:00", endTimeStr: "23:00")
    let periodEndTime = mode == .day ? "23:00" : "09:00"
    return SimpleEntry(
      date: Date(),
      periodEndDate: DateStrings.relativeDate(
        time: periodEndTime, direction: .next),
      progress: progress, mode: mode)
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
    let periodEndTime = mode == .day ? endTimeStr : startTimeStr
    completion(
      SimpleEntry(
        date: Date(),
        periodEndDate: DateStrings.relativeDate(
          time: periodEndTime,
          direction: .next,
          default: periodEndTime
        ),
        progress: progress,
        mode: mode))
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
      let periodEndTime = mode == .day ? endTimeStr : startTimeStr
      let entry = SimpleEntry(
        date: entryDate,
        periodEndDate: DateStrings.relativeDate(
          time: periodEndTime,
          direction: .next,
          default: periodEndTime,
          from: entryDate
        ),
        progress: progress,
        mode: mode
      )
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
  let periodEndDate: Date
  let progress: Int
  let mode: Mode
}

struct WidgetEntryView: View {
  @Environment(\.widgetFamily) var widgetFamily

  var entry: Provider.Entry

  var body: some View {
    switch widgetFamily {
    case .accessoryCircular:
      if entry.mode == .day {
        Gauge(value: Double(entry.progress) / 100.0) {
          VStack {
            Image(systemName: "sun.min").font(.caption2)
            Text("\(100 - entry.progress)%")
          }
        }
        .gaugeStyle(.accessoryCircularCapacity)
      } else {
        VStack {
          Image(systemName: "moon").font(.caption2)
          Text(entry.periodEndDate, style: .timer)
            .font(.caption2)
            .multilineTextAlignment(.center)
        }
      }

    case .systemSmall:
      if entry.mode == .day {
        VStack {
          HStack(spacing: 4) {
            Image(systemName: "sun.min").font(.caption2)
            Text("ends in").font(
              .system(.caption2, design: .rounded).bold()
            )
            Text(entry.periodEndDate, style: .timer).font(
              .system(.caption2, design: .rounded).bold()
            ).lineLimit(1)
          }
          .padding(.leading)
          .padding(.top)
          .frame(maxWidth: .infinity, alignment: .leading)
          
          Spacer()
          
          Text("\(100 - entry.progress)%")
            .font(.system(.largeTitle, design: .rounded))
            .fontWeight(.bold)
          
          Text("remaining in day")
            .font(.system(.callout, design: .rounded))
          
          Spacer()

          Text("\(entry.progress)% complete")
            .font(.system(.caption, design: .rounded))
            .padding(.bottom)
            .padding(.top, 8)
        }
      } else {
        VStack {
          Spacer()
          Image(systemName: "moon")
            .font(.title2)
            .padding(.bottom, 4)
          Text("Your day begins in")
            .font(.system(.caption, design: .rounded))
          Text(entry.periodEndDate, style: .timer)
            .font(.system(.title2, design: .rounded))
            .fontWeight(.medium)
            .monospacedDigit()
          Spacer()
        }
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
        .containerBackground(.fill.tertiary, for: .widget)
    }
    .configurationDisplayName("Continuum Clock")
    .description("See how much time you have at a glance.")
    .supportedFamilies([.systemSmall, .accessoryCircular])
  }
}

struct Widget_Previews: PreviewProvider {
  static var previews: some View {
    let now = Date()

    let (progress, mode) = Provider.calculateProgressAndMode(
      at: now, startTimeStr: "09:00", endTimeStr: "23:00")
    let periodEndTime = mode == .day ? "23:00" : "09:00"

    WidgetEntryView(
      entry: SimpleEntry(
        date: now,
        periodEndDate: DateStrings.relativeDate(
          time: periodEndTime, direction: .next),
        progress: progress, mode: mode)
    )
    .previewContext(WidgetPreviewContext(family: .systemSmall))
  }
}
