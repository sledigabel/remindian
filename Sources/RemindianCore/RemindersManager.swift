import Foundation
import EventKit

public class RemindersManager {
    private let eventStore = EKEventStore()
    private var isAuthorized = false
    
    public init() {}
    
    // Request access to the Reminders
    public func requestAccess() async -> Bool {
        if #available(macOS 14.0, *) {
            do {
                return try await eventStore.requestFullAccessToReminders()
            } catch {
                print("Error requesting reminders access: \(error)")
                return false
            }
        } else {
            // For older macOS versions
            return await withCheckedContinuation { continuation in
                eventStore.requestAccess(to: .reminder) { granted, error in
                    if let error = error {
                        print("Error requesting reminders access: \(error)")
                    }
                    self.isAuthorized = granted
                    continuation.resume(returning: granted)
                }
            }
        }
    }
    
    // Get all reminder lists
    public func getReminderLists() -> [EKCalendar] {
        return eventStore.calendars(for: .reminder)
    }
    
    // Get a specific reminder list by name
    public func getReminderList(named name: String) -> EKCalendar? {
        let lists = getReminderLists()
        return lists.first { $0.title == name }
    }
    
    // Create a reminder list if it doesn't exist
    public func ensureReminderList(named name: String) -> EKCalendar? {
        if let existingList = getReminderList(named: name) {
            return existingList
        }
        
        // Create a new list
        let newList = EKCalendar(for: .reminder, eventStore: eventStore)
        newList.title = name
        newList.source = eventStore.defaultCalendarForNewReminders()?.source
        
        do {
            try eventStore.saveCalendar(newList, commit: true)
            return newList
        } catch {
            print("Failed to create reminder list '\(name)': \(error)")
            return nil
        }
    }
    
    // Create a new reminder
    public func createReminder(title: String, in listName: String) -> String? {
        guard let list = ensureReminderList(named: listName) else {
            print("Failed to get or create list '\(listName)'")
            return nil
        }
        
        let reminder = EKReminder(eventStore: eventStore)
        reminder.title = title
        reminder.calendar = list
        
        do {
            try eventStore.save(reminder, commit: true)
            return reminder.calendarItemIdentifier
        } catch {
            print("Failed to create reminder: \(error)")
            return nil
        }
    }
    
    // Get a reminder by its identifier
    public func getReminder(byId identifier: String) -> EKReminder? {
        guard let reminder = try? eventStore.calendarItem(withIdentifier: identifier) as? EKReminder else {
            return nil
        }
        return reminder
    }
    
    // Check if a reminder is completed
    public func isReminderCompleted(id: String) -> Bool {
        guard let reminder = getReminder(byId: id) else {
            return false
        }
        return reminder.completionDate != nil
    }
    
    // Update a reminder
    public func updateReminder(id: String, title: String, isCompleted: Bool) -> Bool {
        guard let reminder = getReminder(byId: id) else {
            print("Reminder not found with ID: \(id)")
            return false
        }
        
        reminder.title = title
        
        if isCompleted {
            reminder.completionDate = Date()
        } else {
            reminder.completionDate = nil
        }
        
        do {
            try eventStore.save(reminder, commit: true)
            return true
        } catch {
            print("Failed to update reminder: \(error)")
            return false
        }
    }
    
    // Delete a reminder
    public func deleteReminder(id: String) -> Bool {
        guard let reminder = getReminder(byId: id) else {
            print("Reminder not found with ID: \(id)")
            return false
        }
        
        do {
            try eventStore.remove(reminder, commit: true)
            return true
        } catch {
            print("Failed to delete reminder: \(error)")
            return false
        }
    }
}