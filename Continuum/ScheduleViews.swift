//
//  ScheduleViews.swift
//  Continuum
//

import SwiftUI

struct ScheduleItemCard: View {
  let item: ScheduleItem
  let wakingMinutes: Int
  let onEdit: () -> Void
  let onDelete: () -> Void
  
  var body: some View {
    HStack(alignment: .center, spacing: 12) {
      VStack(alignment: .leading, spacing: 2) {
        Text(item.name)
          .font(.subheadline)
          .fontWeight(.medium)
          .foregroundStyle(.primary)
        
        Text(item.displayTimeInfo)
          .font(.caption)
          .foregroundStyle(.secondary)
      }
      
      Spacer()
      
      VStack(alignment: .trailing, spacing: 1) {
        Text("\(item.percentageOfWakingHours(wakingMinutes: wakingMinutes))%")
          .font(.system(size: 20, weight: .semibold, design: .rounded))
          .foregroundStyle(.primary)
        
        Text("of your day")
          .font(.caption2)
          .foregroundStyle(.secondary)
      }
      
      Image(systemName: "line.3.horizontal")
        .font(.system(size: 12))
        .foregroundStyle(.tertiary)
    }
    .padding(12)
    .background(Color(uiColor: .secondarySystemGroupedBackground))
    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
    .contentShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
    .contextMenu {
      Button {
        onEdit()
      } label: {
        Label("Edit", systemImage: "pencil")
      }
      
      Button(role: .destructive) {
        onDelete()
      } label: {
        Label("Delete", systemImage: "trash")
      }
    }
  }
}

struct ScheduleSection: View {
  @ObservedObject var scheduleManager: ScheduleManager
  let wakingMinutes: Int
  @Binding var showingAddSheet: Bool
  @Binding var editingItem: ScheduleItem?
  
