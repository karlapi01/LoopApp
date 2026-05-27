//
//  MainTabView.swift
//  RunningApp
//
//  Created by Karla Pisonic on 22.05.2026..
//

import SwiftUI

struct MainTabView: View {

    init() {
        let appearance = UITabBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = UIColor(DS.Color.background)
        // Warm golden hairline above the tab bar
        appearance.shadowColor = UIColor(DS.Color.accent.opacity(0.4))

        let item = UITabBarItemAppearance()
        item.normal.titleTextAttributes = [
            .font: UIFont.systemFont(ofSize: 9, weight: .medium),
            .foregroundColor: UIColor(DS.Color.textSecondary)
        ]
        item.selected.titleTextAttributes = [
            .font: UIFont.systemFont(ofSize: 9, weight: .bold),
            .foregroundColor: UIColor(DS.Color.textPrimary)
        ]
        item.normal.iconColor  = UIColor(DS.Color.textSecondary)
        item.selected.iconColor = UIColor(DS.Color.textPrimary)
        appearance.stackedLayoutAppearance = item
        appearance.inlineLayoutAppearance = item
        appearance.compactInlineLayoutAppearance = item

        UITabBar.appearance().standardAppearance = appearance
        UITabBar.appearance().scrollEdgeAppearance = appearance
    }

    var body: some View {
        TabView {
            HomeView()
                .tabItem { Label("Record", systemImage: "figure.run") }
            UsersView()
                .tabItem { Label("Runners", systemImage: "person.2.fill") }
            HistoryView()
                .tabItem { Label("History", systemImage: "clock.arrow.circlepath") }
            LeaderboardView()
                .tabItem { Label("Leaderboard", systemImage: "flag.checkered") }
        }
        .preferredColorScheme(.light)
    }
}
