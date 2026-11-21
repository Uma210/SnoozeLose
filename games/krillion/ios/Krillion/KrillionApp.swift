import Foundation
import SwiftUI
import WebKit

@main
struct KrillionApp: App {
    var body: some Scene {
        WindowGroup {
            GameView()
        }
    }
}

private struct GameView: UIViewRepresentable {
    func makeCoordinator() -> PromptHistory {
        PromptHistory()
    }

    func makeUIView(context: Context) -> WKWebView {
        let configuration = WKWebViewConfiguration()
        configuration.websiteDataStore = .nonPersistent()
        context.coordinator.configure(configuration.userContentController)

        let webView = WKWebView(frame: .zero, configuration: configuration)
        if let game = Bundle.main.url(forResource: "index", withExtension: "html") {
            webView.loadFileURL(game, allowingReadAccessTo: game)
        }
        return webView
    }

    func updateUIView(_ webView: WKWebView, context: Context) {}

    static func dismantleUIView(_ webView: WKWebView, coordinator: PromptHistory) {
        webView.stopLoading()
        webView.configuration.userContentController.removeScriptMessageHandler(forName: PromptHistory.handlerName)
    }
}

private final class PromptHistory: NSObject, WKScriptMessageHandler {
    static let handlerName = "krillionHistory"
    private static let storageKey = "krill_seen_v2"

    func configure(_ controller: WKUserContentController) {
        let history = UserDefaults.standard.stringArray(forKey: Self.storageKey) ?? []
        let encoded = (try? JSONEncoder().encode(history)) ?? Data("[]".utf8)
        let initialHistory = String(decoding: encoded, as: UTF8.self)

        // Give the bundled file the same prompt-history storage API as the website.
        let script = """
        (() => {
            const key = "\(Self.storageKey)";
            let saved = JSON.stringify(\(initialHistory));
            Object.defineProperty(window, "localStorage", {
                value: {
                    getItem(name) {
                        return name === key ? saved : null;
                    },
                    setItem(name, value) {
                        if (name === key) {
                            saved = String(value);
                            window.webkit.messageHandlers.\(Self.handlerName).postMessage(saved);
                        }
                    }
                }
            });
        })();
        """
        controller.add(self, name: Self.handlerName)
        controller.addUserScript(WKUserScript(
            source: script,
            injectionTime: .atDocumentStart,
            forMainFrameOnly: true
        ))
    }

    func userContentController(_ controller: WKUserContentController, didReceive message: WKScriptMessage) {
        guard message.name == Self.handlerName,
              message.frameInfo.isMainFrame,
              let value = message.body as? String,
              let history = try? JSONDecoder().decode([String].self, from: Data(value.utf8)) else { return }
        UserDefaults.standard.set(history, forKey: Self.storageKey)
    }
}
