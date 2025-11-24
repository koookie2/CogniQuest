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

    func testMatchesStateRuleAcceptsLongAndShortForms() {
        let service = ScoringService()
        let question = Question(
            id: 3,
            text: "State?",
            type: .orientation,
            points: 1,
            scoringCriteria: ScoringCriteria(dynamicRule: "matchesState", exactMatches: nil, thresholds: nil, requiredComponents: nil, keywords: nil)
        )

        let answersShort: [Int: Answer] = [3: .text("va")]
        let answersLong: [Int: Answer] = [3: .text("Virginia")]
        let expectedState = StateInfo(fullName: "Virginia", abbreviation: "VA")

        let shortScore = service.score(
            answers: answersShort,
            questions: [question],
            hasHighSchoolEducation: true,
            expectedState: expectedState
        )
        let longScore = service.score(
            answers: answersLong,
            questions: [question],
            hasHighSchoolEducation: true,
            expectedState: expectedState
        )

        XCTAssertEqual(shortScore, 1)
        XCTAssertEqual(longScore, 1)
    }

    func testMatchesStateRuleIgnoresCase() {
        let service = ScoringService()
        let question = Question(
            id: 3,
            text: "State?",
            type: .orientation,
            points: 1,
            scoringCriteria: ScoringCriteria(dynamicRule: "matchesState", exactMatches: nil, thresholds: nil, requiredComponents: nil, keywords: nil)
        )

        let answers: [Int: Answer] = [3: .text("va")]
        let expectedState = StateInfo(fullName: "Virginia", abbreviation: "VA")
        let score = service.score(
            answers: answers,
            questions: [question],
            hasHighSchoolEducation: true,
            expectedState: expectedState
        )
        XCTAssertEqual(score, 1)
    }
    
    func testCurrentDayAcceptsShortForm() {
        let service = ScoringService()
        let question = Question(
            id: 1,
            text: "Day?",
            type: .orientation,
            points: 1,
            scoringCriteria: ScoringCriteria(dynamicRule: "currentDay", exactMatches: nil, thresholds: nil, requiredComponents: nil, keywords: nil)
        )
        
        let shortDay = DateFormatter.weekdayShort().capitalized
        let answers: [Int: Answer] = [1: .text(shortDay)]
        
        let score = service.score(answers: answers, questions: [question], hasHighSchoolEducation: true)
        XCTAssertEqual(score, 1)
    }
    
    func testCurrentYearAcceptsTwoDigitAnswer() {
        let service = ScoringService()
        let question = Question(
            id: 2,
            text: "Year?",
            type: .orientation,
            points: 1,
            scoringCriteria: ScoringCriteria(dynamicRule: "currentYear", exactMatches: nil, thresholds: nil, requiredComponents: nil, keywords: nil)
        )
        
        let currentYear = Calendar.current.component(.year, from: Date())
        let shortYear = currentYear % 100
        let answers: [Int: Answer] = [2: .number(shortYear)]
        
        let score = service.score(answers: answers, questions: [question], hasHighSchoolEducation: true)
        XCTAssertEqual(score, 1)
    }
    
    func testShapeIdentificationIgnoresCase() {
        let service = ScoringService()
        let question = Question(
            id: 10,
            text: "Shapes",
            type: .shapeIdentification,
            points: 2,
            scoringCriteria: ScoringCriteria(
                dynamicRule: nil,
                exactMatches: ["Triangle", "Square"],
                thresholds: nil,
                requiredComponents: nil,
                keywords: nil
            )
        )
        
        var answers: [Int: Answer] = [:]
        answers[10] = .shape(ShapeAnswer(tappedShape: "triangle", largestShape: "square"))
        
        let score = service.score(answers: answers, questions: [question], hasHighSchoolEducation: true)
        XCTAssertEqual(score, 2)
    }

    func testStoryRecallAcceptsTeenSubstringAndStateAbbreviation() {
        let service = ScoringService()
        let question = Question(
            id: 11,
            text: "Story",
            type: .storyRecall,
            points: 8,
            scoringCriteria: ScoringCriteria(
                dynamicRule: nil,
                exactMatches: nil,
                thresholds: nil,
                requiredComponents: nil,
                keywords: ["jill", "stockbroker", "teenagers", "illinois"]
            )
        )

        let answer = StoryAnswer(
            womanName: "Jill",
            profession: "Stockbroker",
            whenReturnedToWork: "When the kids were in their teens",
            state: "IL"
        )

        let score = service.score(
            answers: [11: .story(answer)],
            questions: [question],
            hasHighSchoolEducation: true
        )

        XCTAssertEqual(score, 8)
    }
}
