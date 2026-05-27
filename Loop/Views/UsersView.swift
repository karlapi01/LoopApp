//
//  UsersView.swift
//  RunningApp
//
//  Created by Karla Pisonic on 22.05.2026..
//

import SwiftUI
import SwiftData

struct UsersView: View {
    @AppStorage("activeProfileID") private var activeProfileID = ""
    @AppStorage("hasUnlocked") private var hasUnlocked = false
    @Query(sort: \Profile.joinedDate) private var profiles: [Profile]
    @Query private var activities: [Activity]
    @State private var glitchTrigger = false

    var body: some View {
        ZStack {
            DS.Color.background.ignoresSafeArea()

            ScrollView {
                VStack(spacing: 0) {

                    VStack(alignment: .leading, spacing: 6) {
                        DS.Label.tag("who's running")
                            .scrollReveal(delay: 0.0)
                        StaggeredText(
                            words: ["Runners."],
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

                    VStack(spacing: 0) {
                        ForEach(Array(profiles.enumerated()), id: \.element.id) { index, profile in
                            runnerRow(index: index + 1, profile: profile)
                                .scrollReveal(delay: Double(index) * 0.07)
                            DSRule().padding(.horizontal, DS.Layout.pagePadding)
                        }
                    }

                    Button {
                        activeProfileID = ""
                        hasUnlocked = false
                    } label: {
                        HStack {
                            Text("LOG OUT")
                                .font(.system(size: 11, weight: .semibold, design: .rounded))
                                .tracking(0.5)
                                .foregroundStyle(DS.Color.terra)
                            Spacer()
                            Image(systemName: "arrow.right")
                                .font(.system(size: 11, weight: .semibold))
                                .foregroundStyle(DS.Color.terra)
                        }
                        .padding(.horizontal, DS.Layout.pagePadding)
                        .padding(.vertical, 20)
                    }
                    .scrollReveal(delay: Double(profiles.count) * 0.07 + 0.1)
                }
                .padding(.bottom, 40)
            }
        }
        .navigationBarHidden(true)
        .scanOnAppear()
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                glitchTrigger.toggle()
            }
        }
    }

    private func runnerRow(index: Int, profile: Profile) -> some View {
        HStack(alignment: .center, spacing: 16) {

            Text(String(format: "%02d.", index))
                .font(.system(size: 11, weight: .medium, design: .rounded))
                .foregroundStyle(DS.Color.textSecondary)
                .tracking(1)
                .frame(width: 28, alignment: .leading)

            Circle()
                .fill(Color(hex: profile.colorHex))
                .frame(width: 13, height: 13)
                .shadow(color: Color(hex: profile.colorHex).opacity(0.5), radius: 4, x: 0, y: 2)

            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 8) {
                    Text(profile.name)
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundStyle(DS.Color.textPrimary)
                        .glitchEffect(
                            trigger: profile.id == activeProfileID ? glitchTrigger : false,
                            color: Color(hex: profile.colorHex)
                        )

                    if profile.id == activeProfileID {
                        Text("YOU")
                            .font(.system(size: 8, weight: .bold, design: .rounded))
                            .tracking(0.5)
                            .foregroundStyle(DS.Color.textPrimary)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 3)
                            .background(DS.Color.accent)
                            .clipShape(RoundedRectangle(cornerRadius: 4))
                    }
                }

                Text("\(runCount(for: profile)) run\(runCount(for: profile) == 1 ? "" : "s")  ·  joined \(profile.joinedDate, format: .dateTime.month(.abbreviated).day())")
                    .font(.system(size: 12, weight: .regular, design: .rounded))
                    .foregroundStyle(DS.Color.textSecondary)
            }

            Spacer()
        }
        .padding(.horizontal, DS.Layout.pagePadding)
        .padding(.vertical, 20)
    }

    private func runCount(for profile: Profile) -> Int {
        activities.filter { $0.ownerProfileID == profile.id }.count
    }
}
