//
//  JournalView.swift
//  Continuum
//
//  Created by Claude on 29/12/2024.
//

import SwiftData
import SwiftUI

struct JournalView: View {
  @Environment(\.modelContext) private var modelContext
  @Query(sort: \JournalEntry.date, order: .reverse) private var allEntries: [JournalEntry]

  @State private var selectedDate: Date = Date()
  @State private var displayedMonth: Date = Date()
  @State private var showingEntrySheet = false
  @State private var editingEntry: JournalEntry?

  var body: some View {
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
        Text("Journal")
          .font(.headline)
      }
    }
    .sheet(isPresented: $showingEntrySheet) {
      EntryEditorSheet(
        selectedDate: selectedDate,
        entry: editingEntry
      )
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

struct CalendarGridView: View {
  @Binding var displayedMonth: Date
  @Binding var selectedDate: Date
  let entriesForMonth: [Date: Bool]

  private let calendar = Calendar.current
  private let daysOfWeek = ["S", "M", "T", "W", "T", "F", "S"]

  var body: some View {
    VStack(spacing: 12) {
      HStack {
        Button {
          withAnimation {
            displayedMonth = calendar.date(byAdding: .month, value: -1, to: displayedMonth) ?? displayedMonth
          }
        } label: {
          Image(systemName: "chevron.left")
        }

        Spacer()

        Text(monthYearString)
          .font(.headline)

        Spacer()

        Button {
          withAnimation {
            displayedMonth = calendar.date(byAdding: .month, value: 1, to: displayedMonth) ?? displayedMonth
          }
        } label: {
          Image(systemName: "chevron.right")
        }
      }
      .padding(.horizontal)

      LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 7), spacing: 8) {
        ForEach(daysOfWeek, id: \.self) { day in
          Text(day)
            .font(.caption)
            .foregroundStyle(.secondary)
        }

        ForEach(daysInMonth, id: \.self) { date in
          if let date = date {
            DayCell(
              date: date,
              isSelected: calendar.isDate(date, inSameDayAs: selectedDate),
              isToday: calendar.isDateInToday(date),
              hasEntry: entriesForMonth[calendar.startOfDay(for: date)] ?? false
            )
            .onTapGesture {
              selectedDate = date
            }
          } else {
            Text("")
              .frame(height: 36)
          }
        }
      }
      .padding(.horizontal)
    }
    .padding(.vertical)
  }

  private var monthYearString: String {
    let formatter = DateFormatter()
    formatter.dateFormat = "MMMM yyyy"
    return formatter.string(from: displayedMonth)
  }

  private var daysInMonth: [Date?] {
    let monthStart = calendar.date(from: calendar.dateComponents([.year, .month], from: displayedMonth))!
    let monthRange = calendar.range(of: .day, in: .month, for: monthStart)!

    let firstWeekday = calendar.component(.weekday, from: monthStart)
    let leadingSpaces = firstWeekday - calendar.firstWeekday

    var days: [Date?] = Array(repeating: nil, count: leadingSpaces)

    for day in monthRange {
      if let date = calendar.date(byAdding: .day, value: day - 1, to: monthStart) {
        days.append(date)
      }
    }

    return days
  }
}

struct DayCell: View {
  let date: Date
  let isSelected: Bool
  let isToday: Bool
  let hasEntry: Bool

  private let calendar = Calendar.current

  var body: some View {
    VStack(spacing: 2) {
      Text("\(calendar.component(.day, from: date))")
        .font(.system(.body, design: .rounded))
        .fontWeight(isToday ? .bold : .regular)
        .foregroundStyle(isSelected ? .white : (isToday ? .accentColor : .primary))
        .frame(width: 32, height: 32)
        .background {
          if isSelected {
            Circle()
              .fill(Color.accentColor)
          } else if isToday {
            Circle()
              .strokeBorder(Color.accentColor, lineWidth: 1)
          }
        }

      Circle()
        .fill(hasEntry ? Color.accentColor : Color.clear)
        .frame(width: 5, height: 5)
    }
    .frame(height: 44)
  }
}

struct EntriesListView: View {
  let selectedDate: Date
  let entries: [JournalEntry]
  let onAdd: () -> Void
  let onEdit: (JournalEntry) -> Void
  let onDelete: (JournalEntry) -> Void

