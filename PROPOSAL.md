# Continuum Technical Specification

**Version:** 2.0
**Date:** December 2024
**Status:** Draft

---

## 1. Executive Summary

Continuum is a minimalist iOS utility that helps users visualize how much time remains in their waking day, promoting intentional use of free time. This specification defines the evolution from the current MVP (widgets + basic settings) to a polished, multi-platform experience with journaling, notifications, and Shortcuts integration.

### Core Philosophy
- **Deliberate simplicity**: Single schedule, no time categorization, emotionally neutral
- **Passive awareness**: Users glance when they want; app doesn't demand attention
- **System native**: Standard iOS design language, minimal visual branding
- **Free forever**: No monetization, no paywalls

---

## 2. Platform Support

| Platform | Form Factor | Priority |
|----------|-------------|----------|
| iPhone | Main app + widgets | Phase 1 |
| iPad | Sidebar navigation layout | Phase 1 |
| Apple Watch | Complications only (circular, corner, inline) | Phase 2 |
| macOS | Native menu bar app | Phase 2 |

---

## 3. Feature Specifications

### 3.1 Core Time Display (Existing, Enhanced)

#### Day Mode
- Display percentage of waking hours remaining
- Show countdown to end-of-day
- Sun icon indicator

#### Night Mode (Simplified)
**Change from current:** Replace sleep progress percentage with minimal UI.

- Display: "Your day begins in X hours"
- Moon icon indicator
- No percentage tracking during sleep hours
- Static, calm presentation

#### Widgets
No customization options. Consistent experience across all users.

**Supported families:**
- `.systemSmall` (Home Screen)
- `.accessoryCircular` (Lock Screen)

---

### 3.2 Milestone Notifications (New)

Optional notifications at configurable thresholds.

#### Available Thresholds
Users toggle which milestones they want:
- 90% remaining
- 75% remaining
- 50% remaining
- 25% remaining
- 10% remaining

#### Data Model

```swift
struct NotificationSettings: Codable {
    var enabled: Bool = false
    var thresholds: Set<Int> = [] // e.g., [90, 50, 25]
}
```

#### Implementation Notes
- Use `UNUserNotificationCenter` for local notifications
- Calculate notification fire times based on start/end times
- Reschedule when settings change
- Notification content: "{X}% of your day remaining" (neutral tone)
- Badge: None (passive, non-urgent)

#### Technical Considerations
- Maximum of 64 pending local notifications (iOS limit)
- Recalculate daily at midnight or on schedule change
- Handle timezone changes

---

### 3.3 Personal Journal (New)

Freeform text journaling with calendar-based browsing.

#### Entry Model

```swift
struct JournalEntry: Codable, Identifiable {
    let id: UUID
    let date: Date // Calendar day (normalized to midnight)
    let createdAt: Date
    var updatedAt: Date
    var content: String // Plain text, no formatting
}
```

#### User Flows

**Creating an entry:**
1. User opens app
2. Taps "Journal" tab/section
3. Today's entry shown (or empty state)
4. Types freely in text view
5. Auto-saves on background/dismiss

**Browsing history:**
1. Calendar view shows days with entries (dot indicator)
2. Tap date to view/edit that day's entry
3. Scroll through months
4. One entry per calendar day maximum

#### UI Components

```swift
struct JournalView: View {
    // Calendar grid (similar to CalendarKit or custom)
    // Entry detail view (TextEditor)
    // Empty state for days without entries
}
```

#### Storage
- Primary: CloudKit (CKRecord)
- Local cache: SwiftData (iOS 17+)
- Sync: Automatic via CloudKit

---

### 3.4 iCloud Sync (New)

Sync journal entries and settings across devices.

#### CloudKit Schema

**Record Type: `JournalEntry`**
| Field | Type |
|-------|------|
| `id` | String (UUID) |
| `date` | Date |
| `createdAt` | Date |
| `updatedAt` | Date |
| `content` | String |

**Record Type: `Settings`**
| Field | Type |
|-------|------|
| `startTime` | String (HH:mm) |
| `endTime` | String (HH:mm) |
| `notificationsEnabled` | Int (0/1) |
| `notificationThresholds` | List<Int> |

