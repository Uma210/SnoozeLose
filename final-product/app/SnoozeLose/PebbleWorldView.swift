import SwiftUI
import WebKit

struct PebbleWorldView: View {
    @EnvironmentObject private var model: SnoozeModel
    @State private var showAddAlarm = false
    @State private var showSettings = false
    @State private var showAlarms = false
    @State private var alertText: String?
    @State private var webStatus: PebbleWebStatus = .loading
    @State private var webVersion = 0
    // Native UI appears before expensive WebKit initialization.
    @State private var webBootStarted = false
    @State private var didBootstrap = false
    @Environment(\.scenePhase) private var scenePhase

    private var nextAlarm: WakeAlarm? {
        let calendar = Calendar.current
        let now = Date()
        return model.alarms.filter(\.enabled).min { a, b in
            let nextA = calendar.nextDate(after: now, matching: DateComponents(hour: a.hour, minute: a.minute), matchingPolicy: .nextTime) ?? .distantFuture
            let nextB = calendar.nextDate(after: now, matching: DateComponents(hour: b.hour, minute: b.minute), matchingPolicy: .nextTime) ?? .distantFuture
            return nextA < nextB
        }
    }

    var body: some View {
        ZStack {
            // Native SwiftUI is always mounted. A broken WebKit process cannot
            // prevent access to the alarm controls on the first frame.
            if webBootStarted {
                PebbleWebView(isActive: scenePhase == .active && !model.showSession, status: $webStatus) { action in
                    switch action {
                    case "add": showAddAlarm = true
                    case "alarms": showAlarms = true
                    case "settings": showSettings = true
                    case "test":
                        if let alarm = model.alarms.first { model.previewAlarm(alarm) }
                        else { alertText = "Create an alarm first, then tap Test to play a wake-up challenge." }
                    default: break
                    }
                }
                .id(webVersion)
                .opacity(webStatus == .ready ? 1 : 0)
                .allowsHitTesting(webStatus == .ready)
            }

            if !webBootStarted || webStatus == .loading {
                PebbleLoadingScreen(
                    onAdd: { showAddAlarm = true },
                    onAlarms: { showAlarms = true })
            } else if case .failed(let reason) = webStatus {
                PebbleFallbackScreen(
                    reason: reason,
                    onRetry: {
                        webStatus = .loading
                        webVersion += 1
                    },
                    onAdd: { showAddAlarm = true },
                    onAlarms: { showAlarms = true })
            }
        }
        .background(Color(red: 0.91, green: 0.96, blue: 0.99))
        .safeAreaInset(edge: .bottom, spacing: 0) { alarmDock }
        .ignoresSafeArea(edges: .top)
        .sheet(isPresented: $showAddAlarm) { AlarmEditor(existing: nil) }
        .sheet(isPresented: $showSettings) { StudioSettingsView() }
        .sheet(isPresented: $showAlarms) { PebbleAlarmsSheet() }
        .fullScreenCover(isPresented: $model.showSession) { WakeChallengeSession().interactiveDismissDisabled(true) }
        .snoozeOnChange(of: model.showSession) { visible in
            guard visible && !model.isPractice else { return }
            // A due alarm takes priority over alarm editing and pet settings.
            showAddAlarm = false
            showAlarms = false
            showSettings = false
        }
        .alert("Create an alarm", isPresented: Binding(get: { alertText != nil }, set: { if !$0 { alertText = nil } })) {
            Button("OK", role: .cancel) { alertText = nil }
        } message: { Text(alertText ?? "") }
        .onAppear {
            guard !didBootstrap else { return }
            didBootstrap = true
            print("[SnoozeLose Startup] Native home appeared. WebKit will load separately.")
            // Paint native content first; defer the full animated web world.
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.50) {
                webBootStarted = true
            }
            // Do not block initial rendering on alarm status reconciliation.
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                model.refreshSessionOnOpen()
                model.refreshPermissions()
                model.consumePendingNotification()
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.20) {
                model.reconcileSchedules()
            }
        }
        .snoozeOnChange(of: scenePhase) { phase in
            if phase == .active { model.refreshSessionOnOpen(); model.refreshPermissions(); model.consumePendingNotification(); model.reconcileSchedules() }
        }
    }

    private var alarmDock: some View {
        Button { showAlarms = true } label: {
            HStack(spacing: 14) {
                Image(systemName: "alarm.fill")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundStyle(Color(red: 0.18, green: 0.42, blue: 0.53))
                    .frame(width: 48, height: 48)
                    .background(Color(red: 0.88, green: 0.96, blue: 1), in: RoundedRectangle(cornerRadius: 15))
                VStack(alignment: .leading, spacing: 5) {
                    Text(nextAlarm == nil ? "MY ALARMS" : "NEXT WAKE-UP")
                        .font(.system(size: 11, weight: .bold, design: .monospaced))
                        .tracking(0.5)
                        .foregroundStyle(Color(red: 0.36, green: 0.49, blue: 0.59))
                    Text(nextAlarm?.timeLabel ?? "No alarms scheduled")
                        .font(.system(size: nextAlarm == nil ? 16 : 24, weight: .bold, design: .monospaced))
                        .lineLimit(1)
                        .minimumScaleFactor(0.75)
                        .foregroundStyle(Color(red: 0.15, green: 0.31, blue: 0.42))
                    if let alarm = nextAlarm {
                        let state = model.state(for: alarm)
                        Text(state.title)
                            .font(.system(size: 10, weight: .semibold))
                            .foregroundStyle(state.isArmed ? Color(red: 0.15, green: 0.43, blue: 0.37) : .orange)
                            .lineLimit(2)
                    }
                }
                Spacer(minLength: 6)
                Image(systemName: "chevron.right")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(Color(red: 0.33, green: 0.50, blue: 0.61))
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 14)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Manage alarms. Next alarm: \(nextAlarm?.timeLabel ?? "none scheduled")")
        .accessibilityHint("Opens your scheduled alarms")
        .background(Color(red: 0.94, green: 0.98, blue: 1))
        .overlay(alignment: .top) {
            Rectangle().fill(Color(red: 0.72, green: 0.84, blue: 0.91)).frame(height: 1)
        }
    }

}

