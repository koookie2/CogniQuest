import Foundation
import SwiftUI

// MARK: - Typed Answers

public enum Answer: Equatable {
    case text(String)
    case number(Int)
    case calculation(CalculationAnswer)
    case animalCount(Int)
    case fiveWordRecall([String])
    case numberSeries(NumberSeriesAnswer)
    case drawing([DrawingPath])
    case shape(ShapeAnswer)
    case story(StoryAnswer)
}

public struct CalculationAnswer: Equatable {
    public let spent: Int
    public let left: Int
}

public struct NumberSeriesAnswer: Equatable {
    public let series1: String
    public let series2: String
    public let series3: String
}

public struct ShapeAnswer: Equatable {
    public let tappedShape: String?
    public let largestShape: String?
}

public struct StoryAnswer: Equatable {
    public let womanName: String
    public let profession: String
    public let whenReturnedToWork: String
    public let state: String
}

// DrawingPath is used by drawing answers; keep it here for visibility
public struct DrawingPath: Identifiable, Equatable {
    public let id: UUID
    public var points: [CGPoint]
    public let color: Color
    public let lineWidth: CGFloat

    public init(id: UUID = UUID(), points: [CGPoint] = [], color: Color, lineWidth: CGFloat) {
        self.id = id
        self.points = points
        self.color = color
        self.lineWidth = lineWidth
    }
}


