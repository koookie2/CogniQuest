import Foundation
import Combine

@MainActor
protocol TimerServiceProtocol: ObservableObject {
    var timeRemaining: Double { get }
    var isPaused: Bool { get }
    func start(duration: Double)
    func pause()
    func resume()
    func stop()
}

@MainActor
final class TimerService: TimerServiceProtocol {
    @Published private(set) var timeRemaining: Double = 0
    @Published private(set) var isPaused: Bool = false
    
    private var duration: Double = 0
    
    private var timer: Timer?
    
    func start(duration: Double) {
        self.duration = duration
        self.timeRemaining = duration
        self.isPaused = false
        startTimer()
    }
    
    func pause() {
        isPaused = true
        timer?.invalidate()
    }
    
    func resume() {
        isPaused = false
        startTimer()
    }
    
    func stop() {
        timeRemaining = 0
        isPaused = false
        timer?.invalidate()
    }
    
    private func startTimer() {
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in
                self?.tick()
            }
        }
    }
    
    private func tick() {
        guard !isPaused, timeRemaining > 0 else { return }
        timeRemaining -= 1
    }
}
