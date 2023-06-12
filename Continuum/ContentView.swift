//
//  ContentView.swift
//  Continuum
//
//  Created by Jack on 10/06/2023.
//

import SwiftUI
import WidgetKit

struct ContentView: View {
  let sharedUserDefaults = UserDefaults(suiteName: "G2Q4VASTYV.group.xyz.jackw.continuum")!

  @State private var startTime: Date
  @State private var endTime: Date

  init() {
    let startTimeStr = sharedUserDefaults.string(forKey: "startTimeStr") ?? "09:00"
    let endTimeStr = sharedUserDefaults.string(forKey: "endTimeStr") ?? "23:00"

    _startTime = State(initialValue: DateStrings.date(from: startTimeStr))
    _endTime = State(initialValue: DateStrings.date(from: endTimeStr))
  }

  var body: some View {
    VStack(alignment: .leading) {
      Text("Continuum").font(.title).fontWeight(.medium)

      DatePicker("Start of Day", selection: $startTime, displayedComponents: .hourAndMinute)
        .datePickerStyle(.compact)
        .onChange(of: startTime) { newValue in
          sharedUserDefaults.set(DateStrings.string(from: newValue), forKey: "startTimeStr")
          WidgetCenter.shared.reloadAllTimelines()
        }
      DatePicker("End of Day", selection: $endTime, displayedComponents: .hourAndMinute)
        .datePickerStyle(.compact)
        .onChange(of: endTime) { newValue in
          sharedUserDefaults.set(DateStrings.string(from: endTime), forKey: "endTimeStr")
          WidgetCenter.shared.reloadAllTimelines()

        }

      Spacer()
    }

    .padding()
    .onAppear(perform: { () in
      WidgetCenter.shared.reloadTimelines(ofKind: "Track")
        print("SHould have reloaded timeline")
    })
  }
}

struct ContentView_Previews: PreviewProvider {
  static var previews: some View {
    ContentView()
  }
}
