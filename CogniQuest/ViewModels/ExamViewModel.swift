import Foundation
import Combine

@MainActor
final class ExamViewModel: ObservableObject {
    enum NavigationDirection { case forward, backward }
    enum Phase { case narrating, answering, finished }

    @Published var currentQuestionIndex: Int = 0
    @Published var answers: [Int: Answer] = [:]
    @Published var score: Int = 0
    @Published var showResults: Bool = false
    @Published var navigationDirection: NavigationDirection = .forward
    @Published var phase: Phase = .answering
    @Published var timeRemaining: Double
    @Published var isTimerPaused: Bool = false
    @Published var questions: [Question] = []

    let hasHighSchoolEducation: Bool
    let timerDuration: Double
    private let scoringService = ScoringService()
    private let repository: QuestionRepositoryProtocol

    init(hasHighSchoolEducation: Bool, timerDuration: Double, repository: QuestionRepositoryProtocol = QuestionRepository()) {
        self.hasHighSchoolEducation = hasHighSchoolEducation
        self.timerDuration = timerDuration
        self.timeRemaining = timerDuration
        self.repository = repository
        
        Task { await loadQuestions() }
    }
    
    @MainActor
    private func loadQuestions() async {
        do {
            self.questions = try await repository.fetchQuestions()
        } catch {
            print("Failed to load questions: \(error)")
            // In a real app, we would handle this error (e.g. show an alert)
        }
    }

    func handleTick() {
        guard !showResults, phase != .narrating else { return }
        if timeRemaining > 0 { timeRemaining -= 1 } else { moveToNextQuestion() }
    }

    func resetTimer() { timeRemaining = timerDuration }

    func moveToNextQuestion() {
        navigationDirection = .forward
        if currentQuestionIndex < questions.count - 1 {
            currentQuestionIndex += 1
            resetTimer()
        } else {
            score = scoringService.score(answers: answers, questions: questions, hasHighSchoolEducation: hasHighSchoolEducation)
            showResults = true
            phase = .finished
        }
    }

    func moveBack() {
        guard currentQuestionIndex > 0 else { return }
        navigationDirection = .backward
        currentQuestionIndex -= 1
        resetTimer()
    }

    func setNarrating(_ narrating: Bool) {
        phase = narrating ? .narrating : .answering
    }

    var questionTransition: Any { navigationDirection == .forward }
}


