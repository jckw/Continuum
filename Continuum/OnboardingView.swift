//
//  OnboardingView.swift
//  Continuum
//
//  Created by Claude on 29/12/2024.
//

import SwiftUI
import WidgetKit

struct OnboardingView: View {
  @Environment(\.dismiss) private var dismiss
  @State private var currentPage = 0
  
  let sharedUserDefaults = UserDefaults(suiteName: "group.systems.weekend.continuum")!
  @State private var startTime: Date
  @State private var endTime: Date
  @StateObject private var notificationManager = NotificationManager.shared
  
  init() {
    let defaults = UserDefaults(suiteName: "group.systems.weekend.continuum")!
    let startTimeStr = defaults.string(forKey: "startTimeStr")
    let endTimeStr = defaults.string(forKey: "endTimeStr")
    
    _startTime = State(initialValue: DateStrings.date(from: startTimeStr, default: "09:00"))
    _endTime = State(initialValue: DateStrings.date(from: endTimeStr, default: "23:00"))
  }
  
  var body: some View {
    VStack(spacing: 0) {
      // Back button area
      HStack {
        if currentPage > 0 {
          OnboardingBackButton {
            withAnimation(.easeInOut(duration: 0.3)) {
              currentPage -= 1
            }
          }
        }
        Spacer()
      }
      .padding(.horizontal, 20)
      .padding(.top, 16)
      .frame(height: 52)
      
      // Content carousel - swipeable
      TabView(selection: $currentPage) {
        WelcomeContent()
          .tag(0)
        
        SetYourDayContent(
          startTime: $startTime,
          endTime: $endTime,
          sharedUserDefaults: sharedUserDefaults
        )
          .tag(1)
        
        StayAwareContent(notificationManager: notificationManager)
          .tag(2)
      }
      .tabViewStyle(.page(indexDisplayMode: .never))
      
      // Fixed bottom area
      VStack(spacing: 20) {
        PageIndicator(currentPage: currentPage)
        
        Button {
          if currentPage < 2 {
            withAnimation(.easeInOut(duration: 0.3)) {
              currentPage += 1
            }
          } else {
            completeOnboarding()
          }
        } label: {
          Text(currentPage == 2 ? "Get Started" : "Continue")
            .font(.headline)
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(Color.accentColor)
            .clipShape(RoundedRectangle(cornerRadius: 14))
        }
        .padding(.horizontal, 40)
      }
      .padding(.bottom, 20)
    }
    .interactiveDismissDisabled()
  }
  
  private func completeOnboarding() {
    sharedUserDefaults.set(true, forKey: "hasCompletedOnboarding")
    dismiss()
  }
}

// MARK: - Page Indicator
struct PageIndicator: View {
  let currentPage: Int
  let totalPages: Int = 3
  
  var body: some View {
    HStack(spacing: 8) {
      ForEach(0..<totalPages, id: \.self) { index in
        Circle()
          .fill(currentPage == index ? Color.primary : Color.secondary.opacity(0.3))
          .frame(width: 8, height: 8)
      }
    }
  }
}

// MARK: - Back Button
struct OnboardingBackButton: View {
  let action: () -> Void
  
  var body: some View {
    Button(action: action) {
      Image(systemName: "chevron.left")
        .font(.system(size: 16, weight: .semibold))
        .foregroundStyle(.primary)
        .frame(width: 36, height: 36)
        .background(Color.secondary.opacity(0.15))
        .clipShape(Circle())
    }
  }
}

// MARK: - Content 1: Welcome
struct WelcomeContent: View {
  @State private var iconScale: CGFloat = 1.0
  
  var body: some View {
    VStack(spacing: 0) {
      Spacer()
      
      // Animated sun/moon icon
      ZStack {
        Image(systemName: "sun.max.fill")
          .font(.system(size: 100))
          .foregroundStyle(.orange)
          .opacity(iconScale > 1.05 ? 1 : 0)
        
        Image(systemName: "moon.fill")
          .font(.system(size: 100))
          .foregroundStyle(.indigo)
          .opacity(iconScale <= 1.05 ? 1 : 0)
      }
      .scaleEffect(iconScale)
      .onAppear {
        withAnimation(.easeInOut(duration: 2.0).repeatForever(autoreverses: true)) {
          iconScale = 1.1
        }
      }
      .padding(.bottom, 60)
      
      Text("You have more time\nthan you think")
        .font(.system(size: 34, weight: .bold))
        .multilineTextAlignment(.center)
        .lineLimit(2)
        .minimumScaleFactor(0.8)
        .padding(.horizontal, 40)
        .padding(.bottom, 16)
      
      Text("Continuum helps you reclaim your waking hours by showing you how much time you truly have.")
        .font(.body)
        .foregroundStyle(.secondary)
        .multilineTextAlignment(.center)
        .lineLimit(3)
        .minimumScaleFactor(0.9)
        .padding(.horizontal, 40)
      
      Spacer()
    }
  }
}

