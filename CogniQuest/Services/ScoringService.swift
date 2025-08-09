import Foundation

struct ScoringService {
    func score(answers: [Int: Answer], hasHighSchoolEducation: Bool) -> Int {
        var totalScore = 0

        // Orientation: Q1 day of week, Q2 year, Q3 state (non-empty)
        let currentDay = DateFormatter.weekday()
        if case let .text(value)? = answers[1], value.trimmedLowercased() == currentDay { totalScore += 1 }

        let currentYear = Calendar.current.component(.year, from: Date())
        if case let .number(value)? = answers[2], value == currentYear { totalScore += 1 }

        if case let .text(value)? = answers[3], !value.trimmedLowercased().isEmpty { totalScore += 1 }

        // Calculation Q5
        if case let .calculation(calc)? = answers[5] {
            if calc.spent == 23 { totalScore += 1 }
            if calc.left == 77 { totalScore += 2 }
        }

        // Animal list Q6
        if case let .animalCount(count)? = answers[6] {
            if count >= 15 { totalScore += 3 }
            else if count >= 10 { totalScore += 2 }
            else if count >= 5 { totalScore += 1 }
        }

        // Five word recall Q7
        if case let .fiveWordRecall(words)? = answers[7] {
            let correctWords: Set<String> = ["apple","pen","tie","house","car"]
            totalScore += words.map { $0.trimmedLowercased() }.filter { correctWords.contains($0) }.count
        }

        // Number series backwards Q8
        if case let .numberSeries(series)? = answers[8] {
            if series.series2 == "846" { totalScore += 1 }
            if series.series3 == "7358" { totalScore += 1 }
        }

        // Clock drawing Q9
        if case let .clockDrawing(clock)? = answers[9] {
            if clock.hasCorrectNumbers { totalScore += 2 }
            if clock.hasCorrectTime { totalScore += 2 }
        }

        // Shape identification Q10
        if case let .shape(shape)? = answers[10] {
            if shape.tappedShape == "Triangle" { totalScore += 1 }
            if shape.largestShape == "Square" { totalScore += 1 }
        }

        // Story recall Q11
        if case let .story(story)? = answers[11] {
            if story.womanName.trimmedLowercased() == "jill" { totalScore += 2 }
            if story.profession.trimmedLowercased() == "stockbroker" { totalScore += 2 }
            if story.whenReturnedToWork.trimmedLowercased().contains("teenagers") { totalScore += 2 }
            if story.state.trimmedLowercased() == "illinois" { totalScore += 2 }
        }

        return totalScore
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


