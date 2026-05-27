//
//  EntryFlowView.swift
//  RunningApp
//
//  Created by Karla Pisonic on 22.05.2026..
//

import SwiftUI
import SwiftData

struct EntryFlowView: View {
    @AppStorage("hasUnlocked") private var hasUnlocked = false

    var body: some View {
        if hasUnlocked {
            ProfileSetupView()
        } else {
            AccessCodeView()
        }
    }
}

struct AccessCodeView: View {
    @AppStorage("hasUnlocked") private var hasUnlocked = false
    @State private var code = ""
    @State private var showError = false
    @State private var colorIndex = 0

    private let colors: [Color] = [.red, .orange, .pink]

    var body: some View {
        ZStack {
            colors[colorIndex]
                .ignoresSafeArea()
                .animation(.easeInOut(duration: 3), value: colorIndex)

            TextField("", text: $code, prompt:
                Text("Enter the code").foregroundColor(.white.opacity(0.8)))
                .textInputAutocapitalization(.characters)
                .autocorrectionDisabled()
                .multilineTextAlignment(.center)
                .font(.system(.title3, design: .rounded))
                .foregroundStyle(.white)
                .padding()
                .background(.white.opacity(0.25), in: RoundedRectangle(cornerRadius: 16))
                .padding(.horizontal, 40)
                .onSubmit { submit() }
        }
        .onAppear {
            startCycling()
        }
    }

    private func submit() {
        if AccessCodes.isValid(code) {
            withAnimation { hasUnlocked = true }
        } else {
            showError = true
            code = ""
        }
    }

    private func startCycling() {
        Timer.scheduledTimer(withTimeInterval: 3, repeats: true) { _ in
            colorIndex = (colorIndex + 1) % colors.count
        }
    }
}

struct ProfileSetupView: View {
    @Environment(\.modelContext) private var context
    @AppStorage("activeProfileID") private var activeProfileID = ""
    @Query(sort: \Profile.joinedDate) private var profiles: [Profile]

    @State private var name = ""

    private let palette = ["FF6B6B", "4ECDC4", "FFD93D", "6C5CE7", "26DE81", "FD9644"]

    var body: some View {
        ZStack {
            DS.Color.background.ignoresSafeArea()

            VStack(spacing: 0) {

                VStack(alignment: .leading, spacing: 6) {
                    DS.Label.tag("welcome back")
                    StaggeredText(
                        words: ["Who's", "running?"],
                        size: 36,
                        weight: .black,
                        color: DS.Color.textPrimary,
                        stagger: 0.08
                    )
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, DS.Layout.pagePadding)
                .padding(.top, 72)
                .padding(.bottom, 28)

                DSRule().padding(.horizontal, DS.Layout.pagePadding)

                if !profiles.isEmpty {
                    ScrollView {
                        VStack(spacing: 0) {
                            ForEach(Array(profiles.enumerated()), id: \.element.id) { index, profile in
                                Button {
                                    withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                                        activeProfileID = profile.id
                                    }
                                } label: {
                                    HStack(spacing: 16) {
                                        Text(String(format: "%02d.", index + 1))
                                            .font(.system(size: 11, weight: .medium, design: .rounded))
                                            .foregroundStyle(DS.Color.textSecondary)
                                            .frame(width: 28, alignment: .leading)

                                        Circle()
                                            .fill(Color(hex: profile.colorHex))
                                            .frame(width: 13, height: 13)
                                            .shadow(color: Color(hex: profile.colorHex).opacity(0.5), radius: 4, x: 0, y: 2)

                                        Text(profile.name)
                                            .font(.system(size: 17, weight: .semibold, design: .rounded))
                                            .foregroundStyle(DS.Color.textPrimary)

                                        Spacer()

                                        Image(systemName: "chevron.right")
                                            .font(.system(size: 11, weight: .semibold))
                                            .foregroundStyle(DS.Color.accent)
                                    }
                                    .padding(.horizontal, DS.Layout.pagePadding)
                                    .padding(.vertical, 20)
                                }
                                .scrollReveal(delay: Double(index) * 0.07)

                                DSRule().padding(.horizontal, DS.Layout.pagePadding)
                            }
                        }
                    }
                }

                Spacer()

                VStack(spacing: 16) {
                    DSRule().padding(.horizontal, DS.Layout.pagePadding)

                    if !profiles.isEmpty {
                        Text("or create a new one")
                            .font(.system(size: 13, weight: .regular, design: .rounded))
                            .foregroundStyle(DS.Color.textSecondary)
                    }

                    HStack(spacing: 12) {
                        TextField("Your name", text: $name)
                            .font(.system(size: 16, weight: .medium, design: .rounded))
                            .foregroundStyle(DS.Color.textPrimary)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 14)
                            .background(DS.Color.surface)
                            .clipShape(RoundedRectangle(cornerRadius: DS.Layout.cornerRadius))
                            .overlay(
                                RoundedRectangle(cornerRadius: DS.Layout.cornerRadius)
                                    .stroke(DS.Color.rule, lineWidth: 1)
                            )

                        Button {
                            let trimmed = name.trimmingCharacters(in: .whitespaces)
                            guard !trimmed.isEmpty else { return }
                            let color = palette[profiles.count % palette.count]
                            let profile = Profile(name: trimmed, colorHex: color)
                            context.insert(profile)
                            activeProfileID = profile.id
                        } label: {
                            Text("Add")
                                .font(.system(size: 15, weight: .bold, design: .rounded))
                                .foregroundStyle(DS.Color.textPrimary)
                                .padding(.horizontal, 22)
                                .padding(.vertical, 14)
                                .background(DS.Color.accent)
                                .clipShape(RoundedRectangle(cornerRadius: DS.Layout.cornerRadius))
                        }
                        .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty)
                        .opacity(name.trimmingCharacters(in: .whitespaces).isEmpty ? 0.4 : 1)
                    }
                    .padding(.horizontal, DS.Layout.pagePadding)
                }
                .padding(.bottom, 40)
            }
        }
        .preferredColorScheme(.light)
        .scanOnAppear()
    }
}
