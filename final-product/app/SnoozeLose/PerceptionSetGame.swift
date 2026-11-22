import SwiftUI
import WebKit

// The local Perception Set is one challenge containing four sequential rounds.
// It is selected FIRST for newly created alarm sessions; SnoozeLose owns alarm
// state and dismissal. No network access is needed for the bundled HTML.
enum PerceptionSetBundle {
    static var entryPoint: URL? {
        Bundle.main.url(forResource: "index", withExtension: "html", subdirectory: "PerceptionSet")
    }
    static var isAvailable: Bool { entryPoint != nil }
}

struct PerceptionWakeScreen: View {
    @EnvironmentObject private var model: SnoozeModel
    let item: ChallengeItem

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 10) {
                Image(systemName: "alarm.fill")
                    .foregroundStyle(Color(red: 0.12, green: 0.40, blue: 0.34))
                    .accessibilityHidden(true)
                VStack(alignment: .leading, spacing: 2) {
                    Text(model.isPractice ? "PRACTICE · PERCEPTION SET" : "WAKE-UP CHALLENGE")
                        .font(.system(size: 11, weight: .heavy, design: .monospaced))
                        .tracking(0.8)
                    Text(model.isPractice ? "Practice mode · alarm unaffected" : "Finish the set to advance")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(.secondary)
                }
                Spacer(minLength: 6)
                if let session = model.session {
                    Text("\(session.solvedCount + 1) / \(session.requiredCount)")
                        .font(.system(size: 15, weight: .bold, design: .monospaced))
                        .monospacedDigit()
                        .accessibilityLabel("Challenge \(session.solvedCount + 1) of \(session.requiredCount)")
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(Color(red: 0.96, green: 0.99, blue: 1))

            PerceptionSetGame(item: item) { model.complete(item) }
                .frame(maxWidth: .infinity, maxHeight: .infinity)

            HStack(spacing: 12) {
                if model.isPractice {
                    Button("Exit practice") { model.endPractice() }
                        .frame(maxWidth: .infinity, minHeight: 44)
                        .buttonStyle(.bordered)
                } else {
                    Button { model.snooze() } label: {
                        Label("Snooze 5 min", systemImage: "moon.zzz.fill")
                            .frame(maxWidth: .infinity, minHeight: 44)
                    }
                    .buttonStyle(.bordered)
                    if model.ringIsActive {
                        Button { model.stopRinger() } label: {
                            Label("Silence effects", systemImage: "speaker.slash.fill")
                                .frame(maxWidth: .infinity, minHeight: 44)
                        }.buttonStyle(.bordered)
                    }
                }
            }
            .font(.system(size: 13, weight: .semibold))
            .padding(.horizontal, 14)
            .padding(.vertical, 9)
            .background(Color(red: 0.94, green: 0.98, blue: 1))
        }
        .background(Color(red: 0.89, green: 0.94, blue: 0.98))
        .preferredColorScheme(.light)
    }
}

struct PerceptionSetGame: View {
    let item: ChallengeItem
    let onSuccess: () -> Void
    @State private var loadError: String?
    @State private var retryID = UUID()

    var body: some View {
        ZStack {
            if let indexURL = PerceptionSetBundle.entryPoint {
                PerceptionSetWebView(indexURL: indexURL,
                                     seed: item.puzzleSeed,
                                     onSuccess: onSuccess,
                                     onError: { loadError = $0 })
                    .id(retryID)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .accessibilityLabel("Four-round Perception Set")
            } else {
                Text("The Perception Set game is missing. This challenge has not been completed.")
                    .foregroundStyle(.red)
                    .multilineTextAlignment(.center)
                    .padding(22)
            }
            if let loadError {
                VStack(spacing: 14) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.system(size: 29)).foregroundStyle(.orange)
                    Text("Can't load the perception game")
                        .font(.headline)
                    Text(loadError).font(.footnote).multilineTextAlignment(.center)
                    Button("Retry game") { self.loadError = nil; retryID = UUID() }
                        .buttonStyle(.borderedProminent)
                        .frame(minHeight: 44)
                }
                .padding(24)
                .frame(maxWidth: 350)
                .background(Color.white, in: RoundedRectangle(cornerRadius: 20))
                .shadow(radius: 14)
                .padding(12)
            }
        }
    }
}

