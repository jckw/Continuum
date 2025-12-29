//
//  ContinuumApp.swift
//  Continuum
//
//  Created by Jack on 10/06/2023.
//

import SwiftData
import SwiftUI
import TipKit

@main
struct ContinuumApp: App {
  init() {
    try? Tips.configure([
      .displayFrequency(.immediate),
      .datastoreLocation(.applicationDefault)
    ])
  }

  var body: some Scene {
    WindowGroup {
      ContentView()
    }
    .modelContainer(for: JournalEntry.self)
  }
}
