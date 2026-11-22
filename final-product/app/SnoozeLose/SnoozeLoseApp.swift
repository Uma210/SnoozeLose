import SwiftUI
import UserNotifications
#if canImport(AlarmKit)
import AlarmKit
#endif

@main
struct SnoozeLoseApp: App {
    @UIApplicationDelegateAdaptor(SnoozeAppDelegate.self) var delegate
    @StateObject private var model = SnoozeModel()
    @Environment(\.scenePhase) private var scenePhase

    var body: some Scene {
        WindowGroup {
            PebbleWorldView()
                .environmentObject(model)
                .preferredColorScheme(.light)
                .onAppear {
                    model.setAutomaticPresentationActive(UIApplication.shared.applicationState == .active)
                    model.consumePendingNotification()
                    model.refreshSessionOnOpen()
                }
                .snoozeOnChange(of: scenePhase) { phase in
                    if phase != .active {
                        model.setAutomaticPresentationActive(false)
                        model.stopForegroundEffectsForBackground()
                    } else {
                        model.setAutomaticPresentationActive(true)
                        model.consumePendingNotification()
                        model.refreshSessionOnOpen()
                    }
                }
                // A WKWebView is not the alarm scheduler. This native monitor
                // presents the game automatically at the due time in foreground.
                .onReceive(Timer.publish(every: 1, on: .main, in: .common).autoconnect()) { date in
                    model.checkAutomaticAlarms(at: date)
                }
                .onReceive(NotificationCenter.default.publisher(for: .snoozeNotificationOpened)) { note in
                    if let id = note.userInfo?["alarmID"] as? String {
                        model.openFromNotification(id)
                    }
                }
        }
    }
}

extension Notification.Name {
    static let snoozeNotificationOpened = Notification.Name("SnoozeLoseNotificationOpened")
}

final class SnoozeAppDelegate: NSObject, UIApplicationDelegate, UNUserNotificationCenterDelegate {
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil) -> Bool {
        UNUserNotificationCenter.current().delegate = self
        print("[SnoozeLose Startup] App delegate launched successfully")
        return true
    }

    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        if let id = response.notification.request.content.userInfo["alarmID"] as? String {
            UserDefaults.standard.set(id, forKey: "snoozelose.pendingNotificationAlarmID")
            DispatchQueue.main.async {
                NotificationCenter.default.post(name: .snoozeNotificationOpened, object: nil, userInfo: ["alarmID": id])
            }
        }
        completionHandler()
    }

    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        // When already in the foreground, open the matching challenge instead of
        // requiring an extra banner tap; background delivery is always iOS-controlled.
        if let id = notification.request.content.userInfo["alarmID"] as? String {
            DispatchQueue.main.async {
                NotificationCenter.default.post(name: .snoozeNotificationOpened, object: nil, userInfo: ["alarmID": id])
            }
        }
        completionHandler([.banner, .sound, .list])
    }
}

// MARK: - SwiftUI change observation compatible with iOS 16 and newer
// iOS 17 deprecates the one-argument onChange closure. Keep the existing
// state-handling semantics without raising our iOS 16 deployment target.
extension View {
    @ViewBuilder
    func snoozeOnChange<Value: Equatable>(
        of value: Value,
        perform action: @escaping (Value) -> Void
    ) -> some View {
        if #available(iOS 17.0, *) {
            self.onChange(of: value) { _, newValue in
                action(newValue)
            }
        } else {
            self.snoozeLegacyOnChange(of: value, perform: action)
        }
    }

    // Only compiled as a possible runtime path before iOS 17, where the
    // single-value onChange overload is not deprecated.
    @available(iOS, introduced: 16.0, obsoleted: 17.0)
    private func snoozeLegacyOnChange<Value: Equatable>(
        of value: Value,
        perform action: @escaping (Value) -> Void
    ) -> some View {
        self.onChange(of: value, perform: action)
    }
}
