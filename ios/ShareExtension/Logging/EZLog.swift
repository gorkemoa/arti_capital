//
//  EZLog.swift
//  ShareExtension
//
//  Created on 30.10.2025.
//

import Foundation

/// Simple logger that stores timestamped messages in UserDefaults
final class EZLog {
    private static let key = "EZLogs"
    private static let maxEntries = 500
    private static let dateFormatter: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return formatter
    }()
    
    /// Add a log entry with current timestamp
    static func add(_ message: String) {
        let timestamp = dateFormatter.string(from: Date())
        let entry = "[\(timestamp)] \(message)"
        
        // Print to console
        print("[EZ] \(entry)")
        
        // Save to UserDefaults
        var logs = UserDefaults.standard.stringArray(forKey: key) ?? []
        logs.append(entry)
        
        // Trim to max entries (remove oldest if exceeded)
        if logs.count > maxEntries {
            logs.removeFirst(logs.count - maxEntries)
        }
        
        UserDefaults.standard.set(logs, forKey: key)
    }
    
    /// Get all logs as a single string
    static func all() -> String {
        let logs = UserDefaults.standard.stringArray(forKey: key) ?? []
        return logs.isEmpty ? "(boş)" : logs.joined(separator: "\n")
    }
    
    /// Clear all logs
    static func clear() {
        UserDefaults.standard.removeObject(forKey: key)
        print("[EZ] Logs cleared")
    }
}
