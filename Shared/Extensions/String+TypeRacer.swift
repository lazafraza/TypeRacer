import Foundation

extension String {
    var wordCount: Int {
        split(separator: " ").count
    }

    /// Normalizes smart quotes, dashes, and other iOS keyboard substitutions to ASCII equivalents.
    var normalized: String {
        self.replacingOccurrences(of: "\u{2018}", with: "'")  // left single quote
            .replacingOccurrences(of: "\u{2019}", with: "'")  // right single quote (smart apostrophe)
            .replacingOccurrences(of: "\u{201C}", with: "\"") // left double quote
            .replacingOccurrences(of: "\u{201D}", with: "\"") // right double quote
            .replacingOccurrences(of: "\u{2014}", with: "--") // em dash
            .replacingOccurrences(of: "\u{2013}", with: "-")  // en dash
    }

    /// Returns progress (0.0–1.0) of typed text against the target sentence.
    func typingProgress(against target: String) -> Double {
        guard !target.isEmpty else { return 1.0 }
        let targetChars = Array(target.normalized)
        let typedChars = Array(self.normalized)
        var correct = 0
        for i in 0..<min(typedChars.count, targetChars.count) {
            if typedChars[i] == targetChars[i] {
                correct += 1
            } else {
                break // stop at first error
            }
        }
        return Double(correct) / Double(targetChars.count)
    }

    /// Returns the number of correctly typed characters from the start.
    func correctCharacterCount(against target: String) -> Int {
        let targetChars = Array(target.normalized)
        let typedChars = Array(self.normalized)
        var count = 0
        for i in 0..<min(typedChars.count, targetChars.count) {
            if typedChars[i] == targetChars[i] {
                count += 1
            } else {
                break
            }
        }
        return count
    }

    /// Calculates words per minute given elapsed seconds and correct character count.
    static func wpm(correctChars: Int, elapsedSeconds: TimeInterval) -> Int {
        guard elapsedSeconds > 0 else { return 0 }
        // Standard: 1 word = 5 characters
        let words = Double(correctChars) / 5.0
        let minutes = elapsedSeconds / 60.0
        return Int(words / minutes)
    }
}