  var body: some View {
    VStack(alignment: .leading, spacing: 12) {
      HStack {
        Text("Schedule")
          .font(.title3)
          .fontWeight(.semibold)
        
        Spacer()
        
        Button {
          editingItem = nil
          showingAddSheet = true
        } label: {
          Image(systemName: "plus")
            .font(.subheadline)
        }
      }
      .padding(.horizontal, 16)
      
      if scheduleManager.items.isEmpty {
        Button {
          editingItem = nil
          showingAddSheet = true
        } label: {
          HStack {
            Image(systemName: "calendar.badge.plus")
              .font(.title2)
              .foregroundStyle(.secondary)
            
            VStack(alignment: .leading, spacing: 2) {
              Text("No schedule items")
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundStyle(.primary)
              
              Text("Tap to add your first item")
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
        List {
          ForEach(scheduleManager.items) { item in
            ScheduleItemCard(
              item: item,
              wakingMinutes: wakingMinutes,
              onEdit: {
                editingItem = item
                showingAddSheet = true
              },
              onDelete: {
                withAnimation {
                  scheduleManager.deleteItem(item)
                }
              }
            )
            .listRowInsets(EdgeInsets(top: 4, leading: 16, bottom: 4, trailing: 16))
            .listRowSeparator(.hidden)
            .listRowBackground(Color.clear)
          }
          .onDelete { indexSet in
            indexSet.forEach { index in
              scheduleManager.deleteItem(scheduleManager.items[index])
            }
          }
          .onMove { source, destination in
            scheduleManager.moveItem(from: source, to: destination)
          }
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
        .scrollDisabled(true)
        .frame(minHeight: CGFloat(scheduleManager.items.count) * 70 + 8)
      }
    }
  }
}

struct AddEditScheduleSheet: View {
  @Environment(\.dismiss) private var dismiss
  @ObservedObject var scheduleManager: ScheduleManager
  
  let editingItem: ScheduleItem?
  
  @State private var name: String = ""
  @State private var itemType: ScheduleItemType = .duration
  @State private var startTime: Date = DateStrings.date(from: nil, default: "09:00")
  @State private var endTime: Date = DateStrings.date(from: nil, default: "17:00")
  @State private var durationHours: Int = 1
  @State private var durationMinutes: Int = 0
  
  private let quickAddSuggestions = ["Work", "Gym", "Commute", "Lunch", "Meeting", "Exercise", "Reading", "Study"]
  
  var body: some View {
    NavigationStack {
      Form {
        Section {
          TextField("Name", text: $name)
          
          if name.isEmpty {
            ScrollView(.horizontal, showsIndicators: false) {
              HStack(spacing: 8) {
                ForEach(quickAddSuggestions, id: \.self) { suggestion in
                  Button {
                    name = suggestion
                  } label: {
                    Text(suggestion)
                      .font(.subheadline)
                      .padding(.horizontal, 12)
                      .padding(.vertical, 6)
                      .background(Color(uiColor: .tertiarySystemGroupedBackground))
                      .cornerRadius(16)
                  }
                  .buttonStyle(.plain)
                }
              }
              .padding(.vertical, 4)
            }
          }
        } header: {
          Text("NAME")
        }
        
        Section {
          Picker("Type", selection: $itemType) {
            Text("Duration").tag(ScheduleItemType.duration)
            Text("Time Range").tag(ScheduleItemType.timeRange)
          }
          .pickerStyle(.segmented)
          .listRowBackground(Color.clear)
          .listRowInsets(EdgeInsets(top: 8, leading: 0, bottom: 8, trailing: 0))
        }
        
        if itemType == .timeRange {
          Section {
            DatePicker("Start", selection: $startTime, displayedComponents: .hourAndMinute)
            DatePicker("End", selection: $endTime, displayedComponents: .hourAndMinute)
          } header: {
            Text("TIME RANGE")
          }
        } else {
          Section {
            Picker("Hours", selection: $durationHours) {
              ForEach(0..<24, id: \.self) { hour in
                Text("\(hour)h").tag(hour)
              }
            }
            
            Picker("Minutes", selection: $durationMinutes) {
              ForEach(Array(stride(from: 0, to: 60, by: 5)), id: \.self) { minute in
                Text("\(minute)m").tag(minute)
              }
            }
          } header: {
            Text("DURATION")
          }
        }
      }
      .navigationTitle(editingItem == nil ? "Add Schedule Item" : "Edit Schedule Item")
      .navigationBarTitleDisplayMode(.inline)
      .toolbar {
        ToolbarItem(placement: .cancellationAction) {
          Button("Cancel") {
            dismiss()
          }
        }
        
        ToolbarItem(placement: .confirmationAction) {
          Button("Save") {
            saveItem()
            dismiss()
          }
          .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty || (itemType == .duration && durationHours == 0 && durationMinutes == 0))
        }
      }
      .onAppear {
        if let item = editingItem {
          name = item.name
          itemType = item.type
          if let start = item.startTimeStr {
            startTime = DateStrings.date(from: start, default: "09:00")
          }
          if let end = item.endTimeStr {
            endTime = DateStrings.date(from: end, default: "17:00")
          }
          if let mins = item.durationMinutes {
            durationHours = mins / 60
            durationMinutes = mins % 60
          }
        }
      }
    }
  }
  
  private func saveItem() {
    let trimmedName = name.trimmingCharacters(in: .whitespaces)
    
    if var existingItem = editingItem {
      existingItem.name = trimmedName
      existingItem.type = itemType
      if itemType == .timeRange {
        existingItem.startTimeStr = DateStrings.string(from: startTime)
        existingItem.endTimeStr = DateStrings.string(from: endTime)
        existingItem.durationMinutes = nil
      } else {
        existingItem.startTimeStr = nil
        existingItem.endTimeStr = nil
        existingItem.durationMinutes = durationHours * 60 + durationMinutes
      }
      scheduleManager.updateItem(existingItem)
    } else {
      let newItem: ScheduleItem
      if itemType == .timeRange {
        newItem = ScheduleItem(
          name: trimmedName,
          type: .timeRange,
          startTimeStr: DateStrings.string(from: startTime),
          endTimeStr: DateStrings.string(from: endTime)
        )
      } else {
        newItem = ScheduleItem(
          name: trimmedName,
          type: .duration,
          durationMinutes: durationHours * 60 + durationMinutes
        )
      }
      scheduleManager.addItem(newItem)
    }
  }
}
