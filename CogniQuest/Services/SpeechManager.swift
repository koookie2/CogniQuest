import Foundation
import AVFoundation
import os.log

@MainActor
final class SpeechManager: NSObject, AVSpeechSynthesizerDelegate, ObservableObject {
    private let synthesizer = AVSpeechSynthesizer()
    private var speechQueue: [AVSpeechUtterance] = []
    private let logger = Logger(subsystem: "org.kavin.CogniQuest", category: "TTS")

    @Published var isSpeaking = false

    var onQueueFinish: (() -> Void)?

    override init() {
        super.init()
        synthesizer.delegate = self
    }

    func speak(queue: [String]) {
        guard !queue.isEmpty, !synthesizer.isSpeaking else { return }

        do {
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default, options: [.duckOthers])
            try AVAudioSession.sharedInstance().setActive(true, options: [])
        } catch {
            logger.error("Failed to activate audio session: \(error.localizedDescription)")
        }

        speechQueue = queue.map { text in
            let utterance = AVSpeechUtterance(string: text)
            utterance.voice = AVSpeechSynthesisVoice(language: Locale.current.identifier) ?? AVSpeechSynthesisVoice(language: "en-US")
            utterance.rate = AVSpeechUtteranceDefaultSpeechRate * 0.95
            utterance.postUtteranceDelay = 1.0
            return utterance
        }

        isSpeaking = true
        synthesizer.speak(speechQueue.removeFirst())
    }

    nonisolated func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance) {
        Task { @MainActor in
            if !speechQueue.isEmpty {
                self.synthesizer.speak(self.speechQueue.removeFirst())
            } else {
                self.isSpeaking = false
                self.deactivateAudioSession()
                self.onQueueFinish?()
            }
        }
    }

    func stop() {
        synthesizer.stopSpeaking(at: .immediate)
        speechQueue.removeAll()
        isSpeaking = false
        deactivateAudioSession()
    }

    private func deactivateAudioSession() {
        do {
            try AVAudioSession.sharedInstance().setActive(false, options: [.notifyOthersOnDeactivation])
        } catch {
            logger.error("Failed to deactivate audio session: \(error.localizedDescription)")
        }
    }
}


