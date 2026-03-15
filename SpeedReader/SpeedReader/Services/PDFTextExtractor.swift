import Foundation
import PDFKit

struct PDFTextExtractor {
    enum ExtractionError: Error, LocalizedError {
        case failedToLoadPDF
        case noTextContent

        var errorDescription: String? {
            switch self {
            case .failedToLoadPDF:
                return "Failed to load the PDF file."
            case .noTextContent:
                return "No readable text found in the PDF."
            }
        }
    }

    /// Prefix used to mark the first word on a new page.
    static let pageMarker = "¶"

    private static let filteredWords: Set<String> = [
        "oceanofpdf.com", "oceanofpdf"
    ]

    static func extractWords(from url: URL) throws -> [String] {
        guard let document = PDFDocument(url: url) else {
            throw ExtractionError.failedToLoadPDF
        }

        var allWords: [String] = []

        for pageIndex in 0..<document.pageCount {
            guard let page = document.page(at: pageIndex),
                  let pageText = page.string else {
                continue
            }

            let pageWords = pageText
                .components(separatedBy: .whitespacesAndNewlines)
                .map { $0.trimmingCharacters(in: .punctuationCharacters.union(.symbols).subtracting(.init(charactersIn: ".,!?;:'-\""))) }
                .filter { !$0.isEmpty && !filteredWords.contains($0.lowercased()) }

            // Mark the first word of each page (except page 0)
            for (j, word) in pageWords.enumerated() {
                if j == 0 && pageIndex > 0 && !allWords.isEmpty {
                    allWords.append(pageMarker + word)
                } else {
                    allWords.append(word)
                }
            }
        }

        guard !allWords.isEmpty else {
            throw ExtractionError.noTextContent
        }

        return mergeChapterHeadings(allWords)
    }

    /// Prefix used to mark chapter heading tokens in the words array.
    static let chapterPrefix = "§"

    private static let standaloneSectionWords: Set<String> = [
        "foreword", "preface", "introduction", "prologue",
        "epilogue", "afterword", "appendix", "conclusion",
        "acknowledgements", "acknowledgments", "bibliography",
        "glossary", "index", "dedication", "contents"
    ]

    private static let labelWords: Set<String> = [
        "chapter", "part", "section", "book", "act", "volume"
    ]

    private static func mergeChapterHeadings(_ words: [String]) -> [String] {
        var result: [String] = []
        var i = 0

        while i < words.count {
            let word = words[i]
            let lower = word.lowercased()

            // "Chapter 3", "Part II", "Section 1.2", "Act IV" etc.
            if labelWords.contains(lower), i + 1 < words.count {
                let next = words[i + 1]
                if isNumberOrRoman(next) {
                    result.append("\(chapterPrefix)\(word) \(next)")
                    i += 2
                    continue
                }
            }

            // Standalone headings: "Foreword", "Prologue", etc.
            if standaloneSectionWords.contains(lower) {
                result.append("\(chapterPrefix)\(word)")
                i += 1
                continue
            }

            result.append(word)
            i += 1
        }

        return result
    }

    private static func isNumberOrRoman(_ word: String) -> Bool {
        // Numeric: "1", "12", "1.2"
        if word.range(of: #"^\d+[.\d]*$"#, options: .regularExpression) != nil {
            return true
        }
        // Roman numerals: I, II, III, IV, ... up to a reasonable length
        if word.range(of: #"^[IVXLC]+$"#, options: .regularExpression) != nil {
            return true
        }
        // Written numbers
        let writtenNumbers: Set<String> = [
            "one", "two", "three", "four", "five", "six", "seven",
            "eight", "nine", "ten", "eleven", "twelve", "thirteen",
            "fourteen", "fifteen", "sixteen", "seventeen", "eighteen",
            "nineteen", "twenty"
        ]
        if writtenNumbers.contains(word.lowercased()) {
            return true
        }
        return false
    }

    static func extractTitle(from url: URL) -> String {
        if let document = PDFDocument(url: url),
           let attributes = document.documentAttributes,
           let title = attributes[PDFDocumentAttribute.titleAttribute] as? String,
           !title.isEmpty {
            return title
        }
        return url.deletingPathExtension().lastPathComponent
            .replacingOccurrences(of: "_", with: " ")
            .replacingOccurrences(of: "-", with: " ")
    }

    static func extractAuthor(from url: URL) -> String {
        if let document = PDFDocument(url: url),
           let attributes = document.documentAttributes,
           let author = attributes[PDFDocumentAttribute.authorAttribute] as? String,
           !author.isEmpty {
            return author
        }
        return "Unknown Author"
    }
}
