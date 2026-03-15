import Foundation
import Observation

@Observable
final class ReadingEngine {
    var currentWord: String = ""
    var isPlaying: Bool = false
    var wordIndex: Int = 0
    var wordsPerMinute: Int = 300
    var transitionDuration: Double = 0
    var sentencePauseEnabled: Bool = true
    var scaleAmount: Double = 0

    var isChapterHeading: Bool = false
    var isNewPage: Bool = false

    private var timer: Timer?
    private var didPauseForSentence: Bool = false
    private var chapterPauseTicksRemaining: Int = 0
    private(set) var words: [String] = []
    private var book: Book?

    var totalWords: Int { words.count }

    var progressPercentage: Double {
        guard !words.isEmpty else { return 0 }
        return Double(wordIndex) / Double(words.count) * 100
    }

    var timeRemainingSeconds: Double {
        guard wordsPerMinute > 0 else { return 0 }
        let remaining = max(0, words.count - wordIndex)
        return Double(remaining) / Double(wordsPerMinute) * 60
    }

    var timeRemainingFormatted: String {
        let total = Int(timeRemainingSeconds)
        let hours = total / 3600
        let minutes = (total % 3600) / 60
        let seconds = total % 60
        if hours > 0 {
            return String(format: "%dh %02dm %02ds", hours, minutes, seconds)
        } else if minutes > 0 {
            return String(format: "%dm %02ds", minutes, seconds)
        } else {
            return String(format: "%ds", seconds)
        }
    }

    var finishTimeFormatted: String {
        let finishDate = Date().addingTimeInterval(timeRemainingSeconds)
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mma"
        formatter.amSymbol = "pm"
        formatter.pmSymbol = "pm"
        formatter.amSymbol = "am"
        formatter.pmSymbol = "pm"
        return "done " + formatter.string(from: finishDate).lowercased()
    }

    func load(book: Book) {
        pause()
        self.book = book
        self.words = book.words
        self.wordIndex = book.currentWordIndex
        self.wordsPerMinute = book.wordsPerMinute
        self.transitionDuration = book.transitionDuration
        self.sentencePauseEnabled = book.sentencePauseEnabled
        self.scaleAmount = book.scaleAmount
        updateCurrentWord()
    }

    func play() {
        guard !words.isEmpty, wordIndex < words.count else { return }
        isPlaying = true
        startTimer()
    }

    func pause() {
        isPlaying = false
        timer?.invalidate()
        timer = nil
        saveProgress()
    }

    func toggle() {
        if isPlaying {
            pause()
        } else {
            play()
        }
    }

    func back30() {
        let wasPlaying = isPlaying
        if wasPlaying { pause() }
        wordIndex = max(0, wordIndex - 30)
        updateCurrentWord()
        if wasPlaying { play() }
    }

    func seek(to index: Int) {
        let wasPlaying = isPlaying
        if wasPlaying { pause() }
        wordIndex = max(0, min(index, words.count - 1))
        updateCurrentWord()
        if wasPlaying { play() }
    }

    func updateTransition(_ duration: Double) {
        transitionDuration = duration
        book?.transitionDuration = duration
    }

    func updateSentencePause(_ enabled: Bool) {
        sentencePauseEnabled = enabled
        book?.sentencePauseEnabled = enabled
    }

    func updateScaleAmount(_ amount: Double) {
        scaleAmount = amount
        book?.scaleAmount = amount
    }

    func updateSpeed(_ wpm: Int) {
        wordsPerMinute = wpm
        book?.wordsPerMinute = wpm
        // Don't touch the timer — next tick picks up the new speed automatically
    }

    func saveProgress() {
        guard let book else { return }
        book.currentWordIndex = wordIndex
        book.dateLastRead = Date()
    }

    private func startTimer() {
        timer?.invalidate()
        scheduleNextTick()
    }

    private func scheduleNextTick() {
        guard isPlaying else { return }
        let interval = 60.0 / Double(wordsPerMinute)
        let nextTimer = Timer(timeInterval: interval, repeats: false) { [weak self] _ in
            self?.advanceWord()
            self?.scheduleNextTick()
        }
        RunLoop.main.add(nextTimer, forMode: .common)
        timer = nextTimer
    }

    private func advanceWord() {
        // Hold on chapter headings for multiple ticks (~1 second)
        if chapterPauseTicksRemaining > 0 {
            chapterPauseTicksRemaining -= 1
            return
        }

        // Dwell on sentence-ending word for one extra tick
        if sentencePauseEnabled && isSentenceEnding(currentWord) && !didPauseForSentence {
            didPauseForSentence = true
            return
        }

        guard wordIndex < words.count - 1 else {
            pause()
            return
        }
        didPauseForSentence = false
        wordIndex += 1
        updateCurrentWord()

        // If new word is a chapter heading, pause for ~1 second
        if isChapterHeading {
            let interval = 60.0 / Double(wordsPerMinute)
            let ticks = max(1, Int(1.0 / interval) - 1)
            chapterPauseTicksRemaining = ticks
        }
    }

    /// How many ticks the current word will display for (1 = normal, 2 = sentence pause, more = chapter).
    var currentWordTickCount: Int {
        if isChapterHeading {
            let interval = 60.0 / Double(wordsPerMinute)
            return max(1, Int(1.0 / interval))
        }
        if sentencePauseEnabled && isSentenceEnding(currentWord) {
            return 2
        }
        return 1
    }

    private func isSentenceEnding(_ word: String) -> Bool {
        guard let last = word.last else { return false }
        return last == "." || last == "!" || last == "?"
    }

    private func updateCurrentWord() {
        if words.indices.contains(wordIndex) {
            var raw = words[wordIndex]

            // Check for page boundary marker
            if raw.hasPrefix(PDFTextExtractor.pageMarker) {
                raw = String(raw.dropFirst(PDFTextExtractor.pageMarker.count))
                isNewPage = true
            } else {
                isNewPage = false
            }

            // Check for chapter heading marker
            if raw.hasPrefix(PDFTextExtractor.chapterPrefix) {
                currentWord = String(raw.dropFirst(PDFTextExtractor.chapterPrefix.count)).uppercased()
                isChapterHeading = true
            } else {
                currentWord = raw
                isChapterHeading = false
            }
        } else {
            currentWord = ""
            isChapterHeading = false
            isNewPage = false
        }
    }
}
