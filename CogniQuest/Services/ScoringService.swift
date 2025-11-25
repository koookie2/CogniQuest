import Foundation

struct ScoreResult {
    let total: Int
    let perQuestion: [Int: Int]
    let unscoredQuestions: Set<Int>
}

struct ScoringService {
    func score(
        answers: [Int: Answer],
        questions: [Question],
        hasHighSchoolEducation: Bool,
        expectedState: StateInfo? = nil
    ) -> Int {
        scoreResult(
            answers: answers,
            questions: questions,
            hasHighSchoolEducation: hasHighSchoolEducation,
            expectedState: expectedState
        ).total
    }
    
    func scoreResult(
        answers: [Int: Answer],
        questions: [Question],
        hasHighSchoolEducation: Bool,
        expectedState: StateInfo? = nil
    ) -> ScoreResult {
        var totalScore = 0
        var breakdown: [Int: Int] = [:]
        var unscoredQuestions: Set<Int> = []

        for question in questions {
            var earnedPoints = 0
            var isUnscored = false
            if let answer = answers[question.id] {
                switch question.type {
                case .orientation:
                    if question.scoringCriteria?.dynamicRule == "matchesState" && expectedState == nil {
                        isUnscored = true
                    } else {
                        earnedPoints = scoreOrientation(question: question, answer: answer, expectedState: expectedState)
                    }
                case .registration:
                    earnedPoints = 0
                case .calculation:
                    earnedPoints = scoreCalculation(question: question, answer: answer)
                case .animalList:
                    earnedPoints = scoreAnimalList(question: question, answer: answer)
                case .fiveWordRecall:
                    earnedPoints = scoreFiveWordRecall(question: question, answer: answer)
                case .numberSeriesBackwards:
                    earnedPoints = scoreNumberSeries(question: question, answer: answer)
                case .clockDrawing:
                    earnedPoints = scoreClockDrawing(question: question, answer: answer)
                case .shapeIdentification:
                    earnedPoints = scoreShapeIdentification(question: question, answer: answer)
                case .storyRecall:
                    earnedPoints = scoreStoryRecall(question: question, answer: answer)
                }
            }
            
            if isUnscored {
                unscoredQuestions.insert(question.id)
            }
            breakdown[question.id] = earnedPoints
            totalScore += earnedPoints
        }

        return ScoreResult(total: totalScore, perQuestion: breakdown, unscoredQuestions: unscoredQuestions)
    }
    
    private func scoreOrientation(question: Question, answer: Answer, expectedState: StateInfo?) -> Int {
        guard let criteria = question.scoringCriteria else { return 0 }
        
        if let rule = criteria.dynamicRule {
            switch rule {
            case "currentDay":
                guard let value = normalizedText(from: answer) else { return 0 }
                if value == DateFormatter.weekday() { return 1 }
                if value == DateFormatter.weekdayShort() { return 1 }
            case "currentYear":
                let currentYear = Calendar.current.component(.year, from: Date())
                guard let yearValue = numericValue(from: answer) else { return 0 }
                if yearValue == currentYear { return 1 }
                if yearValue == currentYear % 100 { return 1 }
            case "nonEmpty":
                if case let .text(val) = answer, !val.trimmedLowercased().isEmpty { return 1 }
            case "matchesState":
                guard let expectedState,
                      let normalized = normalizedText(from: answer) else { return 0 }
                if normalized == expectedState.fullName.trimmedLowercased() { return 1 }
                if normalized == expectedState.abbreviation.lowercased() { return 1 }
            default: return 0
            }
        }
        return 0
    }
    
    private func scoreCalculation(question: Question, answer: Answer) -> Int {
        guard case let .calculation(calc) = answer,
              let matches = question.scoringCriteria?.exactMatches, matches.count >= 2 else { return 0 }
        
        var points = 0
        if String(calc.spent) == matches[0] { points += 1 }
        if String(calc.left) == matches[1] { points += 2 }
        return points
    }
    
    private func scoreAnimalList(question: Question, answer: Answer) -> Int {
        guard case let .animalCount(count) = answer,
              let thresholds = question.scoringCriteria?.thresholds, thresholds.count >= 3 else { return 0 }
        
        if count >= thresholds[2] { return 3 }
        if count >= thresholds[1] { return 2 }
        if count >= thresholds[0] { return 1 }
        return 0
    }
    
    private func scoreFiveWordRecall(question: Question, answer: Answer) -> Int {
        guard case let .fiveWordRecall(words) = answer,
              let correctWords = question.scoringCriteria?.exactMatches else { return 0 }
        
        let correctSet = Set(correctWords.map { $0.trimmedLowercased() })
        return words.map { $0.trimmedLowercased() }.filter { correctSet.contains($0) }.count
    }
    
    private func scoreNumberSeries(question: Question, answer: Answer) -> Int {
        guard case let .numberSeries(series) = answer,
              let matches = question.scoringCriteria?.exactMatches, matches.count >= 2 else { return 0 }
        
        var points = 0
        if series.series2 == matches[0] { points += 1 }
        if series.series3 == matches[1] { points += 1 }
        return points
    }
    