private struct PebbleAlarmsSheet: View {
    @EnvironmentObject private var model: SnoozeModel
    @Environment(\.dismiss) private var dismiss
    @State private var adding = false
    @State private var editing: WakeAlarm?
    @State private var deleteCandidate: WakeAlarm?
    var body: some View {
        NavigationStack {
            List {
                if !model.feedback.isEmpty {
                    Section("Latest scheduling update") {
                        Text(model.feedback).font(.footnote).foregroundStyle(.secondary)
                    }
                }
                if model.alarms.isEmpty {
                    Text("No alarms yet. Create your first wake-up quest!")
                }
                ForEach(model.alarms) { alarm in
                    VStack(alignment: .leading, spacing: 11) {
                        HStack(alignment: .top) {
                            VStack(alignment: .leading, spacing: 3) {
                                Text(alarm.timeLabel).font(.title2.monospacedDigit()).fontWeight(.bold)
                                Text(alarm.title).font(.subheadline)
                                Label(alarm.game.title, systemImage: "gamecontroller.fill")
                                    .font(.caption).foregroundStyle(Studio.muted)
                                Text(model.state(for: alarm).title)
                                    .font(.caption).fontWeight(.semibold)
                                    .foregroundStyle(model.state(for: alarm).isArmed ? Color.green : Color.orange)
                                Text(model.state(for: alarm).detail).font(.caption2).foregroundStyle(.secondary)
                            }
                            Spacer()
                            Toggle("Enable alarm", isOn: Binding(
                                get: { model.alarms.first(where: { $0.id == alarm.id })?.enabled ?? false },
                                set: { newValue in
                                    guard let current = model.alarms.first(where: { $0.id == alarm.id }), current.enabled != newValue else { return }
                                    model.toggle(current)
                                }))
                                .labelsHidden()
                                .accessibilityLabel("Enable alarm at \(alarm.timeLabel)")
                        }
                        HStack(spacing: 10) {
                            Button("Edit") { editing = alarm }
                            Button("Test") { model.previewAlarm(alarm); dismiss() }
                            Button("Retry") { model.saveAlarm(alarm) }
                            Spacer()
                            Button("Delete", role: .destructive) { deleteCandidate = alarm }
                        }
                        .font(.subheadline)
                        .buttonStyle(.borderless)
                    }.padding(.vertical, 4)
                }
            }
            .navigationTitle("My alarms")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) { Button("Done") { dismiss() } }
                ToolbarItem(placement: .topBarTrailing) {
                    Button { adding = true } label: { Image(systemName: "plus") }.accessibilityLabel("Add alarm")
                }
            }
            .sheet(isPresented: $adding) { AlarmEditor(existing: nil) }
            .sheet(item: $editing) { alarm in AlarmEditor(existing: alarm) }
            .confirmationDialog("Delete this alarm?", isPresented: Binding(
                get: { deleteCandidate != nil }, set: { if !$0 { deleteCandidate = nil } }), titleVisibility: .visible) {
                    if let candidate = deleteCandidate {
                        Button("Delete \(candidate.timeLabel)", role: .destructive) { model.delete(candidate); deleteCandidate = nil }
                    }
                    Button("Cancel", role: .cancel) { deleteCandidate = nil }
                } message: { Text("This removes the scheduled system alarm or notification too.") }
            .onAppear { model.reconcileSchedules() }
        }
    }
}


