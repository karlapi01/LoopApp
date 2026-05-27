//
//  AccessCodes.swift
//  RunningApp
//
//  Created by Karla Pisonic on 22.05.2026..
//

import Foundation

enum AccessCodes {
    private static let validCodes: Set<String> = [
        "5678",
        "2345",
        "7896"
    ]
    
    static func isValid(_ raw: String) -> Bool {
        let cleaned = raw.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
        
        return validCodes.contains(cleaned)
    }
}
