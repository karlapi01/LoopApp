//
//  HomeView.swift
//  RunningApp
//
//  Created by Karla Pisonic on 22.05.2026..
//

import SwiftUI
import SwiftData
import MapKit

struct HomeView: View {
    @Environment(\.modelContext) private var context
    @AppStorage("activeProfileID") private var activeProfileID = ""

    @StateObject private var tracker = TrackingManager()
    @State private var camera: MapCameraPosition = .userLocation(fallback: .automatic)
    @State private var lastResultMessage: String?
    @State private var showResult = false
    @State private var glitchTrigger = false

    @Query private var profiles: [Profile]

    private var isIdle: Bool { tracker.state == .idle }

    private var activeColorHex: String? {
        profiles.first(where: { $0.id == activeProfileID })?.colorHex
    }

    var body: some View {
        ZStack {
            Map(position: $camera) {
                UserAnnotation()
                if tracker.route.count > 1 {
                    MapPolyline(coordinates: tracker.route)
                        .stroke(Color(hex: "D95F3B"), lineWidth: 4)
                    if let hex = activeColorHex {
                        MapPolygon(coordinates: tracker.route)
                            .foregroundStyle(Color(hex: hex).opacity(0.2))
                            .stroke(Color(hex: hex), lineWidth: 2)
                    }
                }
            }
            .mapControls { MapUserLocationButton() }
            .ignoresSafeArea()
            .blur(radius: isIdle ? 8 : 0)
            .overlay {
                if isIdle {
                    Color(hex: "FBF5E6").opacity(0.45).ignoresSafeArea()
                }
            }
            .animation(.easeInOut(duration: 0.4), value: isIdle)

            VStack(spacing: 0) {
                if isIdle { idleHeader }
                Spacer()
                if !isIdle {
                    statsBar
                        .padding(.bottom, 12)
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                }
                controlButtons.padding(.bottom, 8)
            }
            .padding(.horizontal, DS.Layout.pagePadding)
            .animation(.spring(response: 0.4, dampingFraction: 0.85), value: isIdle)
        }
        .scanOnAppear()
        .onAppear { tracker.requestPermission() }
        .alert("Run finished", isPresented: $showResult) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(lastResultMessage ?? "")
        }
    }

    private var idleHeader: some View {
        VStack(alignment: .leading, spacing: 10) {
            DS.Label.tag("ready")
                .scrollReveal(delay: 0.0)

            StaggeredText(
                words: ["Go", "run", "a", "loop."],
                size: 52,
                weight: .black,
                color: DS.Color.textPrimary,
                stagger: 0.08
            )

            Text("Return within \(Int(GeoMath.closureThreshold)) m of your start\nto claim the enclosed area.")
                .font(.system(size: 14, weight: .regular))
                .foregroundStyle(DS.Color.textSecondary)
                .lineSpacing(5)
                .scrollReveal(delay: 0.35)

            if !tracker.hasFix {
                HStack(spacing: 7) {
                    Circle()
                        .fill(DS.Color.terra)
                        .frame(width: 6, height: 6)
                        .ambientPulse(min: 0.3, max: 1.0, period: 1.4)
                    Text("ACQUIRING GPS…")
                        .font(.system(size: 10, weight: .semibold, design: .rounded))
                        .foregroundStyle(DS.Color.terra)
                        .tracking(0.5)
                        .ambientPulse(min: 0.5, max: 0.9, period: 1.4)
                }
                .scrollReveal(delay: 0.45)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.top, 72)
    }

    private var statsBar: some View {
        HStack(spacing: 0) {
            statCell(
                label: "DIST",
                value: String(format: "%.2f", tracker.totalDistance / 1000),
                unit: "km"
            )
            Rectangle().fill(DS.Color.rule).frame(width: 1, height: 36)
            statCell(
                label: "TIME",
                value: format(tracker.elapsedTime),
                unit: nil
            )
            Rectangle().fill(DS.Color.rule).frame(width: 1, height: 36)
            statCell(
                label: "AREA",
                value: liveAreaValue,
                unit: liveAreaUnit
            )
            .glitchEffect(trigger: glitchTrigger, color: DS.Color.terra)
        }
        .padding(.vertical, 18)
        .background(DS.Color.surface)
        .clipShape(RoundedRectangle(cornerRadius: DS.Layout.cornerRadius))
        .overlay(
            RoundedRectangle(cornerRadius: DS.Layout.cornerRadius)
                .stroke(DS.Color.rule, lineWidth: 1)
        )
        .shadow(color: DS.Color.accent.opacity(0.25), radius: 12, x: 0, y: 4)
    }

    private func statCell(label: String, value: String, unit: String?) -> some View {
        VStack(spacing: 5) {
            Text(label)
                .font(.system(size: 9, weight: .semibold, design: .rounded))
                .foregroundStyle(DS.Color.textSecondary)
                .tracking(0.8)
            HStack(alignment: .lastTextBaseline, spacing: 3) {
                Text(value)
                    .font(.system(size: 22, weight: .bold, design: .rounded))
                    .foregroundStyle(DS.Color.textPrimary)
                    .contentTransition(.numericText())
                    .animation(.easeOut(duration: 0.4), value: value)
                if let u = unit {
                    Text(u)
                        .font(.system(size: 10, weight: .medium, design: .rounded))
                        .foregroundStyle(DS.Color.textSecondary)
                }
            }
        }
        .frame(maxWidth: .infinity)
    }

    private var liveAreaValue: String {
        guard tracker.route.count >= 3 else { return "—" }
        let a = GeoMath.enclosedArea(tracker.route)
        if a >= 10_000 { return String(format: "%.2f", a / 10_000) }
        return String(format: "%.0f", a)
    }

    private var liveAreaUnit: String? {
        guard tracker.route.count >= 3 else { return nil }
        return GeoMath.enclosedArea(tracker.route) >= 10_000 ? "ha" : "m²"
    }

    private func format(_ t: TimeInterval) -> String {
        let m = Int(t) / 60, s = Int(t) % 60
        return String(format: "%d:%02d", m, s)
    }

    private var controlButtons: some View {
        HStack(spacing: 10) {
            switch tracker.state {
            case .idle:
                DSButton(title: "Start", color: DS.Color.accent) { tracker.start() }
                    .transition(.mechanicalPush)
            case .recording:
                DSButton(title: "Pause", filled: false, color: DS.Color.textSecondary) { tracker.pause() }
                    .transition(.mechanicalPush)
                DSButton(title: "Stop", color: DS.Color.terra) { stopAndSave() }
                    .transition(.mechanicalPush)
            case .paused:
                DSButton(title: "Resume", color: DS.Color.accent) { tracker.resume() }
                    .transition(.mechanicalPush)
                DSButton(title: "Stop", filled: false, color: DS.Color.terra) { stopAndSave() }
                    .transition(.mechanicalPush)
            }
        }
        .animation(.spring(response: 0.25, dampingFraction: 0.8), value: tracker.state)
    }

    private func stopAndSave() {
        tracker.stop()
        guard tracker.totalDistance > 5, tracker.route.count > 1 else {
            lastResultMessage = "That run was too short to save."
            showResult = true
            return
        }
        let activity = Activity(
            date: tracker.startDate ?? Date(),
            distance: tracker.totalDistance,
            duration: tracker.elapsedTime,
            coordinates: tracker.route,
            ownerProfileID: activeProfileID
        )
        context.insert(activity)
        if activity.isClosed {
            glitchTrigger.toggle()
            lastResultMessage = "Loop closed. You claimed \(activity.areaDisplay)."
        } else {
            lastResultMessage = "Saved as an open run — finish within \(Int(GeoMath.closureThreshold)) m of your start to claim territory."
        }
        showResult = true
    }
}
