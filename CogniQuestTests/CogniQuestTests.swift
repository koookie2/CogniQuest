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
        
        let questions = [
            Question(id: 1, text: "Day?", type: .orientation, points: 1, scoringCriteria: ScoringCriteria(dynamicRule: "currentDay", exactMatches: nil, thresholds: nil, requiredComponents: nil, keywords: nil)),
            Question(id: 2, text: "Year?", type: .orientation, points: 1, scoringCriteria: ScoringCriteria(dynamicRule: "currentYear", exactMatches: nil, thresholds: nil, requiredComponents: nil, keywords: nil)),
            Question(id: 3, text: "State?", type: .orientation, points: 1, scoringCriteria: ScoringCriteria(dynamicRule: "nonEmpty", exactMatches: nil, thresholds: nil, requiredComponents: nil, keywords: nil)),
            Question(id: 5, text: "Calc", type: .calculation, points: 3, scoringCriteria: ScoringCriteria(dynamicRule: nil, exactMatches: ["23", "77"], thresholds: nil, requiredComponents: nil, keywords: nil))
        ]
        
        answers[1] = .text(DateFormatter.weekday())
        answers[2] = .number(Calendar.current.component(.year, from: Date()))
        answers[3] = .text("illinois")
        answers[5] = .calculation(CalculationAnswer(spent: 23, left: 77))
        
        let score = service.score(answers: answers, questions: questions, hasHighSchoolEducation: true)
        XCTAssertEqual(score, 1 + 1 + 1 + 3)
    }
    
    func testScoringAnimalList() {
        let service = ScoringService()
        let questions = [
            Question(id: 6, text: "Animals", type: .animalList, points: 3, scoringCriteria: ScoringCriteria(dynamicRule: nil, exactMatches: nil, thresholds: [5, 10, 15], requiredComponents: nil, keywords: nil))
        ]
        
        var answers: [Int: Answer] = [:]
        answers[6] = .animalCount(12) // Should be 2 points (>= 10)
        
        let score = service.score(answers: answers, questions: questions, hasHighSchoolEducation: true)
        XCTAssertEqual(score, 2)
    }
}
