//
//  LoopApp.swift
//  Loop
//
//  Created by Karla Pisonic on 22.05.2026..
//

import SwiftUI
import SwiftData

@main
struct LoopApp: App {
    @AppStorage("hasUnlocked") private var hasUnlocked = false
    @AppStorage("activeProfileID") private var activeProfileID = ""
    
    var body: some Scene {
        WindowGroup {
            if hasUnlocked && !activeProfileID.isEmpty {
                MainTabView()
            } else {
                EntryFlowView()
            }
        }
        .modelContainer(for: [Activity.self, Profile.self])
    }
}
