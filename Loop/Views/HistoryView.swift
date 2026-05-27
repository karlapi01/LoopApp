//
//  HistoryView.swift
//  RunningApp
//
//  Created by Karla Pisonic on 22.05.2026..
//

import SwiftUI
import SwiftData
import MapKit

struct HistoryView: View {
    @AppStorage("activeProfileID") private var activeProfileID = ""
    @Query(sort: \Activity.date, order: .reverse) private var allActivities: [Activity]
    @Query private var profiles: [Profile]
    @Environment(\.modelContext) private var context

    private var activities: [Activity] {
        allActivities.filter { $0.ownerProfileID == activeProfileID }
    }

    private func colorHex(for ownerID: String) -> String {
        profiles.first(where: { $0.id == ownerID })?.colorHex ?? "F5C842"
    }

    var body: some View {
        NavigationStack {
            ZStack {
                DS.Color.background.ignoresSafeArea()

                if activities.isEmpty {
                    VStack(spacing: 10) {
                        DS.Label.tag("history")
                        Text("No runs yet.")
                            .font(.system(size: 30, weight: .black))
                            .foregroundStyle(DS.Color.textPrimary)
                        Text("Record your first run from the Record tab.")
                            .font(.system(size: 13))
                            .foregroundStyle(DS.Color.textSecondary)
                    }
                } else {
                    ScrollView {
                        VStack(spacing: 0) {

                            VStack(alignment: .leading, spacing: 6) {
                                DS.Label.tag("your runs")
                                    .scrollReveal(delay: 0.0)
                                StaggeredText(
                                    words: ["History."],
                                    size: 38,
                                    weight: .black,
                                    color: DS.Color.textPrimary,
                                    stagger: 0.06
                                )
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.horizontal, DS.Layout.pagePadding)
                            .padding(.top, 60)
                            .padding(.bottom, 28)

                            DSRule().padding(.horizontal, DS.Layout.pagePadding)

                            ForEach(Array(activities.enumerated()), id: \.element.id) { index, activity in
                                NavigationLink {
                                    ActivityDetailView(
                                        activity: activity,
                                        colorHex: colorHex(for: activity.ownerProfileID)
                                    )
                                } label: {
                                    activityRow(index: activities.count - index, activity: activity)
                                }
                                .buttonStyle(.plain)
                                .scrollReveal(delay: Double(index) * 0.06)

                                DSRule().padding(.horizontal, DS.Layout.pagePadding)
                            }
                        }
                        .padding(.bottom, 40)
                    }
                }
            }
            .navigationBarHidden(true)
            .scanOnAppear()
        }
    }

    private func activityRow(index: Int, activity: Activity) -> some View {
        HStack(alignment: .center, spacing: 16) {

            Text(String(format: "%02d.", index))
                .font(.system(size: 11, weight: .medium, design: .rounded))
                .foregroundStyle(DS.Color.textSecondary)
                .tracking(1)
                .frame(width: 28, alignment: .leading)

            VStack(alignment: .leading, spacing: 5) {
                Text(activity.date, format: .dateTime.weekday(.abbreviated).month(.abbreviated).day().hour().minute())
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(DS.Color.textPrimary)

                HStack(spacing: 10) {
                    statPill(String(format: "%.2f km", activity.distance / 1000))
                    statPill(durationString(activity.duration))
                    if activity.paceMinPerKm > 0 {
                        statPill(String(format: "%.1f /km", activity.paceMinPerKm))
                    }
                }
            }

            Spacer()

            if activity.isClosed {
                Text(activity.areaDisplay)
                    .font(.system(size: 12, weight: .bold, design: .rounded))
                    .foregroundStyle(DS.Color.textPrimary)
                    .padding(.horizontal, 9)
                    .padding(.vertical, 5)
                    .background(DS.Color.accent)
                    .clipShape(RoundedRectangle(cornerRadius: 6))
            } else {
                Text("OPEN")
                    .font(.system(size: 9, weight: .semibold, design: .rounded))
                    .tracking(0.5)
                    .foregroundStyle(DS.Color.textSecondary)
                    .padding(.horizontal, 7)
                    .padding(.vertical, 4)
                    .overlay(
                        RoundedRectangle(cornerRadius: 6)
                            .stroke(DS.Color.rule, lineWidth: 1)
                    )
            }

            Image(systemName: "chevron.right")
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(DS.Color.accent)
        }
        .padding(.horizontal, DS.Layout.pagePadding)
        .padding(.vertical, 20)
    }

