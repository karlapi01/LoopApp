//
//  ColorHex.swift
//  RunningApp
//
//  Created by Karla Pisonic on 22.05.2026..
//

import SwiftUI

extension Color {
    init(hex: String) {
        let clean = hex.trimmingCharacters(in: .alphanumerics.inverted)
        var value: UInt64 = 0
        Scanner(string: clean).scanHexInt64(&value)
        let r = Double((value >> 16) & 0xFF) / 255
        let g = Double((value >> 8) & 0xFF) / 255
        let b = Double(value & 0xFF) / 255
        self.init(red: r, green: g, blue: b)
    }
}
