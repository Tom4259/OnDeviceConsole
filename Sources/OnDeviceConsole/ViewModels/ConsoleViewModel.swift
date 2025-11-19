//
//  ConsoleViewModel.swift
//  OnDeviceConsole
//
//  Created by Tom Redway on 19/11/2025.
//

import Foundation

struct ConsoleLog: Identifiable {
    
    let id = UUID()
    let message: String
    let timestamp: Date
    
    var formattedTime: String {
        
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm:ss.SSS"
        return formatter.string(from: timestamp)
    }
}


@Observable @MainActor public class ConsoleManager {
    
    static let shared = ConsoleManager()
    
    var logs: [ConsoleLog] = []
    
    private init() {}
    
    func addLog(_ message: String) {
        
        let log = ConsoleLog(message: message, timestamp: Date())
        logs.append(log)
    }
    
    func clearLogs() {
        
        logs.removeAll()
    }
}

// MARK: - Global Print Override
public func consolePrint(_ items: Any..., separator: String = " ", terminator: String = "\n") {
    
    let message = items.map { "\($0)" }.joined(separator: separator)
    
    Task { @MainActor in ConsoleManager.shared.addLog(message) }
    
    print(message, terminator: terminator)
}