private struct PerceptionSetWebView: UIViewRepresentable {
    let indexURL: URL
    let seed: Int
    let onSuccess: () -> Void
    let onError: (String) -> Void

    func makeCoordinator() -> Coordinator {
        Coordinator(onSuccess: onSuccess, onError: onError)
    }

    func makeUIView(context: Context) -> WKWebView {
        let config = WKWebViewConfiguration()
        config.defaultWebpagePreferences.allowsContentJavaScript = true
        let controller = WKUserContentController()
        let token = context.coordinator.token
        let script = """
        (function () {
          window.__snoozeEmbedded = true;
          const token = '\(token)';
          Object.defineProperty(window, 'SnoozeLosePerception', {
            value: Object.freeze({
              seed: \(seed),
              complete: function (result) {
                if (!result || result.won !== true || !Array.isArray(result.scores)) return;
                window.webkit.messageHandlers.perceptionGame.postMessage({
                  type: 'complete', token: token, scores: result.scores,
                  average: result.average, rounds: result.rounds
                });
              }
            }), configurable: false
          });
        })();
        """
        controller.addUserScript(WKUserScript(source: script, injectionTime: .atDocumentStart,
                                               forMainFrameOnly: true))
        controller.add(context.coordinator, name: "perceptionGame")
        config.userContentController = controller

        let view = WKWebView(frame: .zero, configuration: config)
        view.navigationDelegate = context.coordinator
        view.scrollView.isScrollEnabled = false
        view.scrollView.bounces = false
        view.isOpaque = false
        view.backgroundColor = UIColor(red: 0.89, green: 0.94, blue: 0.98, alpha: 1)
        // Everything stays offline. No remote host, fonts, or asset dependency.
        view.loadFileURL(indexURL, allowingReadAccessTo: indexURL.deletingLastPathComponent())
        return view
    }

    func updateUIView(_ uiView: WKWebView, context: Context) {}

    static func dismantleUIView(_ uiView: WKWebView, coordinator: Coordinator) {
        uiView.stopLoading()
        uiView.navigationDelegate = nil
        uiView.configuration.userContentController.removeScriptMessageHandler(forName: "perceptionGame")
    }

    final class Coordinator: NSObject, WKScriptMessageHandler, WKNavigationDelegate {
        let token = UUID().uuidString
        let onSuccess: () -> Void
        let onError: (String) -> Void
        private var completed = false

        init(onSuccess: @escaping () -> Void, onError: @escaping (String) -> Void) {
            self.onSuccess = onSuccess
            self.onError = onError
            super.init()
        }

        func userContentController(_ userContentController: WKUserContentController,
                                   didReceive message: WKScriptMessage) {
            guard !completed, message.name == "perceptionGame", message.frameInfo.isMainFrame,
                  let payload = message.body as? [String: Any],
                  payload["type"] as? String == "complete",
                  payload["token"] as? String == token,
                  let scores = payload["scores"] as? [NSNumber], scores.count == 4,
                  scores.allSatisfy({ $0.intValue >= 0 && $0.intValue <= 100 && $0.doubleValue == Double($0.intValue) }),
                  let avg = payload["average"] as? NSNumber,
                  let rounds = payload["rounds"] as? NSNumber, rounds.intValue == 4,
                  avg.intValue >= 70, avg.intValue <= 100,
                  avg.doubleValue == Double(avg.intValue),
                  avg.intValue == Int((Double(scores.reduce(0) { $0 + $1.intValue }) / 4.0).rounded())
            else { return }
            completed = true
            DispatchQueue.main.async { self.onSuccess() }
        }

        func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
            DispatchQueue.main.async { self.onError("Game load failed: \(error.localizedDescription)") }
        }
        func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
            DispatchQueue.main.async { self.onError("Game load failed: \(error.localizedDescription)") }
        }
        func webViewWebContentProcessDidTerminate(_ webView: WKWebView) {
            DispatchQueue.main.async { self.onError("The game stopped unexpectedly. Retry to reopen it.") }
        }
    }
}