// Always keep app navigation available even if the HTML asset or WebKit process fails.
private enum PebbleWebStatus: Equatable {
    case loading
    case ready
    case failed(String)
}

private struct PebbleLoadingScreen: View {
    let onAdd: () -> Void
    let onAlarms: () -> Void
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var floating = false
    var body: some View {
        ZStack {
            LinearGradient(colors: [Color(red: 0.88, green: 0.96, blue: 1),
                                    Color(red: 0.69, green: 0.83, blue: 0.91)],
                           startPoint: .top, endPoint: .bottom).ignoresSafeArea()
            VStack(spacing: 22) {
                ZStack {
                    Circle().fill(.white.opacity(0.33))
                        .frame(width: 184, height: 184)
                    // This is the original expressive Pebble artwork captured
                    // from the supplied SVG, not a substitute mascot.
                    Image("PebbleLoading")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 204, height: 214)
                }
                .offset(y: reduceMotion ? 0 : (floating ? -6 : 6))
                .accessibilityHidden(true)

                VStack(spacing: 9) {
                    Text("snoozeLOSE")
                        .font(.system(size: 31, weight: .black, design: .rounded))
                        .foregroundStyle(Color(red: 0.15, green: 0.34, blue: 0.43))
                    Text("WAKE UP. LEVEL UP.")
                        .font(.system(size: 16, weight: .black, design: .monospaced))
                        .foregroundStyle(Color(red: 0.20, green: 0.39, blue: 0.48))
                    ProgressView("Getting Pebble ready…")
                        .tint(Color(red: 0.14, green: 0.48, blue: 0.40))
                        .font(.footnote)
                        .padding(.top, 12)
                }
                // Functional native controls remain available during slow/failed
                // WebKit startup; this is not a blocking splash screen.
                VStack(spacing: 10) {
                    Button(action: onAdd) {
                        Label("Set an alarm", systemImage: "plus.circle.fill")
                            .frame(maxWidth: .infinity)
                            .frame(minHeight: 48)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(Color(red: 0.15, green: 0.46, blue: 0.39))
                    Button(action: onAlarms) {
                        Label("My alarms", systemImage: "alarm.fill")
                            .frame(maxWidth: .infinity)
                            .frame(minHeight: 48)
                    }
                    .buttonStyle(.bordered)
                }
                .frame(maxWidth: 300)
                .padding(.top, 12)
            }
        }
        .onAppear {
            if !reduceMotion {
                withAnimation(.easeInOut(duration: 1.2).repeatForever(autoreverses: true)) {
                    floating = true
                }
            }
        }
    }
}

private struct PebbleFallbackScreen: View {
    let reason: String
    let onRetry: () -> Void
    let onAdd: () -> Void
    let onAlarms: () -> Void
    var body: some View {
        ZStack {
            Color(red: 0.89, green: 0.96, blue: 0.99).ignoresSafeArea()
            ScrollView {
                VStack(spacing: 18) {
                    Image(systemName: "alarm.waves.left.and.right.fill")
                        .font(.system(size: 51)).foregroundStyle(Color(red: 0.19, green: 0.46, blue: 0.43))
                    Text("SnoozeLose")
                        .font(.system(size: 31, weight: .black, design: .rounded))
                    Text("Pebble couldn't load, but your alarms are still available.")
                        .font(.headline).multilineTextAlignment(.center)
                    Text(reason)
                        .font(.footnote).foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                    Button(action: onRetry) {
                        Label("Retry home screen", systemImage: "arrow.clockwise")
                            .frame(maxWidth: .infinity).frame(minHeight: 48)
                    }.buttonStyle(.borderedProminent)
                    Button(action: onAlarms) {
                        Label("My alarms", systemImage: "alarm")
                            .frame(maxWidth: .infinity).frame(minHeight: 48)
                    }.buttonStyle(.bordered)
                    Button(action: onAdd) {
                        Label("Set an alarm", systemImage: "plus")
                            .frame(maxWidth: .infinity).frame(minHeight: 48)
                    }.buttonStyle(.bordered)
                    Text("Existing scheduled iOS alerts are managed separately from the animation.")
                        .font(.caption).foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding(24)
                .padding(.top, 70)
            }
        }
    }
}

private struct PebbleWebView: UIViewRepresentable {
    let isActive: Bool
    @Binding var status: PebbleWebStatus
    let onAction: (String) -> Void

    func makeCoordinator() -> Coordinator {
        Coordinator(status: $status, onAction: onAction)
    }

