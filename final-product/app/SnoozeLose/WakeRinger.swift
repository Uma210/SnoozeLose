import Foundation
import AVFoundation
import AVFAudio
import AudioToolbox
import UIKit

/// Foreground-only bell, vibration, and LED torch controls.
/// Does not bypass iOS system permissions or run a flashlight in the background.
@MainActor
final class WakeRinger: ObservableObject {
    @Published private(set) var isPlaying = false
    @Published private(set) var flashlightOn = false
    private var player: AVAudioPlayer?
    private var pulseTimer: Timer?
    private var vibrationEnabled = false
    private var flashEnabled = false
    private var pulseCount = 0
    private var torchTurnOff: Task<Void, Never>?
    private var generation = 0

    func start(sound: String, vibrate: Bool, flash: Bool) {
        stop()
        generation += 1
        let currentGeneration = generation
        vibrationEnabled = vibrate
        flashEnabled = flash
        isPlaying = true
        if sound != "Silent" {
            let filename = sound == "Pulse" ? "Pulse" : "Sunrise"
            if let url = Bundle.main.url(forResource: filename, withExtension: "wav") {
                do {
                    try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default)
                    try AVAudioSession.sharedInstance().setActive(true)
                    let audio = try AVAudioPlayer(contentsOf: url)
                    audio.numberOfLoops = -1
                    audio.prepareToPlay()
                    if audio.play() { player = audio }
                    else { print("Alarm audio could not start") }
                } catch { print("Alarm audio unavailable: \(error)") }
            }
        }
        pulse()
        pulseTimer = Timer.scheduledTimer(withTimeInterval: 1.6, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in
                guard self?.generation == currentGeneration else { return }
                self?.pulse()
            }
        }
    }

    private func pulse() {
        guard isPlaying else { return }
        if vibrationEnabled { AudioServicesPlaySystemSound(kSystemSoundID_Vibrate) }
        // A short flash every other pulse, rather than a rapid strobe.
        if flashEnabled && pulseCount.isMultiple(of: 2) {
            torchTurnOff?.cancel()
            setTorch(true)
            let currentGeneration = generation
            torchTurnOff = Task { @MainActor [weak self] in
                try? await Task.sleep(nanoseconds: 320_000_000)
                guard !Task.isCancelled, self?.generation == currentGeneration else { return }
                self?.setTorch(false)
            }
        }
        pulseCount += 1
    }

    private func setTorch(_ on: Bool) {
        guard let device = AVCaptureDevice.default(for: .video), device.hasTorch else { return }
        do {
            try device.lockForConfiguration()
            if on { try device.setTorchModeOn(level: min(AVCaptureDevice.maxAvailableTorchLevel, 0.20)) }
            else { device.torchMode = .off }
            device.unlockForConfiguration()
            flashlightOn = on
        } catch { print("Torch unavailable: \(error)") }
    }

    func stop() {
        generation += 1
        torchTurnOff?.cancel()
        torchTurnOff = nil
        isPlaying = false
        pulseTimer?.invalidate()
        pulseTimer = nil
        player?.stop()
        player = nil
        setTorch(false)
        try? AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
    }
}