#### Sync Strategy
- Use `CKSyncEngine` (iOS 17+) for automatic sync
- Conflict resolution: Last-write-wins based on `updatedAt`
- Offline support: Local SwiftData acts as source of truth
- Sync on app launch, background fetch, and settings change

#### Container
- Container ID: `iCloud.systems.weekend.continuum`
- Zone: Private database, default zone

---

### 3.5 Interactive Tutorials (Replacing Guides)

Replace text-based widget guides with TipKit-powered interactive tutorials.

#### Tips to Implement

```swift
struct HomeScreenWidgetTip: Tip {
    var title: Text { Text("Add to Home Screen") }
    var message: Text? { Text("Long-press your home screen, tap +, and search for Continuum.") }
    var image: Image? { Image(systemName: "plus.square.on.square") }
}

struct LockScreenWidgetTip: Tip {
    var title: Text { Text("Add to Lock Screen") }
    var message: Text? { Text("Long-press your lock screen, tap Customize, and add Continuum.") }
    var image: Image? { Image(systemName: "lock.circle") }
}
```

#### Behavior
- Show on first launch
- Dismiss permanently after user interacts
- Respect TipKit's built-in rate limiting
- No manual "show guide" buttons in settings

#### TipKit Configuration

```swift
try? Tips.configure([
    .displayFrequency(.immediate),
    .datastoreLocation(.applicationDefault)
])
```

---

### 3.6 Shortcuts Integration (New)

Read-only Shortcuts actions.

#### Actions

**Get Time Remaining**
```swift
struct GetTimeRemainingIntent: AppIntent {
    static var title: LocalizedStringResource = "Get Time Remaining"
    static var description = IntentDescription("Returns the percentage of waking day remaining.")

    func perform() async throws -> some IntentResult & ReturnsValue<Int> {
        let progress = calculateProgress()
        return .result(value: 100 - progress)
    }
}
```

**Get Today's Journal Entry**
```swift
struct GetJournalEntryIntent: AppIntent {
    static var title: LocalizedStringResource = "Get Today's Journal"
    static var description = IntentDescription("Returns today's journal entry text, if any.")

    func perform() async throws -> some IntentResult & ReturnsValue<String?> {
        let entry = fetchTodayEntry()
        return .result(value: entry?.content)
    }
}
```

#### App Shortcuts (Siri)
```swift
struct ContinuumShortcuts: AppShortcutsProvider {
    static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: GetTimeRemainingIntent(),
            phrases: ["How much time left in \(.applicationName)"],
            shortTitle: "Time Remaining",
            systemImageName: "clock"
        )
    }
}
```

---

### 3.7 Apple Watch Complications (New)

Watch-only extension with complications. No standalone app.

#### Supported Families
- `.accessoryCircular` - Gauge with percentage
- `.accessoryCorner` - Curved gauge with text
- `.accessoryInline` - Text only: "42% remaining"

#### Data Flow
- Watch app reads from shared UserDefaults (app group)
- WatchConnectivity for initial sync of settings
- Complications use TimelineProvider pattern (same as widgets)

#### Implementation

```swift
struct WatchComplicationProvider: TimelineProvider {
    func timeline(for complication: CLKComplication,
                  withHandler handler: @escaping (CLKComplicationTimeline<CLKComplicationTemplate>?) -> Void) {
        // Generate 24 hours of entries
        // Similar logic to iOS widget provider
    }
}
```

---

### 3.8 Mac Menu Bar App (New)

Native macOS menu bar utility.

#### Features
- Menu bar icon showing percentage (text or circular indicator)
- Click to reveal popover with:
  - Time remaining display
  - Quick journal entry for today
  - Settings access
- Native SwiftUI for macOS

#### Architecture
- Separate macOS target (not Catalyst)
- Shared SwiftUI views where possible
- Menu bar via `MenuBarExtra` (macOS 13+)

```swift
@main
struct ContinuumMacApp: App {
    var body: some Scene {
        MenuBarExtra("Continuum", systemImage: "clock") {
            MenuBarView()
        }
        .menuBarExtraStyle(.window)

        Settings {
            SettingsView()
        }
    }
}
```