    func makeUIView(context: Context) -> WKWebView {
        let config = WKWebViewConfiguration()
        config.defaultWebpagePreferences.allowsContentJavaScript = true
        config.allowsInlineMediaPlayback = true
        config.userContentController.add(context.coordinator, name: "snooze")
        let web = WKWebView(frame: .zero, configuration: config)
        web.isOpaque = false
        web.backgroundColor = UIColor(red: 0.91, green: 0.96, blue: 0.99, alpha: 1)
        web.scrollView.contentInsetAdjustmentBehavior = .never
        web.navigationDelegate = context.coordinator

        // Xcode copies PebbleWorld as a folder reference. Explicitly grant
        // read access to this directory (including CSS, JS, SVG and iframe).
        let folder = Bundle.main.resourceURL?.appendingPathComponent("PebbleWorld", isDirectory: true)
        let index = Bundle.main.url(forResource: "index", withExtension: "html", subdirectory: "PebbleWorld")
            ?? folder?.appendingPathComponent("index.html")
        if let url = index, FileManager.default.fileExists(atPath: url.path) {
            print("[SnoozeLose WebKit] Loading local home page: \(url.path)")
            web.loadFileURL(url, allowingReadAccessTo: url.deletingLastPathComponent())
        } else {
            print("[SnoozeLose WebKit] Missing PebbleWorld/index.html from app bundle")
            context.coordinator.report(.failed("Home screen files are missing from the app bundle. Check the PebbleWorld folder reference in Copy Bundle Resources."))
        }
        return web
    }

    func updateUIView(_ uiView: WKWebView, context: Context) {
        guard context.coordinator.lastActive != isActive else { return }
        context.coordinator.lastActive = isActive
        if !isActive {
            uiView.evaluateJavaScript("window.snoozeStopPebble && window.snoozeStopPebble();", completionHandler: nil)
        }
    }

    static func dismantleUIView(_ uiView: WKWebView, coordinator: Coordinator) {
        uiView.evaluateJavaScript("window.snoozeStopPebble && window.snoozeStopPebble();", completionHandler: nil)
        uiView.configuration.userContentController.removeScriptMessageHandler(forName: "snooze")
        uiView.navigationDelegate = nil
        uiView.stopLoading()
    }

    final class Coordinator: NSObject, WKScriptMessageHandler, WKNavigationDelegate {
        private var status: Binding<PebbleWebStatus>
        private let onAction: (String) -> Void
        let openedAt = Date()
        var lastActive: Bool?
        private var didResolve = false
        private var hasFatalError = false

        init(status: Binding<PebbleWebStatus>, onAction: @escaping (String) -> Void) {
            self.status = status
            self.onAction = onAction
            // NSObject must be initialized before a closure may capture self.
            super.init()
            // A stalled local WKWebView must not leave a permanent loading spinner.
            DispatchQueue.main.asyncAfter(deadline: .now() + 10) { [weak self] in
                guard let self = self, !self.didResolve else { return }
                self.report(.failed("The home screen took too long to load. Check the PebbleWorld resources, then tap Retry."))
            }
        }
        func report(_ newValue: PebbleWebStatus) {
            DispatchQueue.main.async { [weak self] in
                guard let self = self else { return }
                // Errors always override readiness; a late success must not
                // hide the failure, including a WebKit process termination.
                switch newValue {
                case .loading: break
                case .ready:
                    guard !self.hasFatalError else { return }
                    self.didResolve = true
                case .failed:
                    self.hasFatalError = true
                    self.didResolve = true
                }
                self.status.wrappedValue = newValue
            }
        }
        func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
            guard let action = message.body as? String else { return }
            DispatchQueue.main.async { [weak self] in self?.onAction(action) }
        }
        func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            // A successful HTTP/file navigation is not enough; verify the actual
            // expected DOM exists to avoid silently showing an empty WKWebView.
            webView.evaluateJavaScript("Boolean(document.querySelector('#hero') && document.querySelector('#pet-frame') && document.body && document.body.innerText.length > 40)") { [weak self] result, error in
                guard let self = self else { return }
                if let error = error {
                    self.report(.failed("The home page couldn't initialize: \\(error.localizedDescription)"))
                } else if (result as? Bool) == true {
                    // Show the intended loading animation briefly when disk IO is fast.
                    let delay = max(0, 0.65 - Date().timeIntervalSince(self.openedAt))
                    DispatchQueue.main.asyncAfter(deadline: .now() + delay) { [weak self] in self?.report(.ready) }
                } else {
                    self.report(.failed("The home screen opened but its expected content did not render."))
                }
            }
        }
        func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
            report(.failed("Could not load Pebble's home screen: \\(error.localizedDescription)"))
        }
        func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
            report(.failed("Home screen resources failed to load: \\(error.localizedDescription)"))
        }
        func webViewWebContentProcessDidTerminate(_ webView: WKWebView) {
            report(.failed("The home screen process stopped. Tap Retry to restore Pebble."))
        }
    }
}
