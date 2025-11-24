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
    @Published var questionScores: [Int: Int] = [:]
    
    // Forwarded properties for View compatibility
    @Published var currentQuestionIndex: Int = 0
    @Published var navigationDirection: NavigationDirection = .forward
    @Published var phase: Phase = .answering
    @Published var timeRemaining: Double = 0
    @Published private(set) var resolvedState: StateInfo?

    let hasHighSchoolEducation: Bool
    let timerDuration: Double
    
    private let scoringService = ScoringService()
    private let repository: QuestionRepositoryProtocol
    private let timerService: TimerService
    private let navigationManager: NavigationManager
    private let stateResolver: StateResolverProtocol
    private var cancellables = Set<AnyCancellable>()

    init(hasHighSchoolEducation: Bool, timerDuration: Double, 
         repository: QuestionRepositoryProtocol = QuestionRepository(),
         timerService: TimerService? = nil,
         navigationManager: NavigationManager? = nil,
         stateResolver: StateResolverProtocol? = nil) {
        self.hasHighSchoolEducation = hasHighSchoolEducation
        self.timerDuration = timerDuration
        self.repository = repository
        self.timerService = timerService ?? TimerService()
        self.navigationManager = navigationManager ?? NavigationManager()
        self.stateResolver = stateResolver ?? StateResolver()
        
        setupBindings()
        Task { await loadQuestions() }
        Task { await resolveDeviceState() }
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

    private func resolveDeviceState() async {
        resolvedState = await stateResolver.resolveState()
    }

    func resetTimer() { 
        timerService.start(duration: timerDuration)
    }

    func moveToNextQuestion() {
        if navigationManager.next() {
            resetTimer()
        } else {
            Task {
                await finalizeExam()
            }
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

    func pauseTimer() {
        timerService.pause()
    }

    func resumeTimer() {
        timerService.resume()
    }

    var questionTransition: Any { navigationDirection == .forward }

    private func finalizeExam() async {
        timerService.stop()
        if resolvedState == nil {
            resolvedState = await stateResolver.resolveState()
        }
        let scoreResult = scoringService.scoreResult(
            answers: answers,
            questions: questions,
            hasHighSchoolEducation: hasHighSchoolEducation,
            expectedState: resolvedState
        )
        score = scoreResult.total
        questionScores = scoreResult.perQuestion
        showResults = true
    }
}
