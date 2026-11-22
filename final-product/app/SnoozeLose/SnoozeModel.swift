import Foundation
import SwiftUI
import UserNotifications
#if canImport(AlarmKit)
import AlarmKit
import ActivityKit
import AppIntents
#endif

struct WakeAlarm: Identifiable, Codable, Equatable {
    var id = UUID()
    var title: String
    var hour: Int
    var minute: Int
    var enabled = true
    var sound = "Default"
    var vibration = true
    var flash = true
    // Persist a deliberate game choice with the alarm, not with each run.
    var game: AlarmGame = .perception

    // Backward-compatible: alarms saved before this version default to Perception Set.
    init(id: UUID = UUID(), title: String, hour: Int, minute: Int,
         enabled: Bool = true, sound: String = "Default", vibration: Bool = true,
         flash: Bool = true, game: AlarmGame = .perception) {
        self.id = id; self.title = title; self.hour = hour; self.minute = minute
        self.enabled = enabled; self.sound = sound; self.vibration = vibration; self.flash = flash
        self.game = game
    }

    private enum CodingKeys: String, CodingKey {
        case id, title, hour, minute, enabled, sound, vibration, flash, game
    }

    init(from decoder: Decoder) throws {
        let data = try decoder.container(keyedBy: CodingKeys.self)
        id = try data.decode(UUID.self, forKey: .id)
        title = try data.decode(String.self, forKey: .title)
        hour = try data.decode(Int.self, forKey: .hour)
        minute = try data.decode(Int.self, forKey: .minute)
        enabled = try data.decodeIfPresent(Bool.self, forKey: .enabled) ?? true
        sound = try data.decodeIfPresent(String.self, forKey: .sound) ?? "Default"
        vibration = try data.decodeIfPresent(Bool.self, forKey: .vibration) ?? true
        flash = try data.decodeIfPresent(Bool.self, forKey: .flash) ?? false
        game = try data.decodeIfPresent(AlarmGame.self, forKey: .game) ?? .perception
    }

    var timeLabel: String {
        let h = hour % 12 == 0 ? 12 : hour % 12
        return String(format: "%d:%02d %@", h, minute, hour < 12 ? "AM" : "PM")
    }
}

// The game selected while creating or editing an alarm. Krillion is visible for
// transparency but is intentionally unavailable until its missing game modules
// are supplied; the uploaded React Native App.js is only a launcher.
enum AlarmGame: String, Codable, CaseIterable, Identifiable {
    case perception
    case word
    case krillion

    var id: String { rawValue }
    var title: String {
        switch self {
        case .perception: return "Perception Set"
        case .word: return "Word Guess"
        case .krillion: return "Krillion"
        }
    }
    var subtitle: String {
        switch self {
        case .perception: return "Four visual rounds · 70 average to win"
        case .word: return "Five-letter puzzle · six guesses"
        case .krillion: return "Waiting for the actual game source files"
        }
    }
    var symbol: String {
        switch self {
        case .perception: return "eye"
        case .word: return "character.cursor.ibeam"
        case .krillion: return "sparkle.magnifyingglass"
        }
    }
    var isReady: Bool {
        switch self {
        case .perception: return PerceptionSetBundle.isAvailable
        case .word: return true
        case .krillion: return false
        }
    }
}

enum ChallengeKind: String, Codable, CaseIterable {
    // Only offered when the real perception-set bundle is installed.
    case perception = "Perception Set"
    case word = "Word Guess"
    case count = "Quick Count"
    case crossword = "Mini Crossword"
}

struct ChallengeItem: Identifiable, Codable, Equatable {
    var id = UUID()
    var kind: ChallengeKind
    var solved = false
    var puzzleSeed: Int
}

struct WakeSession: Codable, Equatable {
    var alarmID: UUID
    var startedOn: Date
    var snoozes = 0
    var challenges: [ChallengeItem]
    var resumeAt: Date? = nil
    var completed = false
    var snoozeSystemID: UUID? = nil

    private enum CodingKeys: String, CodingKey { case alarmID, startedOn, snoozes, challenges, resumeAt, completed, snoozeSystemID }
    init(alarmID: UUID, startedOn: Date, snoozes: Int = 0, challenges: [ChallengeItem], resumeAt: Date? = nil, completed: Bool = false, snoozeSystemID: UUID? = nil) {
        self.alarmID = alarmID; self.startedOn = startedOn; self.snoozes = snoozes; self.challenges = challenges
        self.resumeAt = resumeAt; self.completed = completed; self.snoozeSystemID = snoozeSystemID
    }
    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        alarmID = try c.decode(UUID.self, forKey: .alarmID)
        startedOn = try c.decode(Date.self, forKey: .startedOn)
        snoozes = try c.decodeIfPresent(Int.self, forKey: .snoozes) ?? 0
        challenges = try c.decode([ChallengeItem].self, forKey: .challenges)
        resumeAt = try c.decodeIfPresent(Date.self, forKey: .resumeAt)
        completed = try c.decodeIfPresent(Bool.self, forKey: .completed) ?? false
        snoozeSystemID = try c.decodeIfPresent(UUID.self, forKey: .snoozeSystemID)
    }
    var requiredCount: Int { challenges.count }
    var solvedCount: Int { challenges.filter(\.solved).count }
    var isUnlocked: Bool { solvedCount == requiredCount && !completed }
    var nextChallenge: ChallengeItem? { challenges.first { !$0.solved } }
}

