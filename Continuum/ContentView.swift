//
//  ContentView.swift
//  Continuum
//
//  Created by Jack on 10/06/2023.
//

import SwiftUI
import SwiftData
import TipKit
import WidgetKit

struct HomeScreenWidgetTip: Tip {
  var title: Text { Text("Add to Home Screen") }
  var message: Text? {
    Text("Long-press your home screen, tap +, and search for Continuum.")
  }
  var image: Image? { Image(systemName: "plus.square.on.square") }
}

struct LockScreenWidgetTip: Tip {
  var title: Text { Text("Add to Lock Screen") }
  var message: Text? {
    Text("Long-press your lock screen, tap Customize, and add Continuum.")
  }
  var image: Image? { Image(systemName: "lock.circle") }
}

enum NavigationItem: Hashable {
  case today
  case journal
  case settings
}

struct ContentView: View {
  @Environment(\.horizontalSizeClass) private var horizontalSizeClass
  @State private var showOnboarding = false
  
  let sharedUserDefaults = UserDefaults(suiteName: "group.systems.weekend.continuum")!

  var body: some View {
    Group {
      if horizontalSizeClass == .regular {
        iPadContentView()
      } else {
        iPhoneContentView()
      }
    }
    .onAppear {
      let hasCompleted = sharedUserDefaults.bool(forKey: "hasCompletedOnboarding")
      showOnboarding = !hasCompleted
    }
    .fullScreenCover(isPresented: $showOnboarding) {
      OnboardingView()
    }
  }
}

struct iPadContentView: View {
  @State private var selection: NavigationItem? = .today

  var body: some View {
    NavigationSplitView {
      List(selection: $selection) {
        Label("Today", systemImage: "clock")
          .tag(NavigationItem.today)
        Label("Settings", systemImage: "gear")
          .tag(NavigationItem.settings)
      }
      .navigationTitle("Continuum")
    } detail: {
      switch selection {
      case .today:
        TodayView()
      case .settings:
        SettingsView()
      case .journal, nil:
        Text("Select an item")
      }
    }
  }
}

struct iPhoneContentView: View {
  var body: some View {
    TabView {
      NavigationStack {
        TodayView()
      }
      .tabItem {
        Label("Today", systemImage: "clock")
      }

      NavigationStack {
        SettingsView()
      }
      .tabItem {
        Label("Settings", systemImage: "gear")
      }
    }
  }
}

struct TodayView: View {
  @Environment(\.modelContext) private var modelContext
  @Environment(\.scenePhase) private var scenePhase
  @Query(sort: \JournalEntry.date, order: .reverse) private var allEntries: [JournalEntry]
  
  let sharedUserDefaults = UserDefaults(suiteName: "group.systems.weekend.continuum")!
  
  private let homeScreenTip = HomeScreenWidgetTip()
  private let lockScreenTip = LockScreenWidgetTip()
  
  @State private var showingCalendar = false
  @State private var showingEntrySheet = false
  @State private var editingEntry: JournalEntry?
  @State private var currentTime = Date()
  
  @StateObject private var scheduleManager = ScheduleManager.shared
  @State private var showingScheduleSheet = false
  @State private var editingScheduleItem: ScheduleItem?
  
  let timer = Timer.publish(every: 60, on: .main, in: .common).autoconnect()

