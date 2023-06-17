//
//  ContentView.swift
//  Continuum
//
//  Created by Jack on 10/06/2023.
//

import SwiftUI
import WidgetKit

struct ContentView: View {
  let sharedUserDefaults = UserDefaults(suiteName: "group.G2Q4VASTYV.xyz.jackw.continuum")!

  @State private var startTime: Date
  @State private var endTime: Date

  init() {
    let startTimeStr = sharedUserDefaults.string(forKey: "startTimeStr")
    let endTimeStr = sharedUserDefaults.string(forKey: "endTimeStr")

    _startTime = State(initialValue: DateStrings.date(from: startTimeStr, default: "09:00"))
    _endTime = State(initialValue: DateStrings.date(from: endTimeStr, default: "23:00"))
  }

  var body: some View {
    NavigationView {
      List {
        Section {
          DatePicker("Start of day", selection: $startTime, displayedComponents: .hourAndMinute)
            .datePickerStyle(.compact)
            .onChange(of: startTime) { newValue in
              sharedUserDefaults.set(DateStrings.string(from: newValue), forKey: "startTimeStr")
              WidgetCenter.shared.reloadAllTimelines()
            }
          DatePicker("End of day", selection: $endTime, displayedComponents: .hourAndMinute)
            .datePickerStyle(.compact)
            .onChange(of: endTime) { newValue in
              sharedUserDefaults.set(DateStrings.string(from: endTime), forKey: "endTimeStr")
              WidgetCenter.shared.reloadAllTimelines()
            }
        } header: {
          Text("CONFIG")
        }
        Section {
          HStack {
            Text("Waking time")
            Spacer()
            Text("\(DateStrings.clockwiseDistance(from: startTime, to: endTime)!) minutes")
          }
        } header: {
          Text("STATS")
        }
      }
      .listStyle(InsetGroupedListStyle())
      .navigationTitle("Continuum")
    }
  }
}

struct ContentView_Previews: PreviewProvider {
  static var previews: some View {
    ContentView()
  }
}