// MARK: - Content 2: Set Your Day
struct SetYourDayContent: View {
  @Binding var startTime: Date
  @Binding var endTime: Date
  let sharedUserDefaults: UserDefaults
  
  @State private var clockRotation: Double = 0
  
  var body: some View {
    VStack(spacing: 0) {
      Spacer()
      
      // Animated clock icon
      Image(systemName: "clock.fill")
        .font(.system(size: 100))
        .foregroundStyle(.blue)
        .rotationEffect(.degrees(clockRotation))
        .onAppear {
          withAnimation(.linear(duration: 8.0).repeatForever(autoreverses: false)) {
            clockRotation = 360
          }
        }
        .padding(.bottom, 60)
      
      Text("When does your\nday begin and end?")
        .font(.system(size: 34, weight: .bold))
        .multilineTextAlignment(.center)
        .lineLimit(2)
        .minimumScaleFactor(0.8)
        .padding(.horizontal, 40)
        .padding(.bottom, 8)
      
      Text("Set your typical waking hours")
        .font(.body)
        .foregroundStyle(.secondary)
        .padding(.bottom, 40)
      
      VStack(spacing: 16) {
        DatePicker("Start of day", selection: $startTime, displayedComponents: .hourAndMinute)
          .datePickerStyle(.compact)
          .onChange(of: startTime) { _, newValue in
            sharedUserDefaults.set(DateStrings.string(from: newValue), forKey: "startTimeStr")
            WidgetCenter.shared.reloadAllTimelines()
          }
        
        DatePicker("End of day", selection: $endTime, displayedComponents: .hourAndMinute)
          .datePickerStyle(.compact)
          .onChange(of: endTime) { _, newValue in
            sharedUserDefaults.set(DateStrings.string(from: newValue), forKey: "endTimeStr")
            WidgetCenter.shared.reloadAllTimelines()
          }
        
        if let wakingMinutes = DateStrings.clockwiseDistance(from: startTime, to: endTime),
           wakingMinutes > 0 {
          let hours = wakingMinutes / 60
          let minutes = wakingMinutes % 60
          
          HStack(spacing: 4) {
            Image(systemName: "checkmark.circle.fill")
              .foregroundStyle(.green)
            if minutes > 0 {
              Text("\(hours)h \(minutes)m of waking time")
            } else {
              Text("\(hours) hours of waking time")
            }
          }
          .font(.subheadline)
          .foregroundStyle(.secondary)
          .padding(.top, 12)
        }
      }
      .padding(.horizontal, 40)
      
      Spacer()
    }
  }
}

// MARK: - Content 3: Stay Aware
struct StayAwareContent: View {
  @ObservedObject var notificationManager: NotificationManager
  @State private var bellBounce: Bool = false
  
  var body: some View {
    VStack(spacing: 0) {
      Spacer()
      
      // Animated notification bell
      Image(systemName: notificationManager.settings.enabled ? "bell.fill" : "bell.slash.fill")
        .font(.system(size: 100))
        .foregroundStyle(notificationManager.settings.enabled ? .purple : .gray)
        .symbolEffect(.bounce, value: bellBounce)
        .contentTransition(.symbolEffect(.replace))
        .onAppear {
          Task {
            while true {
              try? await Task.sleep(for: .seconds(2.5))
              bellBounce.toggle()
            }
          }
        }
        .padding(.bottom, 60)
      
      Text("Stay aware")
        .font(.system(size: 34, weight: .bold))
        .padding(.horizontal, 40)
        .padding(.bottom, 8)
      
      Text("Get a reminder when you're halfway through your day")
        .font(.body)
        .foregroundStyle(.secondary)
        .multilineTextAlignment(.center)
        .lineLimit(2)
        .minimumScaleFactor(0.9)
        .padding(.horizontal, 40)
        .padding(.bottom, 40)
      
      VStack(spacing: 16) {
        Toggle("Remind me at 50%", isOn: $notificationManager.settings.enabled)
          .onChange(of: notificationManager.settings.enabled) { oldValue, newValue in
            if newValue && !oldValue {
              Task {
                let granted = await notificationManager.requestPermission()
                if granted {
                  notificationManager.settings.thresholds.insert(50)
                } else {
                  notificationManager.settings.enabled = false
                }
              }
            } else if !newValue {
              notificationManager.settings.thresholds.remove(50)
            }
          }
        
        if notificationManager.settings.enabled {
          Text("You can add more milestones in Settings")
            .font(.caption)
            .foregroundStyle(.secondary)
            .multilineTextAlignment(.center)
        } else {
          Text("You can always enable this later in Settings")
            .font(.caption)
            .foregroundStyle(.secondary)
            .multilineTextAlignment(.center)
        }
      }
      .padding(.horizontal, 40)
      
      Spacer()
    }
  }
}

#Preview {
  OnboardingView()
}
