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
    let startTimeStr = sharedUserDefaults.string(forKey: "startTimeStr") ?? "09:00"
    let endTimeStr = sharedUserDefaults.string(forKey: "endTimeStr") ?? "23:00"

    _startTime = State(initialValue: DateStrings.date(from: startTimeStr))
    _endTime = State(initialValue: DateStrings.date(from: endTimeStr))
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
        sharedUserDefaults.set(DateStrings.string(from: startTime), forKey: "startTimeStr")
        sharedUserDefaults.set(DateStrings.string(from: endTime), forKey: "endTimeStr")

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
