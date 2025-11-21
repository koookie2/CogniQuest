import XCTest
@testable import CogniQuest

@MainActor
final class TimerServiceTests: XCTestCase {
    func testTimerStartAndTick() async {
        let service = TimerService()
        service.start(duration: 2)
        
        XCTAssertEqual(service.timeRemaining, 2)
        XCTAssertFalse(service.isPaused)
        
        // Wait for tick (approx 1.1s)
        try? await Task.sleep(nanoseconds: 1_100_000_000)
        XCTAssertEqual(service.timeRemaining, 1)
        
        try? await Task.sleep(nanoseconds: 1_100_000_000)
        XCTAssertEqual(service.timeRemaining, 0)
    }
    
    func testPauseResume() {
        let service = TimerService()
        service.start(duration: 10)
        service.pause()
        XCTAssertTrue(service.isPaused)
        
        service.resume()
        XCTAssertFalse(service.isPaused)
    }
}

@MainActor
final class NavigationManagerTests: XCTestCase {
    func testNavigationFlow() {
        let manager = NavigationManager()
        manager.start(totalQuestions: 3)
        
        XCTAssertEqual(manager.currentQuestionIndex, 0)
        XCTAssertEqual(manager.phase, .answering)
        
        // Next
        XCTAssertTrue(manager.next())
        XCTAssertEqual(manager.currentQuestionIndex, 1)
        
        // Next
        XCTAssertTrue(manager.next())
        XCTAssertEqual(manager.currentQuestionIndex, 2)
        
        // Finish
        XCTAssertFalse(manager.next())
        XCTAssertEqual(manager.phase, .finished)
    }
    
    func testBackNavigation() {
        let manager = NavigationManager()
        manager.start(totalQuestions: 3)
        manager.next() // Index 1
        
        manager.back()
        XCTAssertEqual(manager.currentQuestionIndex, 0)
        XCTAssertEqual(manager.navigationDirection, .backward)
    }
}
