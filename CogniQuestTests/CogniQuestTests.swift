//
//  CogniQuestTests.swift
//  CogniQuestTests
//
//  Created by Kavin on 8/7/25.
//

import XCTest
@testable import CogniQuest

final class ScoringServiceTests: XCTestCase {
    func testScoringOrientationAndCalculation() {
        let service = ScoringService()
        var answers: [Int: Answer] = [:]
        answers[1] = .text(DateFormatter.weekday())
        answers[2] = .number(Calendar.current.component(.year, from: Date()))
        answers[3] = .text("illinois")
        answers[5] = .calculation(CalculationAnswer(spent: 23, left: 77))
        let score = service.score(answers: answers, hasHighSchoolEducation: true)
        XCTAssertGreaterThanOrEqual(score, 1 + 1 + 1 + 3)
    }
}
