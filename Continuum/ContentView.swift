//
//  ContentView.swift
//  Continuum
//
//  Created by Jack on 10/06/2023.
//

import SwiftUI
import WidgetKit

struct ContentView: View {
  let sharedUserDefaults = UserDefaults(suiteName: "group.xyz.jackw.continuum")!

  @State private var startTime: Date
  @State private var endTime: Date

  init() {
    let startTimeInterval = sharedUserDefaults.double(forKey: "startTime")
    let endTimeInterval = sharedUserDefaults.double(forKey: "endTime")

    let defaultStartTime = ContentView.defaultDate(hour: 9, minute: 0)
    let defaultEndTime = ContentView.defaultDate(hour: 23, minute: 0)

    _startTime = State(
      initialValue: startTimeInterval != 0.0
        ? Date(timeIntervalSinceReferenceDate: startTimeInterval) : defaultStartTime)
    _endTime = State(
      initialValue: endTimeInterval != 0.0
        ? Date(timeIntervalSinceReferenceDate: endTimeInterval) : defaultEndTime)
  }

  static func defaultDate(hour: Int, minute: Int) -> Date {
    var components = Calendar.current.dateComponents([.year, .month, .day], from: Date())
    components.hour = hour
    components.minute = minute
    return Calendar.current.date(from: components) ?? Date()
  }

  var body: some View {
    VStack {
      HStack {
        Text("Start of day")
        Spacer()
        DatePicker("Start Time", selection: $startTime, displayedComponents: .hourAndMinute)
          .datePickerStyle(.compact)
          .labelsHidden()

      }
      HStack {
        Text("End of day")
        Spacer()
        DatePicker("End Time", selection: $endTime, displayedComponents: .hourAndMinute)
          .datePickerStyle(.compact)
          .labelsHidden()
      }

      Button("Save") {
        let startTimeInterval = startTime.timeIntervalSinceReferenceDate
        let endTimeInterval = endTime.timeIntervalSinceReferenceDate

        sharedUserDefaults.set(startTimeInterval, forKey: "startTime")
        sharedUserDefaults.set(endTimeInterval, forKey: "endTime")

        WidgetCenter.shared.reloadAllTimelines()
      }
      Spacer()
    }
    .padding()
  }
}

struct ContentView_Previews: PreviewProvider {
  static var previews: some View {
    ContentView()
  }
}
