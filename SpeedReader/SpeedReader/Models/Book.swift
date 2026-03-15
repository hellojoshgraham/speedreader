import Foundation
import SwiftData

@Model
final class Book {
    var title: String
    var author: String
    var words: [String]
    var currentWordIndex: Int
    var wordsPerMinute: Int
    var transitionDuration: Double = 0  // 0 = no transition
    var sentencePauseEnabled: Bool = true
    var scaleAmount: Double = 0  // 0 = off, otherwise 1.0–1.5
    var dateAdded: Date
    var dateLastRead: Date?

    var progressPercentage: Double {
        guard !words.isEmpty else { return 0 }
        return Double(currentWordIndex) / Double(words.count) * 100
    }

    var totalWords: Int {
        words.count
    }

    init(title: String, author: String, words: [String], wordsPerMinute: Int = 300, transitionDuration: Double = 0) {
        self.title = title
        self.author = author
        self.words = words
        self.currentWordIndex = 0
        self.wordsPerMinute = wordsPerMinute
        self.transitionDuration = transitionDuration
        self.dateAdded = Date()
        self.dateLastRead = nil
    }
}
