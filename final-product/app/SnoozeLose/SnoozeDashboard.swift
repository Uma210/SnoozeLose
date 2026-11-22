import SwiftUI
import UIKit

// SNOOZELOSE / STUDIO DESIGN SYSTEM
// Rich midnight canvas, warm citrine, restrained lilac, generous rhythm.
enum Studio {
    // Pixel-matched color tokens from the uploaded tidalBYTE portal HTML.
    static let background = Color(red: 0xEF/255.0, green: 0xF6/255.0, blue: 0xFC/255.0)
    static let surface = Color.white
    static let raised = Color(red: 0xE2/255.0, green: 0xEC/255.0, blue: 0xF6/255.0)
    static let border = Color(red: 0xB9/255.0, green: 0xD0/255.0, blue: 0xE6/255.0)
    static let primary = Color(red: 0x30/255.0, green: 0x38/255.0, blue: 0x46/255.0)
    static let muted = Color(red: 0x5B/255.0, green: 0x69/255.0, blue: 0x7C/255.0)
    static let lime = Color(red: 0x29/255.0, green: 0x6B/255.0, blue: 0x5D/255.0) // portal badge green
    static let violet = Color(red: 0x5A/255.0, green: 0x73/255.0, blue: 0x92/255.0)
    static let orange = Color(red: 0x9D/255.0, green: 0x62/255.0, blue: 0x3A/255.0)
    static let hardShadow = Color(red: 0x8F/255.0, green: 0xA1/255.0, blue: 0xB0/255.0)
}

// Native approximation of the HTML's Space Mono. Space Mono is loaded from Google Fonts
// in the original webpage; no third-party font binaries are bundled in this project.
struct PortalCanvas: View {
    var body: some View {
        GeometryReader { proxy in
            Canvas { context, size in
                let spacing: CGFloat = 73
                var lines = Path()
                stride(from: CGFloat(0), through: size.width, by: spacing).forEach { x in
                    lines.move(to: CGPoint(x: x, y: 0))
                    lines.addLine(to: CGPoint(x: x, y: size.height))
                }
                stride(from: CGFloat(0), through: size.height, by: spacing).forEach { y in
                    lines.move(to: CGPoint(x: 0, y: y))
                    lines.addLine(to: CGPoint(x: size.width, y: y))
                }
                context.stroke(lines, with: .color(Color.white.opacity(0.65)), lineWidth: 1)
            }
            .frame(width: proxy.size.width, height: proxy.size.height)
        }
        .background(Studio.background)
        .ignoresSafeArea()
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }
}

struct SoftPanel<Content: View>: View {
    let content: Content
    init(@ViewBuilder content: () -> Content) { self.content = content() }
    var body: some View {
        content
            .background(Studio.surface, in: RoundedRectangle(cornerRadius: 17, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: 17, style: .continuous)
                .strokeBorder(Studio.border, lineWidth: 1.5))
            .shadow(color: Studio.hardShadow.opacity(0.48), radius: 0, x: 4, y: 4)
    }
}

struct StudioButtonStyle: ButtonStyle {
    let bright: Bool
    init(bright: Bool = true) { self.bright = bright }
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 15, weight: .bold, design: .monospaced))
            .foregroundStyle(bright ? Color.white : Studio.primary)
            .frame(maxWidth: .infinity).frame(minHeight: 56)
            .background(bright ? Studio.lime : Studio.raised,
                        in: RoundedRectangle(cornerRadius: 11, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: 11).strokeBorder(bright ? Studio.lime : Studio.border, lineWidth: 1.2))
            .scaleEffect(configuration.isPressed ? 0.97 : 1)
            .opacity(configuration.isPressed ? 0.82 : 1)
            .animation(.spring(response: 0.26, dampingFraction: 0.75), value: configuration.isPressed)
    }
}

struct SnoozeActionStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .foregroundStyle(Color.white)
            .background(Studio.lime, in: RoundedRectangle(cornerRadius: 11, style: .continuous))
            .scaleEffect(configuration.isPressed ? 0.97 : 1)
            .animation(.spring(response: 0.25, dampingFraction: 0.75), value: configuration.isPressed)
    }
}

