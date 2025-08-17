import Foundation

/// A simplified implementation of a tokenizer for the Gemma model.
/// This class loads a vocabulary from a JSON file and provides methods
/// for encoding text into token IDs and decoding token IDs back into text.
///
/// **Note:** This is not a full SentencePiece implementation. It uses a simplified,
/// rule-based tokenization approach that is sufficient for basic prompts.
final class GemmaTokenizer {

    private let vocabulary: [String: Int]
    private let reverseVocabulary: [Int: String]

    enum TokenizerError: Error {
        case fileNotFound
        case parsingFailed
    }

    /// Initializes the tokenizer with a vocabulary file from the app's bundle.
    /// - Parameter modelName: The name of the tokenizer JSON file (e.g., "tokenizer").
    init(modelName: String = "tokenizer") throws {
        guard let url = Bundle.main.url(forResource: modelName, withExtension: "json") else {
            throw TokenizerError.fileNotFound
        }

        do {
            let data = try Data(contentsOf: url)
            // The JSON from Hugging Face `save_vocabulary` is a dictionary of [token: id].
            let vocabData = try JSONDecoder().decode([String: Int].self, from: data)
            self.vocabulary = vocabData

            // Create the reverse mapping for decoding
            var reverseVocab = [Int: String]()
            for (token, id) in vocabData {
                reverseVocab[id] = token
            }
            self.reverseVocabulary = reverseVocab

        } catch {
            throw TokenizerError.parsingFailed
        }
    }

    /// Encodes a string of text into an array of token IDs.
    func encode(text: String) -> [Int] {
        // A very simplified tokenization strategy.
        // A real implementation would use a more complex algorithm like Byte-Pair Encoding
        // or WordPiece, but that is beyond the scope of this project.

        // 1. Add a start-of-sequence token (BOS). Gemma's BOS token ID is 2.
        var tokens = [2]

        // 2. Normalize and split the text.
        let normalizedText = text.lowercased()
        let words = normalizedText.components(separatedBy: .whitespacesAndNewlines)

        // 3. Convert words to tokens.
        for word in words where !word.isEmpty {
            if let tokenId = vocabulary[word] {
                tokens.append(tokenId)
            } else {
                // If a word is not in the vocabulary, break it down into characters.
                for char in word {
                    if let charId = vocabulary[String(char)] {
                        tokens.append(charId)
                    } else {
                        // Use the Unknown Token (UNK) ID, which is 3 for Gemma.
                        tokens.append(3)
                    }
                }
            }
        }

        return tokens
    }

    /// Decodes an array of token IDs back into a string.
    func decode(tokens: [Int]) -> String {
        var text = ""
        for token in tokens {
            if let word = reverseVocabulary[token] {
                // The " " character (U+2581) is used by SentencePiece to represent a space.
                // We replace it with a standard space for readability.
                let readableWord = word.replacingOccurrences(of: " ", with: " ")
                text.append(readableWord)
            }
        }
        return text.trimmingCharacters(in: .whitespaces)
    }
}
