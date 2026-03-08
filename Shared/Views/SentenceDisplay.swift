import SwiftUI

struct SentenceDisplay: View {
    let sentence: String
    let typedText: String

    var body: some View {
        let sentenceChars = Array(sentence.normalized)
        let typedChars = Array(typedText.normalized)

        let text = sentenceChars.enumerated().map { index, char -> Text in
            if index < typedChars.count {
                if typedChars[index] == char {
                    return Text(String(char)).foregroundColor(.green)
                } else {
                    return Text(String(char)).foregroundColor(.red).underline()
                }
            } else if index == typedChars.count {
                return Text(String(char)).foregroundColor(.primary).bold()
            } else {
                return Text(String(char)).foregroundColor(.secondary)
            }
        }.reduce(Text(""), +)

        text
            .font(.title3.monospaced())
            .lineSpacing(6)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding()
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
    }
}