struct AlarmEditor: View {
    @EnvironmentObject private var model: SnoozeModel
    @Environment(\.dismiss) private var dismiss
    let existing: WakeAlarm?
    @State private var alarm: WakeAlarm
    @State private var selectedTime: Date
    @State private var awaitingConfirmation = false

    init(existing: WakeAlarm?) {
        self.existing = existing
        let initial = existing ?? WakeAlarm(title: "Rise and shine", hour: 7, minute: 0)
        _alarm = State(initialValue: initial)
        _selectedTime = State(initialValue: Calendar.current.date(from: DateComponents(hour: initial.hour, minute: initial.minute)) ?? Date())
    }

    var body: some View {
        NavigationStack {
            ZStack {
                PortalCanvas()
                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 25) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(existing == nil ? "New alarm" : "Edit alarm")
                                .font(.system(size: 33, weight: .bold, design: .monospaced)).tracking(-1)
                            Text("Build a better wake-up ritual.").font(.subheadline).foregroundStyle(Studio.muted)
                        }.padding(.top, 14)
                        SoftPanel {
                            VStack(spacing: 6) {
                                Text("WAKE-UP TIME").font(.system(size: 11, weight: .bold, design: .monospaced))
                                    .tracking(1.6).foregroundStyle(Studio.muted)
                                DatePicker("Time", selection: $selectedTime, displayedComponents: .hourAndMinute)
                                    .datePickerStyle(.wheel).labelsHidden()
                                    .tint(Studio.lime).frame(maxWidth: .infinity)
                            }.padding(19)
                        }
                        // Explicit game selection replaces the former random draw.
                        SoftPanel {
                            VStack(alignment: .leading, spacing: 12) {
                                HStack(spacing: 8) {
                                    Image(systemName: "gamecontroller.fill").foregroundStyle(Studio.violet)
                                    Text("WAKE-UP GAME")
                                        .font(.system(size: 12, weight: .bold, design: .monospaced))
                                        .tracking(1)
                                }
                                Text("Choose the one game this alarm will launch. Snoozing keeps the same game.")
                                    .font(.footnote).foregroundStyle(Studio.muted)
                                    .fixedSize(horizontal: false, vertical: true)
                                ForEach(AlarmGame.allCases) { option in
                                    Button {
                                        guard option.isReady else { return }
                                        alarm.game = option
                                        UISelectionFeedbackGenerator().selectionChanged()
                                    } label: {
                                        HStack(alignment: .center, spacing: 12) {
                                            Image(systemName: option.symbol)
                                                .font(.system(size: 19, weight: .semibold))
                                                .frame(width: 28)
                                            VStack(alignment: .leading, spacing: 4) {
                                                Text(option.title)
                                                    .font(.system(size: 15, weight: .bold))
                                                Text(option.subtitle)
                                                    .font(.system(size: 12))
                                                    .fixedSize(horizontal: false, vertical: true)
                                            }
                                            Spacer(minLength: 4)
                                            Image(systemName: alarm.game == option ? "checkmark.circle.fill" :
                                                  (option.isReady ? "circle" : "lock.circle"))
                                                .font(.system(size: 22))
                                        }
                                        .foregroundStyle(option.isReady ? Studio.primary : Studio.muted)
                                        .padding(.horizontal, 12)
                                        .padding(.vertical, 12)
                                        .frame(maxWidth: .infinity, minHeight: 64)
                                        .background(alarm.game == option && option.isReady ?
                                            Studio.raised : Studio.surface,
                                            in: RoundedRectangle(cornerRadius: 13))
                                        .overlay(RoundedRectangle(cornerRadius: 13).strokeBorder(
                                            alarm.game == option && option.isReady ? Studio.lime : Studio.border,
                                            lineWidth: alarm.game == option && option.isReady ? 2 : 1))
                                    }
                                    .buttonStyle(.plain)
                                    .disabled(!option.isReady)
                                    .accessibilityLabel("\(option.title). \(option.subtitle)")
                                    .accessibilityAddTraits(alarm.game == option ? [.isSelected] : [])
                                }
                            }.padding(19)
                        }
                        SoftPanel {
                            VStack(spacing: 18) {
                                HStack {
                                    Image(systemName: "textformat").frame(width: 24).foregroundStyle(Studio.violet)
                                    TextField("Alarm name", text: $alarm.title)
                                        .textInputAutocapitalization(.sentences)
                                }
                                Divider().overlay(Studio.border)
                                HStack {
                                    Image(systemName: "waveform").frame(width: 24).foregroundStyle(Studio.violet)
                                    Picker("Ringtone", selection: $alarm.sound) {
                                        Text("System default (Sunrise preview)").tag("Default")
                                        Text("Sunrise Bell").tag("Sunrise")
                                        Text("Pulse Ringer").tag("Pulse")
                                        Text("Silent in app / notification (not AlarmKit)").tag("Silent")
                                    }.tint(Studio.lime)
                                }
                                Divider().overlay(Studio.border)
                                Toggle(isOn: $alarm.vibration) { Label("Haptic pulses (foreground only)", systemImage: "iphone.radiowaves.left.and.right") }
                                    .tint(Studio.lime)
                                Divider().overlay(Studio.border)
                                Toggle(isOn: $alarm.flash) { Label("Flashlight pulses (foreground only)", systemImage: "flashlight.on.fill") }
                                    .tint(Studio.lime)
                                Divider().overlay(Studio.border)
                                Toggle(isOn: $alarm.enabled) { Label("Alarm enabled", systemImage: "bell.badge.fill") }
                                    .tint(Studio.lime)
                            }.padding(21)
                        }
                        Text("System alarms require authorization on iOS 26+. On older iOS versions, a notification does not ring continuously in the background. Flashlight pulses are low intensity and stop when the app goes inactive; turn them off if uncomfortable. iOS always provides system Stop controls.")
                            .font(.system(size: 12)).foregroundStyle(Studio.muted)
                        if awaitingConfirmation {
                            VStack(alignment: .leading, spacing: 8) {
                                Label(model.state(for: alarm).title,
                                      systemImage: model.state(for: alarm).isArmed ? "checkmark.shield.fill" : "exclamationmark.triangle.fill")
                                    .font(.headline)
                                Text(model.state(for: alarm).detail).font(.footnote)
                                if !model.state(for: alarm).isReady {
                                    Button("Retry scheduling") { model.saveAlarm(alarm) }
                                        .buttonStyle(StudioButtonStyle(bright: false))
                                }
                            }
                            .padding(14)
                            .background(Studio.surface, in: RoundedRectangle(cornerRadius: 14))
                            .accessibilityElement(children: .combine)
                        }
                        Button {
                            let parts = Calendar.current.dateComponents([.hour, .minute], from: selectedTime)
                            alarm.hour = parts.hour ?? 7; alarm.minute = parts.minute ?? 0
                            if alarm.title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty { alarm.title = "Wake up" }
                            guard alarm.game.isReady else { return }
                            awaitingConfirmation = true
                            model.saveAlarm(alarm)
                            if !alarm.enabled { dismiss() }
                        } label: {
                            Label(awaitingConfirmation ? "Try saving again" : "Save and verify alarm", systemImage: "checkmark")
                        }
                            .buttonStyle(StudioButtonStyle())
                            .disabled(!alarm.game.isReady || (awaitingConfirmation && model.state(for: alarm) == .pending))
                    }.padding(22).padding(.bottom, 24)
                }
            }
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }.tint(Studio.muted)
                }
            }
            .toolbarBackground(Studio.background, for: .navigationBar)
        }
        .snoozeOnChange(of: model.delivery[alarm.id]) { status in
            guard awaitingConfirmation, let status = status else { return }
            if status.isArmed || status == .off {
                UINotificationFeedbackGenerator().notificationOccurred(.success)
                dismiss()
            }
        }
        .preferredColorScheme(.light)
    }
}

