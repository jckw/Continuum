//
//  ContentView.swift
//  Continuum
//
//  Created by Jack on 10/06/2023.
//

import SwiftUI
import WidgetKit

func findLowestRatio(a: Int, b: Int) -> (Int, Int) {
  var numerator = a
  var denominator = b

  // Find the greatest common divisor (GCD) using Euclidean algorithm
  while denominator != 0 {
    let remainder = numerator % denominator
    numerator = denominator
    denominator = remainder
  }

  // Divide both numerator and denominator by the GCD
  let gcd = numerator
  let x = a / gcd
  let y = b / gcd

  return (x, y)
}

struct ContentView: View {
  let sharedUserDefaults = UserDefaults(suiteName: "group.G2Q4VASTYV.xyz.jackw.continuum")!

  @State private var startTime: Date
  @State private var endTime: Date
  @State private var workDayStartTime: Date
  @State private var workDayEndTime: Date

  @AppStorage("preWorkDayNotifIsOn") var preWorkDayNotifIsOn: Bool = true
  @AppStorage("workDayEndNotifIsOn") var workDayEndNotifIsOn: Bool = true

  @State private var showingHomeScreenGuide = false
  @State private var showingLockScreenGuide = false

  init() {
    let startTimeStr = sharedUserDefaults.string(forKey: "startTimeStr")
    let endTimeStr = sharedUserDefaults.string(forKey: "endTimeStr")
    let workDayEndTimeStr = sharedUserDefaults.string(forKey: "workDayEndTimeStr")
    let workDayStartTimeStr = sharedUserDefaults.string(forKey: "workDayStartTimeStr")

    _startTime = State(initialValue: DateStrings.date(from: startTimeStr, default: "09:00"))
    _endTime = State(initialValue: DateStrings.date(from: endTimeStr, default: "23:00"))
    _workDayEndTime = State(
      initialValue: DateStrings.date(from: workDayEndTimeStr, default: "17:30"))
    _workDayStartTime = State(
      initialValue: DateStrings.date(from: workDayStartTimeStr, default: "09:00"))
  }

