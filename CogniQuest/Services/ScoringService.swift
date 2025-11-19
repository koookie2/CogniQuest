import Foundation

struct ScoringService {
    func score(answers: [Int: Answer], questions: [Question], hasHighSchoolEducation: Bool) -> Int {
        var totalScore = 0

        for question in questions {
            guard let answer = answers[question.id] else { continue }
            
            switch question.type {
            case .orientation:
                totalScore += scoreOrientation(question: question, answer: answer)
            case .registration:
                break // 0 points
            case .calculation:
                totalScore += scoreCalculation(question: question, answer: answer)
            case .animalList:
                totalScore += scoreAnimalList(question: question, answer: answer)
            case .fiveWordRecall:
                totalScore += scoreFiveWordRecall(question: question, answer: answer)
            case .numberSeriesBackwards:
                totalScore += scoreNumberSeries(question: question, answer: answer)
            case .clockDrawing:
                totalScore += scoreClockDrawing(question: question, answer: answer)
            case .shapeIdentification:
                totalScore += scoreShapeIdentification(question: question, answer: answer)
            case .storyRecall:
                totalScore += scoreStoryRecall(question: question, answer: answer)
            }
        }

        return totalScore
    }
    
    private func scoreOrientation(question: Question, answer: Answer) -> Int {
        guard let criteria = question.scoringCriteria else { return 0 }
        
        if let rule = criteria.dynamicRule {
            switch rule {
            case "currentDay":
                if case let .text(val) = answer, val.trimmedLowercased() == DateFormatter.weekday() { return 1 }
            case "currentYear":
                let currentYear = Calendar.current.component(.year, from: Date())
                if case let .number(val) = answer, val == currentYear { return 1 }
            case "nonEmpty":
                if case let .text(val) = answer, !val.trimmedLowercased().isEmpty { return 1 }
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
        
        var points = 0
        if shape.tappedShape == matches[0] { points += 1 }
        if shape.largestShape == matches[1] { points += 1 }
        return points
    }
    
    private func scoreStoryRecall(question: Question, answer: Answer) -> Int {
        guard case let .story(story) = answer,
              let keywords = question.scoringCriteria?.keywords, keywords.count >= 4 else { return 0 }
        
        var points = 0
        if story.womanName.trimmedLowercased() == keywords[0] { points += 2 }
        if story.profession.trimmedLowercased() == keywords[1] { points += 2 }
        if story.whenReturnedToWork.trimmedLowercased().contains(keywords[2]) { points += 2 }
        if story.state.trimmedLowercased() == keywords[3] { points += 2 }
        return points
    }
}

public extension DateFormatter {
    static func weekday() -> String {
        let df = DateFormatter()
        df.dateFormat = "EEEE"
        return df.string(from: Date()).lowercased()
    }
}

extension String {
    func trimmedLowercased() -> String { self.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() }
}