  var body: some View {
    let startTimeStr = sharedUserDefaults.string(forKey: "startTimeStr") ?? "09:00"
    let endTimeStr = sharedUserDefaults.string(forKey: "endTimeStr") ?? "23:00"

    let now = currentTime
    let startToEndMins = DateStrings.clockwiseDistance(from: startTimeStr, to: endTimeStr) ?? 0
    let startToNowMins = DateStrings.clockwiseDistance(from: startTimeStr, to: now) ?? 0

    let isDay = startToNowMins <= startToEndMins
    let progress = startToEndMins > 0 ? Int((Double(startToNowMins) / Double(startToEndMins)) * 100) : 0
    let periodEndTime = isDay ? endTimeStr : startTimeStr
    let periodEndDate = DateStrings.relativeDate(time: periodEndTime, direction: .next)

    ScrollView {
      VStack(spacing: 20) {
        // Hero Progress Section
        VStack(spacing: 0) {
          if isDay {
            VStack(spacing: 0) {
              // Icon at top
              Image(systemName: "sun.max.fill")
                .font(.system(size: 32, weight: .semibold))
                .foregroundStyle(.white.opacity(0.95))
                .padding(.bottom, 32)
              
              // Clean percentage display
              VStack(spacing: 8) {
                Text("\(100 - progress)%")
                  .font(.system(size: 64, weight: .semibold, design: .rounded))
                  .foregroundStyle(.white)
                  .kerning(-2)
                
                Text("of your day remains")
                  .font(.system(size: 17, weight: .medium))
                  .foregroundStyle(.white.opacity(0.85))
                  .tracking(0.3)
              }
              .padding(.bottom, 40)
              
              // Progress track
              GeometryReader { geometry in
                ZStack(alignment: .leading) {
                  Capsule()
                    .fill(.white.opacity(0.25))
                    .frame(height: 4)
                  
                  Capsule()
                    .fill(.white)
                    .frame(width: geometry.size.width * Double(progress) / 100.0, height: 4)
                }
              }
              .frame(height: 4)
              .padding(.bottom, 20)
              
              // Time labels
              HStack {
                Text(startTimeStr)
                  .font(.system(size: 14, weight: .medium, design: .rounded))
                  .foregroundStyle(.white.opacity(0.7))
                  .monospacedDigit()
                
                Spacer()
                
                Text("ends at \(endTimeStr)")
                  .font(.system(size: 14, weight: .medium, design: .rounded))
                  .foregroundStyle(.white.opacity(0.7))
                  .monospacedDigit()
              }
            }
            .frame(maxWidth: .infinity)
            .padding(.horizontal, 32)
            .padding(.vertical, 44)
            .background(
              LinearGradient(
                colors: [
                  Color.orange,
                  Color.orange.opacity(0.85)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
              )
            )
          } else {
            VStack(spacing: 0) {
              // Night icon
              Image(systemName: "moon.stars.fill")
                .font(.system(size: 32, weight: .semibold))
                .foregroundStyle(.white.opacity(0.95))
                .padding(.bottom, 32)
              
              // Night message
              VStack(spacing: 8) {
                Text("Rest")
                  .font(.system(size: 36, weight: .semibold))
                  .foregroundStyle(.white)
                  .tracking(1.5)
                
                Text("Your day begins in")
                  .font(.system(size: 17, weight: .medium))
                  .foregroundStyle(.white.opacity(0.85))
                  .tracking(0.3)
                  .padding(.bottom, 24)
              }
              
              // Timer display
              Text(periodEndDate, style: .timer)
                .font(.system(size: 56, weight: .semibold, design: .rounded))
                .foregroundStyle(.white)
                .monospacedDigit()
                .padding(.bottom, 32)
              
              // Start time
              Text("at \(startTimeStr)")
                .font(.system(size: 14, weight: .medium, design: .rounded))
                .foregroundStyle(.white.opacity(0.7))
                .monospacedDigit()
            }
            .frame(maxWidth: .infinity)
            .padding(.horizontal, 32)
            .padding(.vertical, 44)
            .background(
              LinearGradient(
                colors: [
                  Color.indigo,
                  Color.indigo.opacity(0.85)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
              )
            )
          }
        }
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .shadow(color: Color.black.opacity(0.1), radius: 20, x: 0, y: 8)
        .padding(.horizontal, 20)
        .padding(.top, 16)
        
        // Journal section
        VStack(alignment: .leading, spacing: 12) {
          HStack {
            Text("Journal")
              .font(.title3)
              .fontWeight(.semibold)
            
            Spacer()
            
            Button {
              showingCalendar = true
            } label: {
              Label("All Days", systemImage: "calendar")
                .font(.subheadline)
                .labelStyle(.iconOnly)
            }
          }
          .padding(.horizontal, 16)
          
          if todayEntries.isEmpty {
            // Compact empty state
            Button {
              editingEntry = nil
              showingEntrySheet = true
            } label: {
              HStack {
                Image(systemName: "square.and.pencil")
                  .font(.title2)
                  .foregroundStyle(.secondary)
                
                VStack(alignment: .leading, spacing: 2) {
                  Text("No notes yet")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundStyle(.primary)
                  
                  Text("Tap to add your first entry")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                  .font(.caption)
                  .foregroundStyle(.tertiary)
              }
              .padding(12)
              .background(Color(uiColor: .secondarySystemGroupedBackground))
              .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            }
            .buttonStyle(.plain)
            .padding(.horizontal, 16)
          } else {
            LazyVStack(spacing: 10) {
              ForEach(todayEntries) { entry in
                EntryCard(
                  entry: entry,
                  onTap: {
                    editingEntry = entry
                    showingEntrySheet = true
                  },
                  onDelete: {
                    modelContext.delete(entry)
                  }
                )
              }
            }
            .padding(.horizontal, 16)
          }
        }
        
        // Schedule section
        ScheduleSection(
          scheduleManager: scheduleManager,
          wakingMinutes: startToEndMins,
          showingAddSheet: $showingScheduleSheet,
          editingItem: $editingScheduleItem
        )
        
        // Tips section
        VStack(spacing: 10) {
          TipView(homeScreenTip)
          TipView(lockScreenTip)
        }
        .padding(.horizontal, 16)
        .padding(.bottom, 16)
      }
    }
    .background(Color(uiColor: .systemGroupedBackground))
    .navigationBarTitleDisplayMode(.inline)
    .toolbar {
      ToolbarItem(placement: .principal) {
        Text("Today")
          .font(.headline)
      }
      
      ToolbarItem(placement: .primaryAction) {
        Button {
          editingEntry = nil
          showingEntrySheet = true
        } label: {
          Image(systemName: "plus.circle.fill")
            .imageScale(.large)
        }
      }
    }
    .sheet(isPresented: $showingEntrySheet) {
      EntryEditorSheet(
        selectedDate: Date(),
        entry: editingEntry
      )
    }
    .sheet(isPresented: $showingCalendar) {
      CalendarNavigationView()
    }
    .sheet(isPresented: $showingScheduleSheet) {
      AddEditScheduleSheet(
        scheduleManager: scheduleManager,
        editingItem: editingScheduleItem
      )
    }
    .onReceive(timer) { _ in
      currentTime = Date()
    }
    .onChange(of: scenePhase) { _, newPhase in
      if newPhase == .active {
        currentTime = Date()
      }
    }
    .onAppear {
      currentTime = Date()
    }
  }
  
  private var todayEntries: [JournalEntry] {
    allEntries.filter { Calendar.current.isDateInToday($0.date) }
  }
}

struct CalendarNavigationView: View {
  @Environment(\.dismiss) private var dismiss
  @Environment(\.modelContext) private var modelContext
  @Query(sort: \JournalEntry.date, order: .reverse) private var allEntries: [JournalEntry]
  
  @State private var selectedDate: Date = Date()
  @State private var displayedMonth: Date = Date()
  @State private var showingEntrySheet = false
  @State private var editingEntry: JournalEntry?
  
  var body: some View {
    NavigationStack {
      VStack(spacing: 0) {
        CalendarGridView(
          displayedMonth: $displayedMonth,
          selectedDate: $selectedDate,
          entriesForMonth: entriesForMonth
        )
        
        Divider()
        
        EntriesListView(
          selectedDate: selectedDate,
          entries: entriesForSelectedDate,
          onAdd: {
            editingEntry = nil
            showingEntrySheet = true
          },
          onEdit: { entry in
            editingEntry = entry
            showingEntrySheet = true
          },
          onDelete: { entry in
            modelContext.delete(entry)
          }
        )
      }
      .navigationBarTitleDisplayMode(.inline)
      .toolbar {
        ToolbarItem(placement: .principal) {
          Text("All Days")
            .font(.headline)
        }
        
        ToolbarItem(placement: .cancellationAction) {
          Button("Done") {
            dismiss()
          }
        }
      }
      .sheet(isPresented: $showingEntrySheet) {
        EntryEditorSheet(
          selectedDate: selectedDate,
          entry: editingEntry
        )
      }
    }
  }
  
  private var entriesForMonth: [Date: Bool] {
    let calendar = Calendar.current
    let monthStart = calendar.date(from: calendar.dateComponents([.year, .month], from: displayedMonth))!
    
    var result: [Date: Bool] = [:]
    for entry in allEntries {
      let entryDay = calendar.startOfDay(for: entry.date)
      if calendar.isDate(entryDay, equalTo: monthStart, toGranularity: .month) {
        result[entryDay] = true
      }
    }
    return result
  }
  
  private var entriesForSelectedDate: [JournalEntry] {
    let targetDate = Calendar.current.startOfDay(for: selectedDate)
    return allEntries.filter { Calendar.current.isDate($0.date, inSameDayAs: targetDate) }
  }
}

struct SettingsView: View {
  let sharedUserDefaults = UserDefaults(suiteName: "group.systems.weekend.continuum")!

  @State private var startTime: Date
  @State private var endTime: Date
  @State private var showOnboarding = false
  @StateObject private var notificationManager = NotificationManager.shared

  private let homeScreenTip = HomeScreenWidgetTip()
  private let lockScreenTip = LockScreenWidgetTip()

  init() {
    let defaults = UserDefaults(suiteName: "group.systems.weekend.continuum")!
    let startTimeStr = defaults.string(forKey: "startTimeStr")
    let endTimeStr = defaults.string(forKey: "endTimeStr")

    _startTime = State(initialValue: DateStrings.date(from: startTimeStr, default: "09:00"))
    _endTime = State(initialValue: DateStrings.date(from: endTimeStr, default: "23:00"))
  }

  var body: some View {
    let wakingMinutes = DateStrings.clockwiseDistance(from: startTime, to: endTime)!
    let sleepingMinutes = 24 * 60 - wakingMinutes
    let wakeToSleepRatio = Double(wakingMinutes) / Double(sleepingMinutes)

    List {
      Section {
        DatePicker("Start of day", selection: $startTime, displayedComponents: .hourAndMinute)
          .datePickerStyle(.compact)
          .onChange(of: startTime) { _, newValue in
            sharedUserDefaults.set(DateStrings.string(from: newValue), forKey: "startTimeStr")
            WidgetCenter.shared.reloadAllTimelines()
            Task { await notificationManager.rescheduleNotifications() }
          }
        DatePicker("End of day", selection: $endTime, displayedComponents: .hourAndMinute)
          .datePickerStyle(.compact)
          .onChange(of: endTime) { _, newValue in
            sharedUserDefaults.set(DateStrings.string(from: newValue), forKey: "endTimeStr")
            WidgetCenter.shared.reloadAllTimelines()
            Task { await notificationManager.rescheduleNotifications() }
          }
      } header: {
        Text("SCHEDULE")
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
        Toggle("Milestone Notifications", isOn: $notificationManager.settings.enabled)
          .onChange(of: notificationManager.settings.enabled) { _, newValue in
            if newValue {
              Task {
                let granted = await notificationManager.requestPermission()
                if !granted {
                  notificationManager.settings.enabled = false
                }
              }
            }
          }
        if notificationManager.settings.enabled {
          ForEach(NotificationSettings.availableThresholds, id: \.self) { threshold in
            Toggle("\(threshold)% remaining", isOn: Binding(
              get: { notificationManager.settings.thresholds.contains(threshold) },
              set: { isOn in
                if isOn {
                  notificationManager.settings.thresholds.insert(threshold)
                } else {
                  notificationManager.settings.thresholds.remove(threshold)
                }
              }
            ))
          }
        }
      } header: {
        Text("NOTIFICATIONS")
      }
      Section {
        Button("Show Welcome") {
          showOnboarding = true
        }
      } header: {
        Text("ABOUT")
      }
    }
    .listStyle(InsetGroupedListStyle())
    .navigationBarTitleDisplayMode(.inline)
    .toolbar {
      ToolbarItem(placement: .principal) {
        Text("Settings")
          .font(.headline)
      }
    }
    .fullScreenCover(isPresented: $showOnboarding) {
      OnboardingView()
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
