import Foundation

// MARK: - Question Models

public struct Question: Identifiable, Equatable, Codable {
    public let id: Int
    public let text: String
    public let type: QuestionType
    public let points: Int
}

public enum QuestionType: String, Equatable, Codable {
    case orientation
    case registration
    case calculation
    case animalList
    case fiveWordRecall
    case numberSeriesBackwards
    case clockDrawing
    case shapeIdentification
    case storyRecall
}


