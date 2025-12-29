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
  
  var body: some View {
    VStack(spacing: 0) {
      TabView(selection: $currentPage) {
        WelcomeScreen(currentPage: $currentPage)
          .tag(0)
        
        SetYourDayScreen(currentPage: $currentPage)
          .tag(1)
        
        StayAwareScreen(currentPage: $currentPage, onComplete: {
          completeOnboarding()
        })
          .tag(2)
      }
      .tabViewStyle(.page(indexDisplayMode: .never))
      
      // Custom page indicator
      HStack(spacing: 8) {
        ForEach(0..<3) { index in
          Circle()
            .fill(currentPage == index ? Color.primary : Color.secondary.opacity(0.3))
            .frame(width: 8, height: 8)
        }
      }
      .padding(.bottom, 50)
      .animation(.easeInOut, value: currentPage)
    }
    .interactiveDismissDisabled()
  }
  
  private func completeOnboarding() {
    let defaults = UserDefaults(suiteName: "group.systems.weekend.continuum")!
    defaults.set(true, forKey: "hasCompletedOnboarding")
    dismiss()
  }
}

// MARK: - Screen 1: Welcome
struct WelcomeScreen: View {
  @Binding var currentPage: Int
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
      Spacer()
      
      Button {
        withAnimation(.easeInOut(duration: 0.3)) {
          currentPage = 1
        }
      } label: {
        Text("Continue")
          .font(.headline)
          .foregroundStyle(.white)
          .frame(maxWidth: .infinity)
          .padding(.vertical, 16)
          .background(Color.accentColor)
          .clipShape(RoundedRectangle(cornerRadius: 14))
      }
      .padding(.horizontal, 40)
      .padding(.bottom, 20)
    }
  }
}

// MARK: - Screen 2: Set Your Day
struct SetYourDayScreen: View {
  @Binding var currentPage: Int
  
  let sharedUserDefaults = UserDefaults(suiteName: "group.systems.weekend.continuum")!
  
  @State private var startTime: Date
  @State private var endTime: Date
  @State private var clockRotation: Double = 0
  
  init(currentPage: Binding<Int>) {
    self._currentPage = currentPage
    
    let defaults = UserDefaults(suiteName: "group.systems.weekend.continuum")!
    let startTimeStr = defaults.string(forKey: "startTimeStr")
    let endTimeStr = defaults.string(forKey: "endTimeStr")
    
    _startTime = State(initialValue: DateStrings.date(from: startTimeStr, default: "09:00"))
    _endTime = State(initialValue: DateStrings.date(from: endTimeStr, default: "23:00"))
  }
  
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
      Spacer()
      
      HStack(spacing: 12) {
        Button {
          withAnimation(.easeInOut(duration: 0.3)) {
            currentPage = 0
          }
        } label: {
          Text("Back")
            .font(.headline)
            .foregroundStyle(.primary)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(Color.secondary.opacity(0.15))
            .clipShape(RoundedRectangle(cornerRadius: 14))
        }
        
        Button {
          withAnimation(.easeInOut(duration: 0.3)) {
            currentPage = 2
          }
        } label: {
          Text("Continue")
            .font(.headline)
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(Color.accentColor)
            .clipShape(RoundedRectangle(cornerRadius: 14))
        }
      }
      .padding(.horizontal, 40)
      .padding(.bottom, 20)
    }
  }
}

// MARK: - Screen 3: Stay Aware
struct StayAwareScreen: View {
  @Binding var currentPage: Int
  let onComplete: () -> Void
  
  @StateObject private var notificationManager = NotificationManager.shared
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
                  // Automatically enable the 50% notification
                  notificationManager.settings.thresholds.insert(50)
                } else {
                  notificationManager.settings.enabled = false
                }
              }
            } else if !newValue {
              // Remove the 50% notification when disabled
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
      Spacer()
      
      HStack(spacing: 12) {
        Button {
          withAnimation(.easeInOut(duration: 0.3)) {
            currentPage = 1
          }
        } label: {
          Text("Back")
            .font(.headline)
            .foregroundStyle(.primary)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(Color.secondary.opacity(0.15))
            .clipShape(RoundedRectangle(cornerRadius: 14))
        }
        
        Button {
          onComplete()
        } label: {
          Text("Get Started")
            .font(.headline)
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(Color.accentColor)
            .clipShape(RoundedRectangle(cornerRadius: 14))
        }
      }
      .padding(.horizontal, 40)
      .padding(.bottom, 20)
    }
  }
}

#Preview {
  OnboardingView()
}
