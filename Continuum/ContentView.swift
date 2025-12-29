//
//  ContentView.swift
//  Continuum
//
//  Created by Jack on 10/06/2023.
//

import SwiftUI
import WidgetKit

struct ContentView: View {
  let sharedUserDefaults = UserDefaults(suiteName: "group.systems.weekend.continuum")!

  @State private var startTime: Date
  @State private var endTime: Date

  @State private var showingHomeScreenGuide = false
  @State private var showingLockScreenGuide = false

  init() {
    let startTimeStr = sharedUserDefaults.string(forKey: "startTimeStr")
    let endTimeStr = sharedUserDefaults.string(forKey: "endTimeStr")

    _startTime = State(initialValue: DateStrings.date(from: startTimeStr, default: "09:00"))
    _endTime = State(initialValue: DateStrings.date(from: endTimeStr, default: "23:00"))
  }

  var body: some View {
    let wakingMinutes = DateStrings.clockwiseDistance(from: startTime, to: endTime)!
    let sleepingMinutes = 24 * 60 - wakingMinutes
    let wakeToSleepRatio = Double(wakingMinutes) / Double(sleepingMinutes)

    NavigationStack {
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
            Text("\(wakingMinutes) minutes")
          }
          HStack {
            Text("Sleep-to-wake ratio")
            Spacer()
            VStack(alignment: .trailing) {
              Text("\(String(format: "%.2f", Double(sleepingMinutes)/Double(wakingMinutes)))")
              Text("1:\(String(format: "%.2f", wakeToSleepRatio))").font(.caption).foregroundColor(
                .gray)
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
      .previewDevice(PreviewDevice(rawValue: "iPhone 14"))
      .previewDisplayName("iPhone 14")

    ContentView()
      .previewDevice(PreviewDevice(rawValue: "iPad Air (5th generation)"))
      .previewDisplayName("iPad Air")
  }
}
