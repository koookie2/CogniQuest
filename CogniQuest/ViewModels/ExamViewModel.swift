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

    let hasHighSchoolEducation: Bool
    let timerDuration: Double
    private let scoringService = ScoringService()

    let questions: [Question] = [
        Question(id: 1, text: "What day of the week is it?", type: .orientation, points: 1),
        Question(id: 2, text: "What is the year?", type: .orientation, points: 1),
        Question(id: 3, text: "What state are we in?", type: .orientation, points: 1),
        Question(id: 4, text: "Please remember these five objects. I will ask you what they are later.", type: .registration, points: 0),
        Question(id: 5, text: "You have $100. You buy a dozen apples for $3 and a tricycle for $20.", type: .calculation, points: 3),
        Question(id: 6, text: "Please name as many animals as you can in one minute.", type: .animalList, points: 3),
        Question(id: 7, text: "What were the five objects I asked you to remember?", type: .fiveWordRecall, points: 5),
        Question(id: 8, text: "I am going to give you a series of numbers and I would like you to give them to me backwards. For example, if I say 42, you would say or type 24.", type: .numberSeriesBackwards, points: 2),
        Question(id: 9, text: "Draw a clock with all the numbers and set the time to ten minutes to eleven o'clock.", type: .clockDrawing, points: 4),
        Question(id: 10, text: "Please place an 'X' in the triangle. Then, identify which of the figures is largest.", type: .shapeIdentification, points: 2),
        Question(id: 11, text: "Listen to this story and answer the questions:\n\nJill was a very successful stockbroker. She made a lot of money on the stock market. She then met Jack, a devastatingly handsome man. She married him and had three children. They lived in Chicago. She then stopped work and stayed at home to bring up her children. When they were teenagers, she went back to work. She and Jack lived happily ever after.", type: .storyRecall, points: 8)
    ]

    init(hasHighSchoolEducation: Bool, timerDuration: Double) {
        self.hasHighSchoolEducation = hasHighSchoolEducation
        self.timerDuration = timerDuration
        self.timeRemaining = timerDuration
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
            score = scoringService.score(answers: answers, hasHighSchoolEducation: hasHighSchoolEducation)
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


