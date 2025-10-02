import Foundation
import EventKit
@testable import RemindianCore

public class MockRemindersManager: RemindersManager {
    public var reminderLists: [String: [String: String]] = [:]  // listName -> [id: title]
    public var completionStatus: [String: Bool] = [:]   // id -> isCompleted (public for testing)
    
    public override init() {
        super.init()
    }
    
    public override func requestAccess() async -> Bool {
        return true
    }
    
    // This method simulates EKCalendars by returning nil for MockRemindersManager
    public override func getReminderLists() -> [EKCalendar] {
        return []
    }
    
    public override func getReminderList(named name: String) -> EKCalendar? {
        return nil
    }
    
    public override func ensureReminderList(named name: String) -> EKCalendar? {
        if reminderLists[name] == nil {
            reminderLists[name] = [:]
        }
        return nil
    }
    
    public override func createReminder(title: String, in listName: String) -> String? {
        if reminderLists[listName] == nil {
            reminderLists[listName] = [:]
        }
        
        let id = "MOCK-\(UUID().uuidString)"
        reminderLists[listName]?[id] = title
        completionStatus[id] = false
        
        return id
    }
    
    public override func getReminder(byId identifier: String) -> EKReminder? {
        // For testing purposes, create a minimal mock EKReminder if the ID exists
        for (_, reminders) in reminderLists {
            if reminders[identifier] != nil {
                // In this mock, we're returning a non-nil value to indicate the reminder exists
                // The actual class doesn't matter since we're only checking for nil or not
                return EKReminder(eventStore: EKEventStore())
            }
        }
        return nil
    }
    
    public override func updateReminder(id: String, title: String, isCompleted: Bool) -> Bool {
        for (listName, _) in reminderLists {
            if reminderLists[listName]?[id] != nil {
                reminderLists[listName]?[id] = title
                completionStatus[id] = isCompleted
                return true
            }
        }
        return false
    }
    
    public override func deleteReminder(id: String) -> Bool {
        for (listName, _) in reminderLists {
            if reminderLists[listName]?.removeValue(forKey: id) != nil {
                completionStatus.removeValue(forKey: id)
                return true
            }
        }
        return false
    }
    
    // Helper methods for testing
    public func getReminderTitle(id: String) -> String? {
        for (_, reminders) in reminderLists {
            if let title = reminders[id] {
                return title
            }
        }
        return nil
    }
    
    public override func isReminderCompleted(id: String) -> Bool {
        return completionStatus[id] ?? false
    }
    
    public func getReminderListName(id: String) -> String? {
        for (listName, reminders) in reminderLists {
            if reminders[id] != nil {
                return listName
            }
        }
        return nil
    }
}