    private func statPill(_ text: String) -> some View {
        Text(text)
            .font(.system(size: 11, weight: .regular, design: .rounded))
            .foregroundStyle(DS.Color.textSecondary)
    }

    private func durationString(_ t: TimeInterval) -> String {
        let m = Int(t) / 60, s = Int(t) % 60
        return String(format: "%d:%02d", m, s)
    }
}

struct ActivityDetailView: View {
    let activity: Activity
    let colorHex: String
    @State private var appeared = false

    var body: some View {
        ZStack(alignment: .bottom) {
            Map(initialPosition: .region(region)) {
                if activity.coordinates.count > 1 {
                    if activity.isClosed {
                        MapPolygon(coordinates: activity.coordinates)
                            .foregroundStyle(Color(hex: colorHex).opacity(0.3))
                            .stroke(Color(hex: colorHex), lineWidth: 3)
                    } else {
                        MapPolyline(coordinates: activity.coordinates)
                            .stroke(DS.Color.terra, lineWidth: 4)
                    }
                    if let start = activity.coordinates.first {
                        Annotation("", coordinate: start) {
                            Circle().fill(Color(hex: "26DE81")).frame(width: 12, height: 12)
                                .overlay(Circle().stroke(.white, lineWidth: 2))
                        }
                    }
                    if let end = activity.coordinates.last {
                        Annotation("", coordinate: end) {
                            Circle().fill(DS.Color.terra).frame(width: 12, height: 12)
                                .overlay(Circle().stroke(.white, lineWidth: 2))
                        }
                    }
                }
            }
            .ignoresSafeArea()
            .scanOnAppear()

            HStack(spacing: 0) {
                detailStat(
                    "DISTANCE",
                    appeared ? activity.distance / 1000 : 0,
                    unit: "km", decimals: 2
                )
                Rectangle().fill(DS.Color.rule).frame(width: 1, height: 32)
                detailStat(
                    "TIME",
                    appeared ? activity.duration / 60 : 0,
                    unit: "min", decimals: 1
                )
                if activity.isClosed {
                    Rectangle().fill(DS.Color.rule).frame(width: 1, height: 32)
                    detailStat(
                        "AREA",
                        appeared ? (activity.area >= 10_000 ? activity.area / 10_000 : activity.area) : 0,
                        unit: activity.area >= 10_000 ? "ha" : "m²",
                        decimals: activity.area >= 10_000 ? 2 : 0
                    )
                }
            }
            .padding(.vertical, 20)
            .frame(maxWidth: .infinity)
            .background(DS.Color.surface)
            .overlay(
                Rectangle()
                    .fill(DS.Color.rule)
                    .frame(height: 1),
                alignment: .top
            )
        }
        .navigationTitle(activity.isClosed ? activity.areaDisplay : String(format: "%.2f km", activity.distance / 1000))
        .navigationBarTitleDisplayMode(.inline)
        .preferredColorScheme(.light)
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { appeared = true }
        }
    }

    private func detailStat(_ label: String, _ value: Double, unit: String, decimals: Int) -> some View {
        VStack(spacing: 4) {
            Text(label)
                .font(.system(size: 9, weight: .semibold, design: .rounded))
                .tracking(0.5)
                .foregroundStyle(DS.Color.textSecondary)
            CountingNumber(
                target: value,
                unit: unit,
                decimals: decimals,
                size: 18,
                color: DS.Color.textPrimary,
                duration: 0.9
            )
        }
        .frame(maxWidth: .infinity)
    }

    private var region: MKCoordinateRegion {
        let coords = activity.coordinates
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