  var body: some View {
    let wakingMinutes = DateStrings.clockwiseDistance(from: startTime, to: endTime)!
    let sleepingMinutes = 24 * 60 - wakingMinutes
    let workingMinutes = DateStrings.clockwiseDistance(from: workDayStartTime, to: workDayEndTime)!
    let (stwRW, stwRS) = findLowestRatio(a: wakingMinutes, b: sleepingMinutes)

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
          DatePicker(
            "Work day start", selection: $workDayStartTime, displayedComponents: .hourAndMinute
          )
          .datePickerStyle(.compact)
          .onChange(of: workDayStartTime) { newValue in
            sharedUserDefaults.set(
              DateStrings.string(from: workDayStartTime), forKey: "workDayStartTimeStr")
            // WidgetCenter.shared.reloadAllTimelines()
          }
          DatePicker(
            "Work day end", selection: $workDayEndTime, displayedComponents: .hourAndMinute
          )
          .datePickerStyle(.compact)
          .onChange(of: workDayEndTime) { newValue in
            sharedUserDefaults.set(
              DateStrings.string(from: workDayEndTime), forKey: "workDayEndTimeStr")
            // WidgetCenter.shared.reloadAllTimelines()
          }
          HStack {
            VStack(alignment: .leading) {
              Text("Start of day notification").padding(.bottom, 1)
              Text(
                "When enabled, Continuum will send you a notification at the start of your waking day to remind you how much time you have before work."
              ).font(.caption).foregroundColor(.gray)
            }
            Spacer()
            Toggle("", isOn: $workDayEndNotifIsOn).labelsHidden()
          }
          HStack {
            VStack(alignment: .leading) {
              Text("End of work day notification").padding(.bottom, 1)
              Text(
                "When enabled, Continuum will send you a notification at the end of your work day to remind you how much time you have left."
              ).font(.caption).foregroundColor(.gray)
            }
            Spacer()
            Toggle("", isOn: $workDayEndNotifIsOn).labelsHidden()
          }
        } header: {
          Text("REMINDERS")
        }
        Section {
          HStack {
            Text("Waking time")
            Spacer()
            Text("\(wakingMinutes) minutes")
          }
          HStack {
            Text("Sleeping time")
            Spacer()
            Text("\(sleepingMinutes) minutes")
          }
          HStack {
            Text("Working time")
            Spacer()
            Text("\(workingMinutes) minutes")
          }
          HStack {
            Text("Sleep-to-wake ratio")
            Spacer()
            VStack(alignment: .trailing) {
              Text("\(String(format: "%.2f", Double(stwRS)/Double(stwRW)))")
              Text("\(stwRS):\(stwRW)").font(.caption).foregroundColor(.gray)
            }
          }
          HStack {
            Text("Waking time working")
            Spacer()
            VStack(alignment: .trailing) {
              Text("\(String(format: "%.1f", Double(workingMinutes)/Double(wakingMinutes)*100))%")
            }
          }
        } header: {
          Text("STATS")
        }
        Section {
          Button("Add to Home Screen") {
            showingHomeScreenGuide.toggle()
          }.fontWeight(.medium)
            .sheet(isPresented: $showingHomeScreenGuide) {
              VStack(alignment: .leading) {
                Text("Adding Continuum to your Home Screen").font(.title).fontWeight(.bold).padding(
                  .bottom, 10)
                VStack(alignment: .leading) {
                  HStack(alignment: .top) {
                    Text("1.").frame(width: 16, alignment: .topLeading)
                    Text(
                      "Touch and hold any empty space on the home screen until the apps start jiggling and the app icons show an \"x\" button."
                    )
                  }.padding(.bottom, 4)
                  HStack(alignment: .top) {
                    Text("2.").frame(width: 16, alignment: .topLeading)
                    Text(
                      "Tap the \"+\" icon in the top left or right corner of the screen. This will open the widget gallery."
                    )
                  }.padding(.bottom, 4)
                  HStack(alignment: .top) {
                    Text("3.").frame(width: 16, alignment: .topLeading)
                    Text("In the widget gallery, search for \"Continuum\" and select it.")
                  }.padding(.bottom, 4)
                  HStack(alignment: .top) {
                    Text("4.").frame(width: 16, alignment: .topLeading)
                    Text("Press \"Add Widget\", place it on your Home Screen, and press \"Done\".")
                  }.padding(.bottom, 4)
                }
              }.frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading).padding(30)
                .presentationDetents([.height(500)])
            }

          Button("Add to Lock Screen") {
            showingLockScreenGuide.toggle()
          }.fontWeight(.medium)
            .sheet(isPresented: $showingLockScreenGuide) {
              VStack(alignment: .leading) {
                Text("Adding Continuum to your Lock Screen").font(.title).fontWeight(.bold).padding(
                  .bottom, 10)
                VStack(alignment: .leading) {
                  HStack(alignment: .top) {
                    Text("1.").frame(width: 16, alignment: .topLeading)
                    Text(
                      "Go to your lock screen and touch and hold the time until the screen goes into customisation mode."
                    )
                  }.padding(.bottom, 4)
                  HStack(alignment: .top) {
                    Text("2.").frame(width: 16, alignment: .topLeading)
                    Text("Tap \"Customise\" and tap your Lock Screen when the two screens appear.")
                  }.padding(.bottom, 4)
                  HStack(alignment: .top) {
                    Text("3.").frame(width: 16, alignment: .topLeading)
                    Text("Tap the space underneath the time and the widget gallery will appear.")
                  }.padding(.bottom, 4)
                  HStack(alignment: .top) {
                    Text("4.").frame(width: 16, alignment: .topLeading)
                    Text("Find the Continuum widget here and tap it.")
                  }.padding(.bottom, 4)
                }
              }.frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading).padding(30)
                .presentationDetents([.height(500)])
            }

        } header: {
          Text("GUIDES")
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