// Delivery is deliberately different from whether the alarm's toggle is on.
// A saved item is not called armed until the OS has accepted a scheduled alert.
enum AlarmDelivery: Equatable {
    case off
    case pending
    case system
    case notification
    case permissionRequired(String)
    case error(String)

    var isReady: Bool {
        switch self { case .system, .notification, .off: return true; default: return false }
    }
    var isArmed: Bool {
        switch self { case .system, .notification: return true; default: return false }
    }
    var title: String {
        switch self {
        case .off: return "Off"
        case .pending: return "Scheduling…"
        case .system: return "System alarm armed"
        case .notification: return "Notification fallback armed"
        case .permissionRequired: return "Permission required — not armed"
        case .error: return "Scheduling failed — not armed"
        }
    }
    var detail: String {
        switch self {
        case .off: return "This alarm is switched off."
        case .pending: return "Confirming delivery with iOS…"
        case .system: return "AlarmKit controls sound and Lock Screen alerting. iOS can still stop it."
        case .notification: return "A local notification is scheduled; this is not a continuous system alarm."
        case .permissionRequired(let message), .error(let message): return message
        }
    }
}

@MainActor
final class SnoozeModel: ObservableObject {
    @Published var alarms: [WakeAlarm] = []
    @Published var session: WakeSession?
    @Published var notificationsAllowed = false
    @Published var showSession = false
    @Published var feedback = ""
    @Published var ringIsActive = false
    @Published var usingSystemAlarms = false
    @Published var delivery: [UUID: AlarmDelivery] = [:]
    @Published var isPractice = false
    let ringer = WakeRinger()

    let snoozeMinutes = 5
    private let alarmsKey = "snoozelose.alarms.v1"
    private let sessionKey = "snoozelose.session.v1"
    private let pendingIDsKey = "snoozelose.pendingLiveAlarmIDs.v1"
    // A single queue serializes all schedule, edit, disable and delete operations.
    // The generation guard discards stale operations before they touch the OS.
    private var schedulingQueue: Task<Void, Never>?
    private var revisions: [UUID: Int] = [:]
    private var pendingLiveAlarmIDs: [UUID] = []

    // MARK: Automatic presentation while the app is in the foreground
    // AlarmKit owns delivery while iOS suspends or closes SnoozeLose. Inside the
    // running app we must separately observe alerting and present SwiftUI ourselves.
    private let nextFireKey = "snoozelose.nextFireDates.v1"
    private var nextFireDates: [UUID: Date] = [:]
    private var lastAutoOpen: [UUID: Date] = [:]
    private var foregroundIsActive = false
    private var alarmUpdatesTask: Task<Void, Never>?

    init() {
        if let data = UserDefaults.standard.data(forKey: alarmsKey),
           let stored = try? JSONDecoder().decode([WakeAlarm].self, from: data) { alarms = stored }
        if let data = UserDefaults.standard.data(forKey: sessionKey),
           let stored = try? JSONDecoder().decode(WakeSession.self, from: data), !stored.completed {
            // v1.8.7 migration: older releases accumulated up to five challenges.
            // Preserve a previously finished set; otherwise keep one unsolved game.
            // A fresh, unattempted legacy session starts with the installed Perception Set.
            var migrated = stored
            if stored.challenges.count > 1 {
                let candidate = stored.nextChallenge ?? stored.challenges.first
                if let candidate {
                    var only = candidate
                    if stored.solvedCount == 0 && PerceptionSetBundle.isAvailable {
                        only = ChallengeItem(kind: .perception, puzzleSeed: candidate.puzzleSeed)
                    }
                    migrated.challenges = [only]
                }
                if let encoded = try? JSONEncoder().encode(migrated) {
                    UserDefaults.standard.set(encoded, forKey: sessionKey)
                }
            }
            session = migrated
        }
        pendingLiveAlarmIDs = (UserDefaults.standard.stringArray(forKey: pendingIDsKey) ?? []).compactMap(UUID.init(uuidString:))
        restoreNextFireDates()
        for alarm in alarms { delivery[alarm.id] = alarm.enabled ? .pending : .off }
        #if canImport(AlarmKit)
        if #available(iOS 26.0, *) { usingSystemAlarms = true }
        #endif
        refreshPermissions()
    }

    // The calendar fallback is deliberately *foreground-only*. A Swift timer cannot
    // wake a suspended iPhone app. AlarmKit/notifications continue to handle that.
    private func followingOccurrence(_ alarm: WakeAlarm, after date: Date) -> Date {
        Calendar.current.nextDate(after: date,
                                  matching: DateComponents(hour: alarm.hour, minute: alarm.minute),
                                  matchingPolicy: .nextTime) ?? date.addingTimeInterval(24 * 60 * 60)
    }

