import Foundation

protocol QuestionRepositoryProtocol {
    func fetchQuestions() async throws -> [Question]
}

final class QuestionRepository: QuestionRepositoryProtocol {
    private let bundle: Bundle
    private let fileName: String
    
    init(bundle: Bundle = .main, fileName: String = "questions") {
        self.bundle = bundle
        self.fileName = fileName
    }
    
    func fetchQuestions() async throws -> [Question] {
        guard let url = bundle.url(forResource: fileName, withExtension: "json") else {
            throw QuestionRepositoryError.fileNotFound
        }
        
        let data = try Data(contentsOf: url)
        let decoder = JSONDecoder()
        return try decoder.decode([Question].self, from: data)
    }
}

enum QuestionRepositoryError: Error {
    case fileNotFound
    case decodingError(Error)
}