struct StudioSettingsView: View {
    @EnvironmentObject private var model: SnoozeModel
    @Environment(\.dismiss) private var dismiss
    var body: some View {
        NavigationStack {
            ZStack {
                PortalCanvas()
                VStack(alignment: .leading, spacing: 22) {
                    Text("The essentials").font(.system(size: 31, weight: .bold, design: .monospaced))
                    SoftPanel {
                        VStack(alignment: .leading, spacing: 17) {
                            Label("Alarm delivery", systemImage: "bell.and.waves.left.and.right")
                                .font(.headline)
                            Text("SnoozeLose schedules supported system alarms through AlarmKit. iOS still allows system-level Stop actions.")
                                .font(.subheadline).foregroundStyle(Studio.muted)
                            Button("Refresh alarm schedules") { model.reapplyAlarmSchedules() }
                                .buttonStyle(StudioButtonStyle())
                            Button("Request notifications") { model.askPermission() }
                                .buttonStyle(StudioButtonStyle(bright: false))
                        }.padding(20)
                    }
                    Text("SNOOZELOSE · v1.8 · BUILD 19")
                        .font(.system(size: 10, weight: .bold, design: .monospaced)).tracking(1.2)
                        .foregroundStyle(Studio.muted)
                    Spacer()
                }.padding(22)
            }
            .toolbar { ToolbarItem(placement: .topBarTrailing) { Button("Done") { dismiss() }.tint(Studio.lime) } }
        }.preferredColorScheme(.light)
    }
}

