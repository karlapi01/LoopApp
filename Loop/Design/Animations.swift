//
//  Animations.swift
//  RunningApp
//
//  Created by Karla Pisonic on 27.05.2026..
//

import SwiftUI

struct StaggeredText: View {
    let words: [String]
    var size: CGFloat = 38
    var weight: Font.Weight = .black
    var color: Color = DS.Color.textPrimary
    var stagger: Double = 0.07

    @State private var revealed: [Bool] = []

    var body: some View {
        FlowLayout(spacing: 8) {
            ForEach(Array(words.enumerated()), id: \.offset) { i, word in
                Text(word)
                    .font(.system(size: size, weight: weight))
                    .foregroundStyle(color)
                    .opacity(safeRevealed(i) ? 1 : 0)
                    .offset(y: safeRevealed(i) ? 0 : 14)
                    .animation(
                        .spring(response: 0.4, dampingFraction: 0.75)
                            .delay(Double(i) * stagger),
                        value: safeRevealed(i)
                    )
            }
        }
        .onAppear {
            revealed = Array(repeating: false, count: words.count)
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                revealed = Array(repeating: true, count: words.count)
            }
        }
    }

    private func safeRevealed(_ i: Int) -> Bool {
        guard i < revealed.count else { return false }
        return revealed[i]
    }
}

struct FlowLayout: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let maxWidth = proposal.width ?? .infinity
        var x: CGFloat = 0
        var y: CGFloat = 0
        var lineHeight: CGFloat = 0
        var totalHeight: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if x + size.width > maxWidth, x > 0 {
                y += lineHeight + spacing
                totalHeight = y
                x = 0
                lineHeight = 0
            }
            x += size.width + spacing
            lineHeight = max(lineHeight, size.height)
        }
        totalHeight += lineHeight
        return CGSize(width: maxWidth, height: totalHeight)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let maxWidth = bounds.width
        var x: CGFloat = bounds.minX
        var y: CGFloat = bounds.minY
        var lineHeight: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if x + size.width > bounds.maxX, x > bounds.minX {
                y += lineHeight + spacing
                x = bounds.minX
                lineHeight = 0
            }
            subview.place(at: CGPoint(x: x, y: y), proposal: .unspecified)
            x += size.width + spacing
            lineHeight = max(lineHeight, size.height)
        }
    }
}

struct CountingNumber: View {
    let target: Double
    var unit: String = ""
    var decimals: Int = 0
    var size: CGFloat = 22
    var weight: Font.Weight = .bold
    var color: Color = DS.Color.textPrimary
    var duration: Double = 0.8

    @State private var displayed: Double = 0

    var body: some View {
        HStack(alignment: .lastTextBaseline, spacing: 3) {
            Text(formatted(displayed))
                .font(.system(size: size, weight: weight, design: .rounded))
                .foregroundStyle(color)
                .contentTransition(.numericText(countsDown: false))
                .animation(.easeOut(duration: duration), value: displayed)
            if !unit.isEmpty {
                Text(unit)
                    .font(.system(size: size * 0.5, weight: .medium, design: .rounded))
                    .foregroundStyle(DS.Color.textSecondary)
            }
        }
        .onAppear {
            displayed = target
        }
        .onChange(of: target) { _, new in
            withAnimation(.easeOut(duration: duration)) { displayed = new }
        }
    }

    private func formatted(_ v: Double) -> String {
        if decimals == 0 {
            return String(Int(v))
        }
        return String(format: "%.\(decimals)f", v)
    }
}

struct GlitchEffect: ViewModifier {
    var trigger: Bool
    var color: Color = DS.Color.terra

    @State private var offsetX: CGFloat = 0
    @State private var opacity: Double = 0

    func body(content: Content) -> some View {
        content
            .overlay(
                content
                    .foregroundStyle(color)
                    .offset(x: offsetX, y: -2)
                    .opacity(opacity)
                    .allowsHitTesting(false)
                    .blendMode(.multiply)
            )
            .onChange(of: trigger) { _, _ in fireGlitch() }
    }

    private func fireGlitch() {
        let steps: [(CGFloat, Double, Double)] = [
            (4,  0.6, 0.00),
            (-3, 0.4, 0.06),
            (6,  0.5, 0.10),
            (0,  0.0, 0.16),
        ]
        for (ox, op, delay) in steps {
            DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                withAnimation(.linear(duration: 0.04)) {
                    offsetX = ox
                    opacity  = op
                }
            }
        }
    }
}

extension View {
    func glitchEffect(trigger: Bool, color: Color = DS.Color.terra) -> some View {
        modifier(GlitchEffect(trigger: trigger, color: color))
    }
}

struct ScrollReveal: ViewModifier {
    var delay: Double = 0

    @State private var visible = false

    func body(content: Content) -> some View {
        content
            .opacity(visible ? 1 : 0)
            .offset(y: visible ? 0 : 22)
            .animation(
                .spring(response: 0.45, dampingFraction: 0.8).delay(delay),
                value: visible
            )
            .onAppear {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.01) {
                    visible = true
                }
            }
            .onDisappear { visible = false }
    }
}

extension View {
    func scrollReveal(delay: Double = 0) -> some View {
        modifier(ScrollReveal(delay: delay))
    }
}

struct AmbientPulse: ViewModifier {
    var minOpacity: Double = 0.35
    var maxOpacity: Double = 0.65
    var period: Double = 2.8

    @State private var phase = false

    func body(content: Content) -> some View {
        content
            .opacity(phase ? maxOpacity : minOpacity)
            .animation(
                .easeInOut(duration: period / 2).repeatForever(autoreverses: true),
                value: phase
            )
            .onAppear {
                phase = true
            }
    }
}

extension View {
    func ambientPulse(min: Double = 0.35, max: Double = 0.65, period: Double = 2.8) -> some View {
        modifier(AmbientPulse(minOpacity: min, maxOpacity: max, period: period))
    }
}

extension AnyTransition {
    static var mechanicalPush: AnyTransition {
        .asymmetric(
            insertion: .move(edge: .bottom).combined(with: .opacity),
            removal:   .move(edge: .top).combined(with: .opacity)
        )
    }
}

struct ScanLine: ViewModifier {
    @State private var yOffset: CGFloat = -UIScreen.main.bounds.height / 2
    @State private var opacity: Double = 0

    func body(content: Content) -> some View {
        content.overlay(
            GeometryReader { geo in
                Rectangle()
                    .fill(
                        LinearGradient(
                            colors: [.clear, DS.Color.accent.opacity(0.35), .clear],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .frame(height: 60)
                    .offset(y: yOffset + geo.size.height / 2)
                    .opacity(opacity)
                    .allowsHitTesting(false)
            }
        )
        .onAppear {
            opacity = 1
            withAnimation(.linear(duration: 0.7)) {
                yOffset = UIScreen.main.bounds.height / 2 + 60
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.75) {
                withAnimation(.linear(duration: 0.15)) {
                    opacity = 0
                }
            }
        }
    }
}

extension View {
    func scanOnAppear() -> some View {
        modifier(ScanLine())
    }
}