    private func saveNextFireDates() {
        let values = Dictionary(uniqueKeysWithValues: nextFireDates.map { ($0.key.uuidString, $0.value.timeIntervalSince1970) })
        UserDefaults.standard.set(values, forKey: nextFireKey)
    }

    private func restoreNextFireDates() {
        let stored = UserDefaults.standard.dictionary(forKey: nextFireKey) as? [String: Double] ?? [:]
        let now = Date()
        nextFireDates.removeAll()
        for alarm in alarms where alarm.enabled {
            if let stamp = stored[alarm.id.uuidString] {
                let expected = Date(timeIntervalSince1970: stamp)
                // Keep an imminent or recently due alarm; don't launch a game
                // a day late after a reboot or an app update.
                if expected > now.addingTimeInterval(-90) {
                    nextFireDates[alarm.id] = expected
                    continue
                }
            }
            nextFireDates[alarm.id] = followingOccurrence(alarm, after: now)
        }
        saveNextFireDates()
    }

    func setAutomaticPresentationActive(_ active: Bool) {
        foregroundIsActive = active
        guard active else { return }
        // Register once. The stream publishes transitions to `.alerting` without
        // requiring a notification button press or web view callback.
        #if canImport(AlarmKit)
        if #available(iOS 26.0, *), alarmUpdatesTask == nil {
            alarmUpdatesTask = Task { @MainActor [weak self] in
                for await alarmList in AlarmManager.shared.alarmUpdates {
                    guard !Task.isCancelled else { break }
                    self?.handleAlarmKitUpdates(alarmList)
                }
            }
        }
        if #available(iOS 26.0, *) {
            do { handleAlarmKitUpdates(try AlarmManager.shared.alarms) }
            catch { print("[SnoozeLose Alarm] Could not inspect AlarmKit states: \(error)") }
        }
        #endif
        checkAutomaticAlarms(at: Date())
    }

    #if canImport(AlarmKit)
    @available(iOS 26.0, *)
    private func handleAlarmKitUpdates(_ alarmsFromSystem: [Alarm]) {
        guard foregroundIsActive else { return }
        for fired in alarmsFromSystem where fired.state == .alerting {
            if let saved = alarms.first(where: { $0.id == fired.id && $0.enabled }) {
                openAutomatically(saved.id, at: Date(), source: "AlarmKit")
            } else if let pending = session,
                      pending.snoozeSystemID == fired.id,
                      let saved = alarms.first(where: { $0.id == pending.alarmID && $0.enabled }) {
                // A snooze timer is separate from the repeating alarm's ID.
                openAutomatically(saved.id, at: Date(), source: "AlarmKit snooze")
            }
        }
    }
    #endif

    private func openAutomatically(_ id: UUID, at now: Date, source: String) {
        guard foregroundIsActive else { return }
        // AlarmKit emits several state snapshots per transition. A single alarm
        // occurrence must create only one session and one selected game.
        if let last = lastAutoOpen[id], now.timeIntervalSince(last) < 120 { return }
        guard let alarm = alarms.first(where: { $0.id == id && $0.enabled }) else { return }
        lastAutoOpen[id] = now
        if let expected = nextFireDates[id], now >= expected.addingTimeInterval(-90) {
            nextFireDates[id] = followingOccurrence(alarm, after: now)
            saveNextFireDates()
        }
        print("[SnoozeLose Alarm] Automatic challenge for \(id) from \(source)")
        startSession(for: id)
    }

    /// Called by the main-run-loop every second while the scene is active.
    /// This is a backup for foreground delivery and also resumes timed snoozes
    /// even if the user leaves SnoozeLose open for the entire snooze period.
    func checkAutomaticAlarms(at now: Date) {
        guard foregroundIsActive else { return }
        if let snoozeEnd = session?.resumeAt, snoozeEnd <= now, !isPractice {
            refreshSessionOnOpen()
        }
        for alarm in alarms where alarm.enabled {
            guard let expected = nextFireDates[alarm.id] else {
                nextFireDates[alarm.id] = followingOccurrence(alarm, after: now)
                saveNextFireDates()
                continue
            }
            guard now >= expected else { continue }
            // If the user returned long after the alarm, wait for the next
            // occurrence. An old calendar deadline must never open a random game.
            guard now.timeIntervalSince(expected) <= 90 else {
                nextFireDates[alarm.id] = followingOccurrence(alarm, after: now)
                saveNextFireDates()
                continue
            }
            openAutomatically(alarm.id, at: now, source: "foreground schedule")
        }
    }

    func state(for alarm: WakeAlarm) -> AlarmDelivery { delivery[alarm.id] ?? (alarm.enabled ? .pending : .off) }

    func askPermission() {
        Task { @MainActor in
            #if canImport(AlarmKit)
            if #available(iOS 26.0, *) {
                do { _ = try await AlarmManager.shared.requestAuthorization() }
                catch { feedback = "Alarm permission request failed: \(error.localizedDescription)" }
            }
            #endif
            do { _ = try await UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) }
            catch { feedback = "Notification permission request failed: \(error.localizedDescription)" }
            refreshPermissions()
            reapplyAlarmSchedules()
        }
    }

    func refreshPermissions() {
        Task { @MainActor in
            let settings = await UNUserNotificationCenter.current().notificationSettings()
            notificationsAllowed = settings.authorizationStatus == .authorized
        }
    }

    func saveAlarm(_ alarm: WakeAlarm) {
        // Never arm an alarm that points to a missing game implementation.
        guard alarm.game.isReady else {
            feedback = "\(alarm.game.title) is not installed. Choose an available game before saving."
            delivery[alarm.id] = .error(feedback)
            return
        }
        if let index = alarms.firstIndex(where: { $0.id == alarm.id }) { alarms[index] = alarm }
        else { alarms.append(alarm) }
        persistAlarms()
        // Reset the next expected occurrence when the saved time or enabled
        // state changes. A newly created alarm for this minute fires tomorrow,
        // matching iOS's repeating schedule instead of firing immediately.
        if alarm.enabled { nextFireDates[alarm.id] = followingOccurrence(alarm, after: Date()) }
        else { nextFireDates.removeValue(forKey: alarm.id) }
        saveNextFireDates()
        requestSchedule(alarm)
    }

    func reapplyAlarmSchedules() { alarms.forEach(requestSchedule) }

    func toggle(_ alarm: WakeAlarm) {
        var updated = alarm; updated.enabled.toggle(); saveAlarm(updated)
    }

    func delete(_ alarm: WakeAlarm) {
        alarms.removeAll { $0.id == alarm.id }
        nextFireDates.removeValue(forKey: alarm.id)
        lastAutoOpen.removeValue(forKey: alarm.id)
        saveNextFireDates()
        pendingLiveAlarmIDs.removeAll { $0 == alarm.id }
        UserDefaults.standard.set(pendingLiveAlarmIDs.map(\.uuidString), forKey: pendingIDsKey)
        if let active = session, active.alarmID == alarm.id {
            if let snoozeID = active.snoozeSystemID { cancelSnoozeSystemIfNeeded(id: snoozeID) }
            stopRinger()
            session = nil; showSession = false; isPractice = false
            UserDefaults.standard.removeObject(forKey: sessionKey)
        }
        persistAlarms()
        requestRemoval(id: alarm.id)
    }

    func reconcileSchedules() {
        Task { @MainActor in
            let requests = await UNUserNotificationCenter.current().pendingNotificationRequests()
            let known = Set(requests.map(\.identifier))
            #if canImport(AlarmKit)
            if #available(iOS 26.0, *) {
                // AlarmKit's `alarms` getter throws. Do not report an alarm as
                // unscheduled if the system merely refused to return its list.
                do {
                    let systemIDs = Set(try AlarmManager.shared.alarms.map(\.id))
                    for alarm in alarms {
                        if !alarm.enabled { delivery[alarm.id] = .off; continue }
                        if systemIDs.contains(alarm.id) { delivery[alarm.id] = .system }
                        else if known.contains(alarm.id.uuidString) { delivery[alarm.id] = .notification }
                        else { delivery[alarm.id] = .permissionRequired("No scheduled alert found. Check permissions, then retry.") }
                    }
                } catch {
                    let detail = error.localizedDescription
                    feedback = "Could not check AlarmKit schedules: \(detail). Retry after checking permissions."
                    for alarm in alarms {
                        if !alarm.enabled { delivery[alarm.id] = .off }
                        else if known.contains(alarm.id.uuidString) { delivery[alarm.id] = .notification }
                        else { delivery[alarm.id] = .error("System alarm status couldn't be verified: \(detail). Tap Retry.") }
                    }
                }
                refreshPermissions(); return
            }
            #endif
            for alarm in alarms {
                if !alarm.enabled { delivery[alarm.id] = .off }
                else if known.contains(alarm.id.uuidString) { delivery[alarm.id] = .notification }
                else { delivery[alarm.id] = .permissionRequired("No notification scheduled. Check permissions, then retry.") }
            }
            refreshPermissions()
        }
    }

    private func persistAlarms() {
        if let data = try? JSONEncoder().encode(alarms) { UserDefaults.standard.set(data, forKey: alarmsKey) }
    }

    private func persistSession() {
        if let active = session, !active.completed, !isPractice,
           let data = try? JSONEncoder().encode(active) { UserDefaults.standard.set(data, forKey: sessionKey) }
        else if !isPractice { UserDefaults.standard.removeObject(forKey: sessionKey) }
    }

    private func requestSchedule(_ alarm: WakeAlarm) {
        let revision = (revisions[alarm.id] ?? 0) + 1
        revisions[alarm.id] = revision
        delivery[alarm.id] = alarm.enabled ? .pending : .off
        let previous = schedulingQueue
        schedulingQueue = Task { @MainActor in
            await previous?.value
            guard revisions[alarm.id] == revision,
                  let current = alarms.first(where: { $0.id == alarm.id }), current == alarm else { return }
            await performSchedule(alarm)
        }
    }

    private func requestRemoval(id: UUID) {
        revisions[id, default: 0] += 1
        delivery.removeValue(forKey: id)
        let previous = schedulingQueue
        schedulingQueue = Task { @MainActor in
            await previous?.value
            await unschedule(id: id)
        }
    }

    private func unschedule(id: UUID) async {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [id.uuidString, "snooze-\(id.uuidString)"])
        #if canImport(AlarmKit)
        if #available(iOS 26.0, *) {
            do { try AlarmManager.shared.cancel(id: id) }
            catch { /* An absent/previously stopped alarm can be harmless here. */ }
        }
        #endif
    }

    private func performSchedule(_ alarm: WakeAlarm) async {
        await unschedule(id: alarm.id)
        guard alarm.enabled else { delivery[alarm.id] = .off; return }
        #if canImport(AlarmKit)
        if #available(iOS 26.0, *) {
            do {
                if AlarmManager.shared.authorizationState == .notDetermined {
                    _ = try await AlarmManager.shared.requestAuthorization()
                }
                if AlarmManager.shared.authorizationState == .authorized {
                    let stop = AlarmButton(text: "Stop", textColor: .white, systemImageName: "stop.circle.fill")
                    let open = AlarmButton(text: "Solve Challenge", textColor: .white, systemImageName: "puzzlepiece.fill")
                    let alert = AlarmPresentation.Alert(
                        title: LocalizedStringResource(stringLiteral: alarm.title),
                        stopButton: stop, secondaryButton: open, secondaryButtonBehavior: .custom)
                    let attributes = AlarmAttributes<EmptyAlarmMetadata>(presentation: AlarmPresentation(alert: alert), tintColor: .orange)
                    let relative = Alarm.Schedule.Relative(time: .init(hour: alarm.hour, minute: alarm.minute),
                        repeats: .weekly([.sunday, .monday, .tuesday, .wednesday, .thursday, .friday, .saturday]))
                    let sound: AlertConfiguration.AlertSound = alarm.sound == "Pulse" ? .named("Pulse") :
                        alarm.sound == "Sunrise" ? .named("Sunrise") : .default
                    let configuration = AlarmManager.AlarmConfiguration.alarm(
                        schedule: .relative(relative), attributes: attributes,
                        stopIntent: nil, secondaryIntent: OpenWakeChallengeIntent(alarmID: alarm.id.uuidString), sound: sound)
                    _ = try await AlarmManager.shared.schedule(id: alarm.id, configuration: configuration)
                    // Do not call a saved alarm "armed" merely because its schedule
                    // request returned. Confirm its ID with AlarmKit where possible.
                    // This lookup is also useful when the app has been relaunched.
                    do {
                        let registered = try AlarmManager.shared.alarms.contains { $0.id == alarm.id }
                        if registered {
                            delivery[alarm.id] = .system
                            feedback = alarm.sound == "Silent" ?
                                "System alarm armed; iOS uses its alarm sound even when Silent is selected." :
                                "\(alarm.timeLabel) system alarm armed. It can ring when SnoozeLose is closed."
                        } else {
                            delivery[alarm.id] = .pending
                            feedback = "iOS accepted the alarm request, but its registered state is still unconfirmed. Tap Retry if it remains pending."
                        }
                    } catch {
                        // A failed listing is not evidence of a failed schedule;
                        // do NOT register a second notification that may double-ring.
                        delivery[alarm.id] = .pending
                        feedback = "iOS accepted the alarm request, but SnoozeLose couldn't verify it yet: \(error.localizedDescription)"
                    }
                    return
                }
            } catch {
                feedback = "AlarmKit failed: \(error.localizedDescription). Checking notification fallback…"
            }
            // AlarmKit denied/unavailable: fallback is a normal notification, NOT a continuous alarm.
        }
        #endif
        do {
            let center = UNUserNotificationCenter.current()
            let settings = await center.notificationSettings()
            if settings.authorizationStatus == .notDetermined {
                _ = try await center.requestAuthorization(options: [.alert, .badge, .sound])
            }
            let finalSettings = await center.notificationSettings()
            guard finalSettings.authorizationStatus == .authorized else {
                delivery[alarm.id] = .permissionRequired("Notifications are off. Enable alerts and sound in iOS Settings, then tap Retry.")
                feedback = "\(alarm.timeLabel) saved, but NOT armed. Enable notification permission to continue."
                return
            }
            let content = UNMutableNotificationContent()
            content.title = "SnoozeLose • \(alarm.title)"
            content.body = "Wake up! Tap to open your challenge."
            // On older iOS this remains a single system notification, NOT a
            // continuous AlarmKit alarm. No priority bypass is requested.
            content.sound = alarm.sound == "Silent" ? nil :
                alarm.sound == "Default" ? .default : UNNotificationSound(named: UNNotificationSoundName(rawValue: alarm.sound + ".wav"))
            content.userInfo = ["alarmID": alarm.id.uuidString]
            let trigger = UNCalendarNotificationTrigger(dateMatching: DateComponents(hour: alarm.hour, minute: alarm.minute), repeats: true)
            try await center.add(UNNotificationRequest(identifier: alarm.id.uuidString, content: content, trigger: trigger))
            delivery[alarm.id] = .notification
            feedback = "\(alarm.timeLabel) scheduled as a notification, not a persistent alarm sound."
        } catch {
            delivery[alarm.id] = .error(error.localizedDescription)
            feedback = "\(alarm.timeLabel) saved but NOT armed: \(error.localizedDescription)"
        }
    }

    func testRinger(for alarm: WakeAlarm) {
        // The system owns lock-screen alarm delivery. When the user enters the
        // active challenge, SnoozeLose provides its own looping *foreground*
        // sound and opt-in light/vibration, even if the system alert was stopped.
        // iOS may still play an AlarmKit alert at the same time; hardware testing
        // must verify the resulting volume and any duplicate playback.
        guard !isPractice else { stopRinger(); return }
        if ringIsActive { return }  // Do not restart or layer a second player.
        ringer.start(sound: alarm.sound, vibrate: alarm.vibration, flash: alarm.flash)
        ringIsActive = true
    }

    func stopRinger() { ringer.stop(); ringIsActive = false }

    func stopForegroundEffectsForBackground() {
        // iOS does not allow a third-party app to enforce a full-screen challenge
        // or keep the LED torch active while backgrounded. AlarmKit remains the
        // source of system-managed lock-screen sound where available.
        stopRinger()
    }

    func resumeActiveForegroundEffectsIfNeeded() {
        guard !isPractice, let active = session, !active.completed,
              active.resumeAt == nil, active.nextChallenge != nil,
              let alarm = alarms.first(where: { $0.id == active.alarmID }) else { return }
        showSession = true
        testRinger(for: alarm)
    }

    func openFromNotification(_ identifier: String) {
        guard let id = UUID(uuidString: identifier),
              let alarm = alarms.first(where: { $0.id == id && $0.enabled }) else { return }
        // The user tapped an iOS notification/AlarmKit action. Honor it even
        // if the app woke outside the narrow foreground scheduling window.
        let now = Date()
        lastAutoOpen[id] = now
        if let expected = nextFireDates[id], now >= expected.addingTimeInterval(-90) {
            nextFireDates[id] = followingOccurrence(alarm, after: now)
            saveNextFireDates()
        }
        startSession(for: id)
    }

    // The selected game comes from the saved alarm. No per-alarm randomization.
    // Repeated occurrences keep that choice; snoozes never replace it.
    private func nextChallengeItem(for chosenGame: AlarmGame) -> ChallengeItem? {
        let seed = Calendar.current.ordinality(of: .day, in: .era, for: Date()) ?? 1
        switch chosenGame {
        case .perception:
            guard PerceptionSetBundle.isAvailable else {
                feedback = "Perception Set is missing from the app bundle. Cannot begin the selected challenge."
                return nil
            }
            return ChallengeItem(kind: .perception, puzzleSeed: seed)
        case .word:
            let item = ChallengeItem(kind: .word, puzzleSeed: seed)
            do {
                _ = try SnoozeLoseWordPuzzle.prepare(occurrenceID: item.id.uuidString)
                return item
            } catch {
                feedback = "Could not prepare Word Guess: \(error.localizedDescription). Retry this challenge."
                return nil
            }
        case .krillion:
            feedback = "Krillion is not playable yet: the uploaded Expo project is missing its game components."
            return nil
        }
    }

    func startSession(for id: UUID) {
        guard let alarm = alarms.first(where: { $0.id == id }) else { return }
        if isPractice { session = nil; isPractice = false; showSession = false }
        if var active = session, !active.completed {
            if active.alarmID != id {
                if !pendingLiveAlarmIDs.contains(id) { pendingLiveAlarmIDs.append(id) }
                UserDefaults.standard.set(pendingLiveAlarmIDs.map(\.uuidString), forKey: pendingIDsKey)
                feedback = "\(alarm.title) is waiting behind the unfinished \(alarmTitle(for: active.alarmID)) challenge."
                showSession = true
                return // Never play the new alarm's ringer while showing another alarm's challenge.
            }
            if let snoozeID = active.snoozeSystemID {
                cancelSnoozeSystemIfNeeded(id: snoozeID)
                UNUserNotificationCenter.current().removePendingNotificationRequests(
                    withIdentifiers: ["snooze-\(active.alarmID.uuidString)"])
                active.snoozeSystemID = nil
            }
            active.resumeAt = nil
            session = active
            persistSession()
        } else {
            guard let assigned = nextChallengeItem(for: alarm.game) else {
                // Keep the system alarm independent; do not silently switch to a
                // different puzzle or mark an unavailable game complete.
                showSession = false
                return
            }
            session = WakeSession(alarmID: id, startedOn: Date(), challenges: [assigned])
            persistSession()
        }
        showSession = true
        testRinger(for: alarm)
    }

    func previewAlarm(_ alarm: WakeAlarm) {
        guard session == nil else {
            feedback = "Finish the current alarm before starting a practice challenge."
            showSession = true
            return
        }
        guard let assigned = nextChallengeItem(for: alarm.game) else { return }
        isPractice = true
        session = WakeSession(alarmID: alarm.id, startedOn: Date(), challenges: [assigned])
        showSession = true
        stopRinger()
    }

    func endPractice() {
        guard isPractice else { return }
        isPractice = false
        session = nil
        showSession = false
    }

    func snooze() {
        guard !isPractice, var active = session, !active.isUnlocked else { return }
        stopRinger()
        stopSystemIfNeeded(id: active.alarmID)
        if let previous = active.snoozeSystemID { cancelSnoozeSystemIfNeeded(id: previous) }
        // Snoozing changes the reminder time, not the assigned game.
        // Exactly one game remains required for this alarm regardless of snoozes.
        active.snoozes += 1
        let date = Date().addingTimeInterval(TimeInterval(snoozeMinutes * 60))
        active.resumeAt = date
        active.snoozeSystemID = UUID()
        session = active
        persistSession()
        showSession = false
        let currentID = active.snoozeSystemID!
        Task { @MainActor in await scheduleSnooze(for: active, with: currentID, at: date) }
    }

    private func scheduleSnooze(for active: WakeSession, with id: UUID, at date: Date) async {
        guard session?.snoozeSystemID == id, !isPractice else { return }
        #if canImport(AlarmKit)
        if #available(iOS 26.0, *), AlarmManager.shared.authorizationState == .authorized {
            do {
                let stop = AlarmButton(text: "Stop", textColor: .white, systemImageName: "stop.circle.fill")
                let open = AlarmButton(text: "Solve Challenge", textColor: .white, systemImageName: "puzzlepiece.fill")
                let alert = AlarmPresentation.Alert(title: "Snooze is over", stopButton: stop, secondaryButton: open, secondaryButtonBehavior: .custom)
                let attributes = AlarmAttributes<EmptyAlarmMetadata>(presentation: AlarmPresentation(alert: alert), tintColor: .orange)
                let config = AlarmManager.AlarmConfiguration.timer(
                    duration: max(1, date.timeIntervalSinceNow), attributes: attributes,
                    stopIntent: nil, secondaryIntent: OpenWakeChallengeIntent(alarmID: active.alarmID.uuidString),
                    sound: .default)
                _ = try await AlarmManager.shared.schedule(id: id, configuration: config)
                // The session may have ended while scheduling; don't leave a ghost timer.
                if session?.snoozeSystemID != id { try? AlarmManager.shared.cancel(id: id) }
                else { feedback = "Snoozed for \(snoozeMinutes) min using an iOS system timer." }
                return
            } catch { feedback = "System snooze failed: \(error.localizedDescription). Checking notification fallback…" }
        }
        #endif
        do {
            let center = UNUserNotificationCenter.current()
            let settings = await center.notificationSettings()
            guard session?.snoozeSystemID == id, !isPractice else { return }
            guard settings.authorizationStatus == .authorized else {
                feedback = "Snooze reminder NOT armed: enable notifications in iOS Settings."
                return
            }
            let content = UNMutableNotificationContent()
            content.title = "Snooze is over"
            content.body = "Your wake-up game is ready. Finish it to complete this alarm."
            content.sound = .default
            content.userInfo = ["alarmID": active.alarmID.uuidString]
            let identifier = "snooze-\(active.alarmID.uuidString)"
            center.removePendingNotificationRequests(withIdentifiers: [identifier])
            try await center.add(UNNotificationRequest(identifier: identifier, content: content,
                trigger: UNTimeIntervalNotificationTrigger(timeInterval: max(1, date.timeIntervalSinceNow), repeats: false)))
            feedback = "Snoozed for \(snoozeMinutes) min using a notification (not a system alarm)."
        } catch { feedback = "Snooze reminder NOT armed: \(error.localizedDescription)" }
    }

    private func stopSystemIfNeeded(id: UUID) {
        #if canImport(AlarmKit)
        if #available(iOS 26.0, *) { try? AlarmManager.shared.stop(id: id) }
        #endif
    }
    private func cancelSnoozeSystemIfNeeded(id: UUID) {
        #if canImport(AlarmKit)
        if #available(iOS 26.0, *) { try? AlarmManager.shared.cancel(id: id) }
        #endif
    }

    func consumePendingNotification() {
        if let id = UserDefaults.standard.string(forKey: "snoozelose.pendingNotificationAlarmID") {
            UserDefaults.standard.removeObject(forKey: "snoozelose.pendingNotificationAlarmID")
            openFromNotification(id)
        }
    }

    func refreshSessionOnOpen() {
        guard let active = session, !active.completed, !isPractice else { return }
        if let date = active.resumeAt {
            guard date <= Date() else { return } // Deliberate snooze remains paused.
            var updated = active
            let expiredTimer = updated.snoozeSystemID
            updated.resumeAt = nil
            updated.snoozeSystemID = nil
            session = updated
            persistSession()
            if let expiredTimer { cancelSnoozeSystemIfNeeded(id: expiredTimer) }
            UNUserNotificationCenter.current().removePendingNotificationRequests(
                withIdentifiers: ["snooze-\(updated.alarmID.uuidString)"])
        }
        resumeActiveForegroundEffectsIfNeeded()
    }

    // An explicit user action can end a snooze early and resume the assigned games.
    // This does not mark any challenge complete, reset snooze penalties, or bypass scoring.
    // Older persisted sessions may predate the Perception Set bundle. If no game has
    // been solved, upgrade just the first challenge to the newly supplied first game.
    func playPendingChallengesNow() {
        guard !isPractice, var active = session, !active.completed,
              active.nextChallenge != nil else { return }

        // Invalidate the timer identifier before canceling it. A concurrent
        // snooze-scheduling Task checks this identifier before scheduling.
        let snoozeID = active.snoozeSystemID
        active.snoozeSystemID = nil
        active.resumeAt = nil
        session = active
        persistSession()
        if let snoozeID { cancelSnoozeSystemIfNeeded(id: snoozeID) }
        UNUserNotificationCenter.current().removePendingNotificationRequests(
            withIdentifiers: ["snooze-\(active.alarmID.uuidString)"])
        showSession = true
        resumeActiveForegroundEffectsIfNeeded()
        feedback = "Your selected wake-up game is ready. \(active.solvedCount) of 1 complete."
    }

    // Gameplay is unchanged; this is only the state-persistence boundary for the incoming game package.
    func complete(_ item: ChallengeItem) {
        guard var active = session,
              let index = active.challenges.firstIndex(where: { $0.id == item.id }),
              !active.challenges[index].solved else { return }
        active.challenges[index].solved = true
        session = active
        persistSession()
        // All required games are complete: stop both foreground effects and
        // an active system alert immediately. The success screen remains until
        // the user closes it; no extra tap is required to silence the alarm.
        if active.isUnlocked && !isPractice {
            stopRinger()
            stopSystemIfNeeded(id: active.alarmID)
            if let timer = active.snoozeSystemID {
                stopSystemIfNeeded(id: timer)
                cancelSnoozeSystemIfNeeded(id: timer)
            }
        }
    }

    func replaceChallenge(_ item: ChallengeItem) {
        guard var active = session,
              let index = active.challenges.firstIndex(where: { $0.id == item.id }) else { return }
        // Legacy prototype games used this route; the user's chosen game is
        // now fixed for an alarm, so never replace it with a random game.
        feedback = "This alarm uses the game you selected when creating it. Edit the alarm to change future games."
        _ = active.challenges[index]
    }

    func dismiss() {
        guard let active = session, active.isUnlocked else { return }
        if isPractice { endPractice(); return }
        stopRinger()
        stopSystemIfNeeded(id: active.alarmID)
        if let timer = active.snoozeSystemID {
            stopSystemIfNeeded(id: timer)
            cancelSnoozeSystemIfNeeded(id: timer)
        }
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: ["snooze-\(active.alarmID.uuidString)"])
        session = nil
        persistSession()
        showSession = false
        if !pendingLiveAlarmIDs.isEmpty {
            let next = pendingLiveAlarmIDs.removeFirst()
            UserDefaults.standard.set(pendingLiveAlarmIDs.map(\.uuidString), forKey: pendingIDsKey)
            Task { @MainActor in
                await Task.yield()
                self.startSession(for: next)
            }
        }
    }

    func alarmTitle(for id: UUID) -> String { alarms.first(where: { $0.id == id })?.title ?? "Wake up!" }
}

#if canImport(AlarmKit)
@available(iOS 26.0, *)
struct EmptyAlarmMetadata: AlarmMetadata {}
#endif

#if canImport(AlarmKit)
@available(iOS 26.0, *)
struct OpenWakeChallengeIntent: LiveActivityIntent {
    static var title: LocalizedStringResource = "Solve Wake-up Challenge"
    static var description = IntentDescription("Open SnoozeLose to solve the wake-up game.")
    static var openAppWhenRun: Bool = true

    @Parameter(title: "Alarm ID") var alarmID: String

    init(alarmID: String) { self.alarmID = alarmID }
    init() { self.alarmID = "" }

    func perform() async throws -> some IntentResult {
        // App is launched by the system, then reads the pending ID on activation.
        UserDefaults.standard.set(alarmID, forKey: "snoozelose.pendingNotificationAlarmID")
        return .result()
    }
}
#endif
