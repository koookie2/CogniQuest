import Foundation
import Combine

@MainActor
final class ExamViewModel: ObservableObject {
    enum NavigationDirection { case forward, backward }
    enum Phase { case narrating, answering, finished }

    @Published var answers: [Int: Answer] = [:]
    @Published var score: Int = 0
    @Published var showResults: Bool = false
    @Published var questions: [Question] = []
    
    // Forwarded properties for View compatibility
    @Published var currentQuestionIndex: Int = 0
    @Published var navigationDirection: NavigationDirection = .forward
    @Published var phase: Phase = .answering
    @Published var timeRemaining: Double = 0
    @Published var isTimerPaused: Bool = false

    let hasHighSchoolEducation: Bool
    let timerDuration: Double
    
    private let scoringService = ScoringService()
    private let repository: QuestionRepositoryProtocol
    private let timerService: TimerService
    private let navigationManager: NavigationManager
    private var cancellables = Set<AnyCancellable>()

    init(hasHighSchoolEducation: Bool, timerDuration: Double, 
         repository: QuestionRepositoryProtocol = QuestionRepository(),
         timerService: TimerService? = nil,
         navigationManager: NavigationManager? = nil) {
        self.hasHighSchoolEducation = hasHighSchoolEducation
        self.timerDuration = timerDuration
        self.repository = repository
        self.timerService = timerService ?? TimerService()
        self.navigationManager = navigationManager ?? NavigationManager()
        
        setupBindings()
        Task { await loadQuestions() }
    }
    
    private func setupBindings() {
        // Bind NavigationManager
        navigationManager.$currentQuestionIndex
            .sink { [weak self] in self?.currentQuestionIndex = $0 }
            .store(in: &cancellables)
        
        navigationManager.$navigationDirection
            .sink { [weak self] in self?.navigationDirection = $0 }
            .store(in: &cancellables)
        
        navigationManager.$phase
            .sink { [weak self] in self?.phase = $0 }
            .store(in: &cancellables)
        
        // Bind TimerService
        timerService.$timeRemaining
            .sink { [weak self] in self?.timeRemaining = $0 }
            .store(in: &cancellables)
        
        timerService.$isPaused
            .sink { [weak self] in self?.isTimerPaused = $0 }
            .store(in: &cancellables)
        
        // Handle timer expiry
        timerService.$timeRemaining
            .filter { $0 <= 0 }
            .dropFirst() // Ignore initial 0
            .sink { [weak self] _ in
                guard let self, !self.navigationManager.isFinished else { return }
                self.moveToNextQuestion()
            }
            .store(in: &cancellables)
    }
    
    @MainActor
    private func loadQuestions() async {
        do {
            self.questions = try await repository.fetchQuestions()
            navigationManager.start(totalQuestions: questions.count)
            timerService.start(duration: timerDuration)
        } catch {
            print("Failed to load questions: \(error)")
        }
    }

    func resetTimer() { 
        timerService.start(duration: timerDuration)
    }

    func moveToNextQuestion() {
        if navigationManager.next() {
            resetTimer()
        } else {
            timerService.stop()
            score = scoringService.score(answers: answers, questions: questions, hasHighSchoolEducation: hasHighSchoolEducation)
            showResults = true
        }
    }

    func moveBack() {
        navigationManager.back()
        resetTimer()
    }

    func setNarrating(_ narrating: Bool) {
        navigationManager.setNarrating(narrating)
        if narrating {
            timerService.pause()
        } else {
            timerService.resume()
        }
    }

    var questionTransition: Any { navigationDirection == .forward }
}