#### Data Sync
- Same iCloud container as iOS
- CloudKit sync works automatically
- Settings and journal shared across platforms

---

### 3.9 iPad Layout (Enhanced)

Sidebar navigation for iPad.

#### Structure

```swift
struct iPadContentView: View {
    @State private var selection: NavigationItem? = .today

    var body: some View {
        NavigationSplitView {
            List(selection: $selection) {
                Label("Today", systemImage: "clock")
                    .tag(NavigationItem.today)
                Label("Journal", systemImage: "book")
                    .tag(NavigationItem.journal)
                Label("Settings", systemImage: "gear")
                    .tag(NavigationItem.settings)
            }
        } detail: {
            switch selection {
            case .today: TodayView()
            case .journal: JournalCalendarView()
            case .settings: SettingsView()
            case nil: Text("Select an item")
            }
        }
    }
}
```

#### Adaptive Layout
- Use `@Environment(\.horizontalSizeClass)` to switch layouts
- iPhone: Tab-based or single-column navigation
- iPad: Sidebar with detail view

---

## 4. Data Architecture

### 4.1 Local Storage

**SwiftData Models (iOS 17+)**

```swift
@Model
class PersistedJournalEntry {
    @Attribute(.unique) var id: UUID
    var date: Date
    var createdAt: Date
    var updatedAt: Date
    var content: String
    var syncStatus: SyncStatus
}

enum SyncStatus: Int, Codable {
    case synced
    case pendingUpload
    case pendingDeletion
}
```

**UserDefaults (Shared via App Group)**

```swift
extension UserDefaults {
    static let shared = UserDefaults(suiteName: "group.systems.weekend.continuum")!

    var startTime: String {
        get { string(forKey: "startTimeStr") ?? "09:00" }
        set { set(newValue, forKey: "startTimeStr") }
    }

    var endTime: String {
        get { string(forKey: "endTimeStr") ?? "23:00" }
        set { set(newValue, forKey: "endTimeStr") }
    }

    var notificationSettings: NotificationSettings {
        get { /* decode from data */ }
        set { /* encode to data */ }
    }
}
```

### 4.2 CloudKit Integration

**Setup Requirements**
1. Enable CloudKit capability in Xcode
2. Create container: `iCloud.systems.weekend.continuum`
3. Define record types in CloudKit Dashboard
4. Add `CKSyncEngine` for iOS 17+ sync

**Sync Flow**

```
┌─────────────┐     ┌─────────────┐     ┌─────────────┐
│  SwiftData  │────▶│ CKSyncEngine│────▶│  CloudKit   │
│   (Local)   │◀────│   (Sync)    │◀────│  (Remote)   │
└─────────────┘     └─────────────┘     └─────────────┘
```

---

## 5. Project Structure

```
Continuum/
├── Continuum/                      # Main iOS app
│   ├── App/
│   │   ├── ContinuumApp.swift
│   │   └── AppDelegate.swift       # (if needed for notifications)
│   ├── Views/
│   │   ├── ContentView.swift       # Adaptive root view
│   │   ├── TodayView.swift         # Time display
│   │   ├── JournalView.swift       # Journal calendar + editor
│   │   └── SettingsView.swift      # Configuration
│   ├── Models/
│   │   ├── JournalEntry.swift
│   │   └── NotificationSettings.swift
│   ├── Services/
│   │   ├── TimeCalculator.swift    # Day/night progress logic
│   │   ├── NotificationManager.swift
│   │   └── SyncEngine.swift        # CloudKit wrapper
│   └── Intents/
│       └── AppIntents.swift        # Shortcuts actions
├── Widget/                         # iOS widgets
│   ├── WidgetProvider.swift
│   ├── WidgetViews.swift
│   └── WidgetBundle.swift
├── WatchWidget/                    # watchOS complications
│   ├── ComplicationProvider.swift
│   └── ComplicationViews.swift
├── ContinuumMac/                   # macOS menu bar app
│   ├── ContinuumMacApp.swift
│   ├── MenuBarView.swift
│   └── SettingsView.swift
├── Shared/                         # Cross-platform code
│   ├── DateStrings.swift
│   ├── TimeCalculations.swift
│   └── CloudKitModels.swift
└── Tests/
    ├── TimeCalculationTests.swift
    └── SyncTests.swift
```

