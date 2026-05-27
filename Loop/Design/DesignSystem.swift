//
//  DesignSystem.swift
//  RunningApp
//
//  Created by Karla Pisonic on 26.05.2026..
//

import SwiftUI

enum DS {
    
    enum Color {
        static let background = SwiftUI.Color(hex: "FBF5E6")
        static let surface = SwiftUI.Color(hex: "F5EDD6")
        static let surfaceLift = SwiftUI.Color(hex: "EDE3C8")
        static let rule = SwiftUI.Color(hex: "C8A96E").opacity(0.25)
        static let textPrimary = SwiftUI.Color(hex: "1E1208")
        static let textSecondary = SwiftUI.Color(hex: "8A6A3A")
        static let accent = SwiftUI.Color(hex: "F5C842")
        static let terra = SwiftUI.Color(hex: "D95F3B")
        static let destructive = SwiftUI.Color(hex: "D95F3B")
    }

    enum Label {
        static func tag(_ text: String) -> some View {
            Text(text.uppercased())
                .font(.system(size: 11, weight: .semibold, design: .rounded))
                .foregroundStyle(DS.Color.textSecondary)
                .tracking(1.5)
        }

        static func index(_ n: Int) -> some View {
            Text(String(format: "%02d.", n))
                .font(.system(size: 11, weight: .medium, design: .rounded))
                .foregroundStyle(DS.Color.textSecondary)
                .tracking(0.5)
        }
    }

    enum Layout {
        static let pagePadding: CGFloat   = 24
        static let cardPadding: CGFloat   = 18
        static let cornerRadius: CGFloat  = 14
        static let ruleHeight: CGFloat    = 0.5
    }
}

struct DSRule: View {
    var body: some View {
        Rectangle()
            .fill(DS.Color.rule)
            .frame(height: DS.Layout.ruleHeight)
    }
}

struct DSButton: View {
    let title: String
    var filled: Bool = true
    var color: SwiftUI.Color = DS.Color.accent
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title.uppercased())
                .font(.system(size: 13, weight: .bold, design: .rounded))
                .tracking(0.5)
                .foregroundStyle(filled ? DS.Color.textPrimary : color)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 17)
                .background(
                    filled
                    ? color
                    : color.opacity(0.12)
                )
                .clipShape(RoundedRectangle(cornerRadius: DS.Layout.cornerRadius))
                .overlay(
                    RoundedRectangle(cornerRadius: DS.Layout.cornerRadius)
                        .stroke(filled ? SwiftUI.Color.clear : color.opacity(0.5), lineWidth: 1)
                )
        }
    }
}


