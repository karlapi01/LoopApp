//
//  LeaderboardView.swift
//  RunningApp
//
//  Created by Karla Pisonic on 26.05.2026..
//

import SwiftUI
import SwiftData
import MapKit

struct LeaderboardView: View {
    @Query(sort: \Profile.joinedDate) private var profiles: [Profile]
    @Query private var activities: [Activity]

    @State private var glitchTrigger = false
    @State private var numbersVisible = false

    private struct Standing: Identifiable {
        let id: String; let name: String; let colorHex: String
        let totalArea: Double; let loopCount: Int
    }

    private var standings: [Standing] {
        profiles.map { p in
            let owned = activities.filter { $0.ownerProfileID == p.id && $0.isClosed }
            return Standing(id: p.id, name: p.name, colorHex: p.colorHex,
                            totalArea: owned.reduce(0) { $0 + $1.area },
                            loopCount: owned.count)
        }.sorted { $0.totalArea > $1.totalArea }
    }

    private var closedActivities: [Activity] { activities.filter { $0.isClosed } }
    private var hasAnyTerritory: Bool { standings.contains { $0.totalArea > 0 } }

    private func colorHex(for id: String) -> String {
        profiles.first(where: { $0.id == id })?.colorHex ?? "F5C842"
    }

    var body: some View {
        ZStack {
            DS.Color.background.ignoresSafeArea()

            ScrollView {
                VStack(spacing: 0) {

                    VStack(alignment: .leading, spacing: 6) {
                        DS.Label.tag("contest")
                            .scrollReveal(delay: 0.0)
                        StaggeredText(
                            words: ["Territory."],
                            size: 38,
                            weight: .black,
                            color: DS.Color.textPrimary,
                            stagger: 0.07
                        )
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, DS.Layout.pagePadding)
                    .padding(.top, 60)
                    .padding(.bottom, 28)

                    if !closedActivities.isEmpty {
                        Map(initialPosition: .region(combinedRegion)) {
                            ForEach(closedActivities) { activity in
                                MapPolygon(coordinates: activity.coordinates)
                                    .foregroundStyle(Color(hex: colorHex(for: activity.ownerProfileID)).opacity(0.4))
                                    .stroke(Color(hex: colorHex(for: activity.ownerProfileID)), lineWidth: 2)
                            }
                        }
                        .frame(height: 220)
                        .clipShape(RoundedRectangle(cornerRadius: DS.Layout.cornerRadius))
                        // Butter-yellow glow under the map card
                        .shadow(color: DS.Color.accent.opacity(0.3), radius: 16, x: 0, y: 6)
                        .padding(.horizontal, DS.Layout.pagePadding)
                        .padding(.bottom, 28)
                        .scrollReveal(delay: 0.2)
                    }

                    HStack {
                        DS.Label.tag("runner")
                        Spacer()
                        DS.Label.tag("area claimed")
                    }
                    .padding(.horizontal, DS.Layout.pagePadding)
                    .padding(.bottom, 8)
                    .scrollReveal(delay: 0.15)

                    DSRule().padding(.horizontal, DS.Layout.pagePadding)

                    if !hasAnyTerritory {
                        VStack(spacing: 8) {
                            Text("No territory yet.")
                                .font(.system(size: 22, weight: .bold))
                                .foregroundStyle(DS.Color.textPrimary)
                                .ambientPulse(min: 0.5, max: 1.0, period: 2.5)
                            Text("Run a closed loop to claim your first area.")
                                .font(.system(size: 13))
                                .foregroundStyle(DS.Color.textSecondary)
                                .ambientPulse(min: 0.3, max: 0.6, period: 3.0)
                        }
                        .padding(.top, 40)
                    } else {
                        ForEach(Array(standings.enumerated()), id: \.element.id) { index, s in
                            standingRow(rank: index + 1, standing: s, isFirst: index == 0)
                                .scrollReveal(delay: Double(index) * 0.08 + 0.2)
                            DSRule().padding(.horizontal, DS.Layout.pagePadding)
                        }
                    }
                }
                .padding(.bottom, 40)
            }
        }
        .navigationBarHidden(true)
        .scanOnAppear()
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                numbersVisible = true
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
                if hasAnyTerritory { glitchTrigger.toggle() }
            }
        }
    }

    private func standingRow(rank: Int, standing: Standing, isFirst: Bool) -> some View {
        HStack(alignment: .center, spacing: 16) {

            if isFirst && standing.totalArea > 0 {
                Text("01.")
                    .font(.system(size: 11, weight: .bold, design: .rounded))
                    .foregroundStyle(DS.Color.textPrimary)
                    .tracking(1)
                    .frame(width: 28, alignment: .leading)
            } else {
                Text(String(format: "%02d.", rank))
                    .font(.system(size: 11, weight: .medium, design: .rounded))
                    .foregroundStyle(DS.Color.textSecondary)
                    .tracking(1)
                    .frame(width: 28, alignment: .leading)
            }

            Circle()
                .fill(Color(hex: standing.colorHex))
                .frame(width: 13, height: 13)
                .shadow(color: Color(hex: standing.colorHex).opacity(0.5), radius: 4, x: 0, y: 2)

            VStack(alignment: .leading, spacing: 3) {
                Text(standing.name)
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundStyle(DS.Color.textPrimary)
                    .glitchEffect(
                        trigger: isFirst ? glitchTrigger : false,
                        color: Color(hex: standing.colorHex)
                    )
                Text("\(standing.loopCount) loop\(standing.loopCount == 1 ? "" : "s")")
                    .font(.system(size: 11, weight: .regular, design: .rounded))
                    .foregroundStyle(DS.Color.textSecondary)
            }

            Spacer()

            if standing.totalArea > 0 {
                CountingNumber(
                    target: numbersVisible ? (standing.totalArea >= 10_000 ? standing.totalArea / 10_000 : standing.totalArea) : 0,
                    unit: standing.totalArea >= 10_000 ? "ha" : "m²",
                    decimals: standing.totalArea >= 10_000 ? 2 : 0,
                    size: 15,
                    weight: .bold,
                    color: Color(hex: standing.colorHex),
                    duration: 1.0 + Double(standings.firstIndex(where: { $0.id == standing.id }) ?? 0) * 0.1
                )
            } else {
                Text("—")
                    .font(.system(size: 15, weight: .medium, design: .rounded))
                    .foregroundStyle(DS.Color.textSecondary)
            }
        }
        .padding(.horizontal, DS.Layout.pagePadding)
        .padding(.vertical, 20)
        .overlay(
            Rectangle()
                .fill(isFirst && standing.totalArea > 0 ? DS.Color.accent : .clear)
                .frame(width: 3),
            alignment: .leading
        )
    }

    private var combinedRegion: MKCoordinateRegion {
        let coords = closedActivities.flatMap { $0.coordinates }
        guard !coords.isEmpty else {
            return MKCoordinateRegion(center: .init(latitude: 0, longitude: 0),
                                      span: .init(latitudeDelta: 0.05, longitudeDelta: 0.05))
        }
        let lats = coords.map(\.latitude), lons = coords.map(\.longitude)
        let center = CLLocationCoordinate2D(
            latitude: (lats.min()! + lats.max()!) / 2,
            longitude: (lons.min()! + lons.max()!) / 2
        )
        let span = MKCoordinateSpan(
            latitudeDelta: max((lats.max()! - lats.min()!) * 1.4, 0.005),
            longitudeDelta: max((lons.max()! - lons.min()!) * 1.4, 0.005)
        )
        return MKCoordinateRegion(center: center, span: span)
    }
}