---

## 6. Development Phases

### Phase 1: Polish (Priority)
1. **TipKit tutorials** - Replace text guides with interactive tips
2. **Milestone notifications** - Fixed thresholds with toggle UI
3. **Night mode simplification** - "Day begins in X hours" display
4. **iPad sidebar layout** - Adaptive navigation

**Estimated scope:** ~15-20 files modified/added

### Phase 2: Journal + Sync
1. **Journal data model** - SwiftData + CloudKit schema
2. **Calendar view** - Month grid with entry indicators
3. **Text editor** - Freeform entry with auto-save
4. **iCloud sync** - CKSyncEngine integration
5. **Shortcuts integration** - Read-only intents

**Estimated scope:** ~25-30 files modified/added

### Phase 3: Platform Expansion
1. **Apple Watch complications** - Three families
2. **macOS menu bar app** - Native target with popover
3. **Cross-device sync polish** - Edge cases, conflict handling

**Estimated scope:** ~20-25 files added (new targets)

---

## 7. Technical Requirements

### Minimum Deployment Targets
- iOS 17.0 (TipKit, SwiftData, CKSyncEngine)
- watchOS 10.0
- macOS 14.0

### Capabilities Required
- iCloud (CloudKit)
- App Groups
- Background Modes (background fetch for sync)
- Push Notifications (local notifications)

### Dependencies
- None external (pure Apple frameworks)

### Frameworks Used
- SwiftUI
- WidgetKit
- SwiftData
- CloudKit / CKSyncEngine
- TipKit
- AppIntents
- UserNotifications
- ClockKit (watchOS)

---

## 8. Testing Strategy

### Unit Tests
- Time calculations (day/night determination, progress percentage)
- Date parsing and formatting
- Notification scheduling logic

### Integration Tests
- CloudKit sync (record creation, updates, conflicts)
- Settings persistence across app/widget
- Shortcut intent execution

### UI Tests
- Journal entry creation and retrieval
- Settings changes propagating to widget
- iPad layout adaptation

### Manual Testing Checklist
- [ ] Widget updates correctly when settings change
- [ ] Notifications fire at correct times
- [ ] Journal syncs between iPhone and iPad
- [ ] Night mode displays correctly after end time
- [ ] Watch complications show accurate data
- [ ] Mac menu bar reflects current state

---

## 9. Privacy & Data Handling

### Data Collected
- Journal entries (user-generated text)
- Schedule preferences (start/end times)
- Notification settings

### Storage
- All data stored in user's private iCloud container
- Local cache via SwiftData (app sandbox)
- No analytics, no telemetry, no third-party services

### Export
- Future consideration: Export journal as plain text/JSON
- Not in current scope

---

## 10. Open Questions

1. **Journal entry length limit?** Recommend 10,000 characters max for CloudKit efficiency
2. **Watch complication refresh rate?** Limited by watchOS; may show stale data
3. **Mac app distribution?** App Store vs direct download
4. **Localization?** English only for initial release?

---

## Appendix A: Current Codebase Reference

| File | Lines | Purpose |
|------|-------|---------|
| `ContinuumApp.swift` | 17 | App entry point |
| `ContentView.swift` | 154 | Main settings UI |
| `Widget.swift` | 219 | Widget provider + views |
| `WidgetBundle.swift` | 16 | Widget bundle |
| `DateStrings.swift` | 143 | Date utilities |
| **Total** | **549** | |

---

## Appendix B: Settings Schema

```swift
// Complete settings structure for reference
struct AppSettings: Codable {
    var startTime: String = "09:00"
    var endTime: String = "23:00"
    var notifications: NotificationSettings = .init()
}

struct NotificationSettings: Codable {
    var enabled: Bool = false
    var thresholds: Set<Int> = []
}
```

---

*End of specification*
