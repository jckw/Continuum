//
//  Track.swift
//  Track
//
//  Created by Jack on 10/06/2023.
//

import WidgetKit
import SwiftUI
import Intents

struct Provider: IntentTimelineProvider {
    func placeholder(in context: Context) -> SimpleEntry {
        SimpleEntry(date: Date(), configuration: ConfigurationIntent(), progress: 20, mode: .day)
    }
    
    func calculateProgressAndMode(now: Date, startTime: Date, endTime: Date) -> (progress: Int, mode: Mode) {
        var endMins = Calendar.current.component(.hour, from: endTime) * 60 + Calendar.current.component(.minute, from: endTime)
        let startMins = Calendar.current.component(.hour, from: startTime) * 60 + Calendar.current.component(.minute, from: startTime)
        var currentMins = Calendar.current.component(.hour, from: now) * 60 + Calendar.current.component(.minute, from: now)
        
        if endMins < startMins {
            endMins += 24 * 60
        }
        
        if currentMins < startMins {
            currentMins += 24 * 60
        }
        
        let progress: Int
        let mode: Mode
        if currentMins > endMins {
            progress = Int((Double(currentMins - endMins) / Double(24 * 60 - (endMins - startMins))) * 100)
            mode = .night
        } else {
            progress = Int((Double(currentMins - startMins) / Double(endMins - startMins)) * 100)
            mode = .day
        }
        
        return (progress, mode)
    }
    
    static func defaultDate(hour: Int, minute: Int) -> Date {
        var components = Calendar.current.dateComponents([.year, .month, .day], from: Date())
        components.hour = hour
        components.minute = minute
        return Calendar.current.date(from: components) ?? Date()
    }
    
    func getStartEndTime() -> (startTime: Date, endTime: Date) {
        let startTime, endTime: Date
        if let sharedUserDefaults = UserDefaults(suiteName: "group.xyz.jackw.continuum") {
            let startTimeInterval = sharedUserDefaults.double(forKey: "startTime")
            let endTimeInterval = sharedUserDefaults.double(forKey: "endTime")
            
            startTime = Date(timeIntervalSinceReferenceDate: startTimeInterval)
            endTime = Date(timeIntervalSinceReferenceDate: endTimeInterval)
        } else {
            startTime = Provider.defaultDate(hour: 9, minute: 0)
            endTime = Provider.defaultDate(hour: 23, minute: 0)
        }
        
        return (startTime, endTime)
    }
    
    func getSnapshot(for configuration: ConfigurationIntent, in context: Context, completion: @escaping (SimpleEntry) -> ()) {
        let (startTime, endTime) = getStartEndTime()
        let currentDate = Date()
        let (progress, mode) = calculateProgressAndMode(now: currentDate, startTime: startTime, endTime: endTime)
        
        completion(SimpleEntry(date: Date(), configuration: configuration, progress: progress, mode: mode))
    }
    
    
    func getTimeline(for configuration: ConfigurationIntent, in context: Context, completion: @escaping (Timeline<Entry>) -> ()) {
        var entries: [SimpleEntry] = []
        let (startTime, endTime) = getStartEndTime()
        let currentDate = Date()
        for minuteOffset in 0 ..< 24*60 {
            let entryDate = Calendar.current.date(byAdding: .minute, value: minuteOffset, to: currentDate)!
            let (progress, mode) = calculateProgressAndMode(now: currentDate, startTime: startTime, endTime: endTime)
            let entry = SimpleEntry(date: entryDate, configuration: configuration, progress: progress, mode: mode)
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
    let configuration: ConfigurationIntent
    let progress: Int
    let mode: Mode
}



struct TrackEntryView : View {
    var entry: Provider.Entry
    
    var body: some View {
        VStack {
            Text(entry.date, style: .time).frame(maxWidth: .infinity, alignment: .leading).padding(.leading).padding(.top).font(.caption2)
            Spacer()
            Text("\(entry.progress)%").font(.largeTitle).fontWeight(.bold)
            Text("through the \(entry.mode.name)")
            Spacer()
            Text("\( 100 - entry.progress)% remaining").font(.caption).padding(.top, 8).padding(.bottom)
            
        }
        
    }
}

struct Track: Widget {
    let kind: String = "Track"
    
    var body: some WidgetConfiguration {
        IntentConfiguration(kind: kind, intent: ConfigurationIntent.self, provider: Provider()) { entry in
            TrackEntryView(entry: entry)
        }
        .configurationDisplayName("My Widget")
        .description("This is an example widget.")
    }
}

struct Track_Previews: PreviewProvider {
    static var previews: some View {
        TrackEntryView(entry: SimpleEntry(date: Date(), configuration: ConfigurationIntent(), progress: 23, mode: .day))
            .previewContext(WidgetPreviewContext(family: .systemSmall))
    }
}
