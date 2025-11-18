import XCTest
@testable import CogniQuest

class MockQuestionRepository: QuestionRepositoryProtocol {
    var questionsToReturn: [Question] = []
    var errorToThrow: Error?
    
    func fetchQuestions() async throws -> [Question] {
        if let error = errorToThrow {
            throw error
        }
        return questionsToReturn
    }
}

@MainActor
final class ExamViewModelTests: XCTestCase {
    var viewModel: ExamViewModel!
    var mockRepository: MockQuestionRepository!
    
    override func setUp() {
        super.setUp()
        mockRepository = MockQuestionRepository()
    }
    
    func testInitializationLoadsQuestions() async {
        // Given
        let expectedQuestions = [
            Question(id: 1, text: "Test Q1", type: .orientation, points: 1),
            Question(id: 2, text: "Test Q2", type: .orientation, points: 1)
        ]
        mockRepository.questionsToReturn = expectedQuestions
        
        // When
        viewModel = ExamViewModel(hasHighSchoolEducation: true, timerDuration: 60, repository: mockRepository)
        
        // Then
        // Allow async task to complete
        try? await Task.sleep(nanoseconds: 100_000_000) // 0.1s
        
        XCTAssertEqual(viewModel.questions, expectedQuestions)
        XCTAssertEqual(viewModel.questions.count, 2)
    }
    
    func testMoveToNextQuestion() async {
        // Given
        mockRepository.questionsToReturn = [
            Question(id: 1, text: "Q1", type: .orientation, points: 1),
            Question(id: 2, text: "Q2", type: .orientation, points: 1)
        ]
        viewModel = ExamViewModel(hasHighSchoolEducation: true, timerDuration: 60, repository: mockRepository)
        try? await Task.sleep(nanoseconds: 100_000_000)
        
        // When
        viewModel.moveToNextQuestion()
        
        // Then
        XCTAssertEqual(viewModel.currentQuestionIndex, 1)
        XCTAssertFalse(viewModel.showResults)
    }
    
    func testFinishExam() async {
        // Given
        mockRepository.questionsToReturn = [
            Question(id: 1, text: "Q1", type: .orientation, points: 1)
        ]
        viewModel = ExamViewModel(hasHighSchoolEducation: true, timerDuration: 60, repository: mockRepository)
        try? await Task.sleep(nanoseconds: 100_000_000)
        
        // When
        viewModel.moveToNextQuestion() // Should finish since it's the last question
        
        // Then
        XCTAssertTrue(viewModel.showResults)
        XCTAssertEqual(viewModel.phase, .finished)
    }
}