  var body: some View {
    VStack(alignment: .leading, spacing: 0) {
      HStack {
        Text(dateString)
          .font(.title3)
          .fontWeight(.semibold)
          .foregroundStyle(.primary)

        Spacer()

        Button {
          onAdd()
        } label: {
          Image(systemName: "plus.circle.fill")
            .font(.title2)
            .foregroundStyle(Color.accentColor)
        }
      }
      .padding(.horizontal, 20)
      .padding(.vertical, 16)
      .background(Color(uiColor: .systemBackground))

      if entries.isEmpty {
        VStack(spacing: 16) {
          Spacer()
          
          Image(systemName: "square.and.pencil")
            .font(.system(size: 48))
            .foregroundStyle(.quaternary)

          Text("No entries")
            .font(.headline)
            .foregroundStyle(.secondary)
          
          Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
      } else {
        ScrollView {
          LazyVStack(spacing: 12) {
            ForEach(entries) { entry in
              EntryCard(
                entry: entry,
                onTap: { onEdit(entry) },
                onDelete: { onDelete(entry) }
              )
            }
          }
          .padding(20)
        }
      }
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
  }

  private var dateString: String {
    let formatter = DateFormatter()
    formatter.dateFormat = "EEEE, MMMM d"
    return formatter.string(from: selectedDate)
  }
}

struct EntryCard: View {
  let entry: JournalEntry
  let onTap: () -> Void
  let onDelete: () -> Void

  var body: some View {
    Button(action: onTap) {
      VStack(alignment: .leading, spacing: 0) {
        // Subtle time header
        Text(entry.displayTime)
          .font(.caption)
          .foregroundStyle(.tertiary)
          .padding(.bottom, 8)
        
        // Content - clean and readable
        Text(entry.content)
          .font(.body)
          .foregroundStyle(.primary)
          .lineLimit(4)
          .multilineTextAlignment(.leading)
          .frame(maxWidth: .infinity, alignment: .leading)
      }
      .padding(20)
      .frame(maxWidth: .infinity, alignment: .leading)
      .background(Color(uiColor: .secondarySystemGroupedBackground))
      .cornerRadius(12)
    }
    .buttonStyle(.plain)
    .contextMenu {
      Button(role: .destructive) {
        onDelete()
      } label: {
        Label("Delete", systemImage: "trash")
      }
    }
  }
}

struct EntryEditorSheet: View {
  @Environment(\.modelContext) private var modelContext
  @Environment(\.dismiss) private var dismiss

  let selectedDate: Date
  let entry: JournalEntry?

  @State private var content: String = ""
  @FocusState private var contentIsFocused: Bool

  var body: some View {
    NavigationStack {
      ZStack(alignment: .topLeading) {
        TextEditor(text: $content)
          .focused($contentIsFocused)
          .font(.body)
          .scrollContentBackground(.hidden)
        
        if content.isEmpty {
          Text("What's on your mind?")
            .font(.body)
            .foregroundStyle(.tertiary)
            .padding(.top, 8)
            .padding(.leading, 5)
            .allowsHitTesting(false)
        }
      }
      .padding(.horizontal, 20)
      .padding(.top, 8)
      .navigationBarTitleDisplayMode(.inline)
        .toolbar {
          ToolbarItem(placement: .principal) {
            VStack(spacing: 2) {
              Text(dateString)
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundStyle(.primary)
              Text(timeString)
                .font(.caption)
                .foregroundStyle(.secondary)
            }
          }
          
          ToolbarItem(placement: .cancellationAction) {
            Button("Cancel") {
              dismiss()
            }
          }

          ToolbarItem(placement: .confirmationAction) {
            Button("Save") {
              saveEntry()
              dismiss()
            }
            .fontWeight(.semibold)
            .disabled(content.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
          }
        }
        .onAppear {
          if let entry = entry {
            content = entry.content
          }
          contentIsFocused = true
        }
    }
  }
  
  private var dateString: String {
    let formatter = DateFormatter()
    formatter.dateFormat = "EEEE, MMM d"
    return formatter.string(from: selectedDate)
  }
  
  private var timeString: String {
    let formatter = DateFormatter()
    formatter.timeStyle = .short
    return formatter.string(from: Date())
  }

  private func saveEntry() {
    let trimmedContent = content.trimmingCharacters(in: .whitespacesAndNewlines)
    guard !trimmedContent.isEmpty else { return }

    if let entry = entry {
      entry.content = trimmedContent
      entry.updatedAt = Date()
    } else {
      let newEntry = JournalEntry(date: selectedDate, content: trimmedContent)
      modelContext.insert(newEntry)
    }
  }
}

#Preview {
  NavigationStack {
    JournalView()
  }
  .modelContainer(for: JournalEntry.self, inMemory: true)
}