struct WakeChallengeSession: View {
    @EnvironmentObject private var model: SnoozeModel
    var body: some View {
        if let session = model.session,
           session.resumeAt == nil,
           let current = session.nextChallenge,
           current.kind == .perception {
            PerceptionWakeScreen(item: current)
                .id(current.id)
        } else if let session = model.session,
                  session.resumeAt == nil,
                  let current = session.nextChallenge,
                  current.kind == .word {
            WordWakeScreen(item: current)
                .id(current.id)
        } else {
        NavigationStack {
            ZStack {
                PortalCanvas()
                ScrollView(showsIndicators: false) {
                    if let session = model.session {
                        VStack(spacing: 22) {
                            if model.isPractice {
                                HStack {
                                    Label("Practice only · no alarm scheduled", systemImage: "play.square")
                                        .font(.caption).foregroundStyle(Studio.muted)
                                    Spacer()
                                    Button("Exit practice") { model.endPractice() }
                                        .font(.subheadline).fontWeight(.semibold)
                                }
                            }
                            ZStack {
                                Circle().stroke(Studio.violet.opacity(0.15), lineWidth: 1).frame(width: 146, height: 146)
                                Circle().stroke(Studio.violet.opacity(0.24), lineWidth: 1).frame(width: 116, height: 116)
                                Circle().fill(Studio.violet.opacity(0.12)).frame(width: 88, height: 88)
                                Image(systemName: "alarm.waves.left.and.right.fill")
                                    .font(.system(size: 40)).foregroundStyle(Studio.violet)
                                    .scaleEffect(model.ringIsActive ? 1.06 : 1)
                                    .animation(.easeInOut(duration: 0.85), value: model.ringIsActive)
                            }.padding(.top, 15)
                            VStack(spacing: 7) {
                                Text(model.ringIsActive ? "TIME TO RISE" : "WAKE-UP QUEST")
                                    .font(.system(size: 11, weight: .bold, design: .monospaced)).tracking(2)
                                    .foregroundStyle(Studio.lime)
                                Text(model.alarmTitle(for: session.alarmID))
                                    .font(.system(size: 29, weight: .bold, design: .monospaced)).tracking(-0.8)
                                    .multilineTextAlignment(.center)
                                Text("One game per alarm. You’ve got this.")
                                    .font(.system(size: 13)).foregroundStyle(Studio.muted)
                            }
                            if model.ringIsActive {
                                Button { model.stopRinger() } label: {
                                    Label("Emergency silence · keep challenge open", systemImage: "speaker.slash")
                                }.font(.system(size: 12, weight: .semibold)).foregroundStyle(Studio.muted)
                            }
                            SoftPanel {
                                VStack(alignment: .leading, spacing: 13) {
                                    HStack {
                                        Text("YOUR PROGRESS").font(.system(size: 11, weight: .bold, design: .monospaced)).tracking(1.2)
                                        Spacer()
                                        Text("\(session.solvedCount) / \(session.requiredCount)")
                                            .font(.system(size: 13, weight: .bold, design: .monospaced)).monospacedDigit()
                                    }
                                    HStack(spacing: 6) {
                                        ForEach(0..<max(1, session.requiredCount), id: \.self) { i in
                                            Capsule().fill(i < session.solvedCount ? Studio.lime : Studio.raised)
                                                .frame(height: 6)
                                        }
                                    }
                                }.padding(19)
                            }
                            if let until = session.resumeAt, until > Date() {
                                VStack(spacing: 20) {
                                    Image(systemName: "moon.zzz.fill").font(.system(size: 44)).foregroundStyle(Studio.violet)
                                    Text("A little more rest").font(.system(size: 25, weight: .bold, design: .monospaced))
                                    Text("Snoozed until \(until.formatted(date: .omitted, time: .shortened))")
                                        .foregroundStyle(Studio.muted)
                                    Text("Your selected game is paused. Play now or wait for the reminder—snoozing won’t add games.")
                                        .font(.system(size: 13))
                                        .foregroundStyle(Studio.muted)
                                        .multilineTextAlignment(.center)
                                    Button {
                                        model.playPendingChallengesNow()
                                    } label: {
                                        Label("Play game now", systemImage: "gamecontroller.fill")
                                    }
                                    .buttonStyle(StudioButtonStyle())
                                    Button("Back to alarms") { model.showSession = false }
                                        .buttonStyle(StudioButtonStyle(bright: false))
                                }.padding(22)
                            } else if let challenge = session.nextChallenge {
                                ChallengePlayer(item: challenge).id(challenge.id)
                                    .transition(.opacity.combined(with: .move(edge: .trailing)))
                                if !model.isPractice {
                                    Button { model.snooze() } label: {
                                        Label("Snooze 5 min · same game", systemImage: "moon.zzz")
                                    }.buttonStyle(StudioButtonStyle(bright: false))
                                    Text("On older iOS versions, snooze uses a notification rather than a persistent system alarm.")
                                        .font(.caption2).foregroundStyle(Studio.muted)
                                }
                            } else {
                                VStack(spacing: 17) {
                                    Image(systemName: "checkmark.seal.fill").font(.system(size: 58)).foregroundStyle(Studio.lime)
                                    Text("You did it.").font(.system(size: 31, weight: .bold, design: .monospaced))
                                    Text(model.isPractice ? "Practice complete. No live alarm was changed." : "Your wake-up game is complete. Your morning is yours.")
                                        .font(.subheadline).foregroundStyle(Studio.muted)
                                        .multilineTextAlignment(.center)
                                    Button(model.isPractice ? "Finish practice" : "Dismiss alarm") {
                                        UINotificationFeedbackGenerator().notificationOccurred(.success)
                                        model.dismiss()
                                    }.buttonStyle(StudioButtonStyle())
                                }.frame(maxWidth: .infinity).padding(25)
                                    .background(Studio.surface, in: RoundedRectangle(cornerRadius: 17))
                            }
                            Text("The challenge stays open until completed. iOS still allows leaving the app or stopping a system alarm; torch and app sound stop in the background.")
                                .font(.system(size: 11)).foregroundStyle(Studio.muted)
                                .multilineTextAlignment(.center)
                            Spacer(minLength: 30)
                        }.padding(21)
                            .animation(.spring(response: 0.37, dampingFraction: 0.88), value: session.solvedCount)
                    } else {
                        Text("No active alarm").foregroundStyle(Studio.muted)
                    }
                }
            }.toolbar(.hidden, for: .navigationBar)
        }
        }
    }
}
