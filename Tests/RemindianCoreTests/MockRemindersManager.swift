import Foundation
import EventKit
@testable import RemindianCore

public class MockRemindersManager: RemindersManager {
    private var reminderLists: [String: [String: String]] = [:]  // listName -> [id: title]
    private var reminderCompletionStatus: [String: Bool] = [:]   // id -> isCompleted
    
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
        reminderCompletionStatus[id] = false
        
        return id
    }
    
    public override func getReminder(byId identifier: String) -> EKReminder? {
        return nil  // We don't need to return actual EKReminder objects for testing
    }
    
    public override func updateReminder(id: String, title: String, isCompleted: Bool) -> Bool {
        for (listName, _) in reminderLists {
            if reminderLists[listName]?[id] != nil {
                reminderLists[listName]?[id] = title
                reminderCompletionStatus[id] = isCompleted
                return true
            }
        }
        return false
    }
    
    public override func deleteReminder(id: String) -> Bool {
        for (listName, _) in reminderLists {
            if reminderLists[listName]?.removeValue(forKey: id) != nil {
                reminderCompletionStatus.removeValue(forKey: id)
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
    
    public func isReminderCompleted(id: String) -> Bool? {
        return reminderCompletionStatus[id]
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