    private func scoreClockDrawing(question: Question, answer: Answer) -> Int {
        guard case let .clockDrawing(clock) = answer else { return 0 }
        // Note: Clock drawing validation is currently boolean flags from the UI/Input
        // We could move "requiredComponents" check here if we had raw data, but for now we trust the flags
        var points = 0
        if clock.hasCorrectNumbers { points += 2 }
        if clock.hasCorrectTime { points += 2 }
        return points
    }
    
    private func scoreShapeIdentification(question: Question, answer: Answer) -> Int {
        guard case let .shape(shape) = answer,
              let matches = question.scoringCriteria?.exactMatches, matches.count >= 2 else { return 0 }
        
        let firstMatch = matches[0].trimmedLowercased()
        let secondMatch = matches[1].trimmedLowercased()
        
        var points = 0
        if shape.tappedShape?.trimmedLowercased() == firstMatch { points += 1 }
        if shape.largestShape?.trimmedLowercased() == secondMatch { points += 1 }
        return points
    }
    
    private func scoreStoryRecall(question: Question, answer: Answer) -> Int {
        guard case let .story(story) = answer,
              let keywords = question.scoringCriteria?.keywords, keywords.count >= 4 else { return 0 }
        
        var points = 0
        if containsKeyword(in: story.womanName, keyword: keywords[0]) { points += 2 }
        if containsKeyword(in: story.profession, keyword: keywords[1]) { points += 2 }

        let whenAnswer = story.whenReturnedToWork
        if containsKeyword(in: whenAnswer, keyword: keywords[2]) || containsKeyword(in: whenAnswer, keyword: "teen") {
            points += 2
        }
        
        if matchesStateAnswer(story.state, keyword: keywords[3]) {
            points += 2
        }
        return points
    }
}

public extension DateFormatter {
    static func weekday() -> String {
        let df = DateFormatter()
        df.dateFormat = "EEEE"
        return df.string(from: Date()).lowercased()
    }
    
    static func weekdayShort() -> String {
        let df = DateFormatter()
        df.dateFormat = "EEE"
        return df.string(from: Date()).lowercased()
    }
}

extension String {
    func trimmedLowercased() -> String { self.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() }
}

private extension ScoringService {
    func normalizedText(from answer: Answer) -> String? {
        switch answer {
        case .text(let value): return value.trimmedLowercased()
        case .number(let num): return String(num).trimmedLowercased()
        default: return nil
        }
    }
    
    func numericValue(from answer: Answer) -> Int? {
        switch answer {
        case .number(let value):
            return value
        case .text(let string):
            return Int(string.trimmingCharacters(in: .whitespacesAndNewlines))
        default:
            return nil
        }
    }

    func containsKeyword(in answer: String, keyword: String) -> Bool {
        let normalizedAnswer = answer.trimmedLowercased()
        let normalizedKeyword = keyword.trimmedLowercased()
        guard !normalizedAnswer.isEmpty, !normalizedKeyword.isEmpty else { return false }
        if normalizedAnswer == normalizedKeyword { return true }

        let tokens = tokenize(normalizedAnswer)
        if tokens.contains(normalizedKeyword) { return true }

        let condensedAnswer = tokens.joined()
        let condensedKeyword = tokenize(normalizedKeyword).joined()
        return condensedAnswer.contains(condensedKeyword)
    }

    func matchesStateAnswer(_ answer: String, keyword: String) -> Bool {
        let normalizedAnswer = answer.trimmedLowercased()
        let normalizedKeyword = keyword.trimmedLowercased()
        guard !normalizedAnswer.isEmpty, !normalizedKeyword.isEmpty else { return false }
        if normalizedAnswer == normalizedKeyword { return true }

        if normalizedAnswer.contains(normalizedKeyword) { return true }
        if tokenize(normalizedAnswer).contains(normalizedKeyword) { return true }

        if let targetState = StateLookup.info(for: keyword) {
            if normalizedAnswer.contains(targetState.fullName.trimmedLowercased()) || normalizedAnswer.contains(targetState.abbreviation.lowercased()) {
                return true
            }
            if let answerInfo = extractStateInfo(from: answer) {
                if answerInfo.abbreviation.lowercased() == targetState.abbreviation.lowercased() { return true }
                if answerInfo.fullName.trimmedLowercased() == targetState.fullName.trimmedLowercased() { return true }
            }
        } else if let answerInfo = extractStateInfo(from: answer) {
            if answerInfo.fullName.trimmedLowercased() == normalizedKeyword { return true }
            if answerInfo.abbreviation.lowercased() == normalizedKeyword { return true }
        }
        return false
    }

    func extractStateInfo(from text: String) -> StateInfo? {
        if let direct = StateLookup.info(for: text) {
            return direct
        }
        let normalized = text.trimmedLowercased()
        guard !normalized.isEmpty else { return nil }
        for state in StateLookup.allStates {
            let fullName = state.fullName.trimmedLowercased()
            let abbreviation = state.abbreviation.lowercased()
            if normalized.contains(fullName) || normalized.contains(abbreviation) {
                return state
            }
        }
        return nil
    }

    func tokenize(_ text: String) -> [String] {
        text.components(separatedBy: CharacterSet.alphanumerics.inverted).filter { !$0.isEmpty }
    }
}
