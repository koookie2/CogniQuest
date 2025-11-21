import Foundation
import Combine

@MainActor
protocol NavigationManagerProtocol: ObservableObject {
    var currentQuestionIndex: Int { get }
    var navigationDirection: ExamViewModel.NavigationDirection { get }
    var phase: ExamViewModel.Phase { get }
    var isFinished: Bool { get }
    
    func start(totalQuestions: Int)
    func next() -> Bool // Returns true if moved next, false if finished
    func back()
    func setNarrating(_ narrating: Bool)
}

@MainActor
final class NavigationManager: NavigationManagerProtocol {
    @Published private(set) var currentQuestionIndex: Int = 0
    @Published private(set) var navigationDirection: ExamViewModel.NavigationDirection = .forward
    @Published private(set) var phase: ExamViewModel.Phase = .answering
    
    private var totalQuestions: Int = 0
    
    var isFinished: Bool {
        phase == .finished
    }
    
    func start(totalQuestions: Int) {
        self.totalQuestions = totalQuestions
        self.currentQuestionIndex = 0
        self.phase = .answering
        self.navigationDirection = .forward
    }
    
    func next() -> Bool {
        navigationDirection = .forward
        if currentQuestionIndex < totalQuestions - 1 {
            currentQuestionIndex += 1
            return true
        } else {
            phase = .finished
            return false
        }
    }
    
    func back() {
        guard currentQuestionIndex > 0 else { return }
        navigationDirection = .backward
        currentQuestionIndex -= 1
    }
    
    func setNarrating(_ narrating: Bool) {
        phase = narrating ? .narrating : .answering
    }
}
