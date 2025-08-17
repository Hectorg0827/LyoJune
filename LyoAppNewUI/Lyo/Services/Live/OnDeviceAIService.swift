import Foundation
import CoreML

/// The live implementation of the `OnDeviceAIServicing` protocol.
/// This service loads a local Core ML model and its tokenizer to perform
/// on-device text generation.
public final class OnDeviceAIService: OnDeviceAIServicing {

    private let tokenizer: GemmaTokenizer
    private let model: MLModel
    private let modelInputName: String // The name of the input tensor, e.g., "input_ids"

    enum OnDeviceAIError: Error {
        case modelNotFound
        case failedToLoadModel(Error)
        case inferenceFailed(String)
        case tokenizationFailed
    }

    public init?() {
        do {
            self.tokenizer = try GemmaTokenizer()

            guard let modelURL = Bundle.main.url(forResource: "gemma_2b", withExtension: "mlmodelc") else {
                print("Error: gemma_2b.mlmodelc not found in bundle.")
                throw OnDeviceAIError.modelNotFound
            }

            self.model = try MLModel(contentsOf: modelURL)

            // The input name is defined in the Core ML model itself. We need to know it.
            // Based on the conversion script, it should be "input_ids".
            self.modelInputName = "input_ids"

        } catch {
            print("Failed to initialize OnDeviceAIService: \(error)")
            return nil
        }
    }

    /// Generates a response by running the local Core ML model autoregressively.
    public func generate(prompt: String) async throws -> String {
        var generatedTokenIds = tokenizer.encode(text: prompt)
        let maxResponseLength = 100 // Limit the generation length
        let endOfSequenceTokenId = 1 // Gemma's EOS token ID

        for _ in 0..<maxResponseLength {
            // 1. Prepare Model Input
            let inputShape = [1, NSNumber(value: generatedTokenIds.count)]
            guard let inputArray = try? MLMultiArray(shape: inputShape, dataType: .int32) else {
                throw OnDeviceAIError.inferenceFailed("Failed to create input MLMultiArray.")
            }

            for (index, tokenId) in generatedTokenIds.enumerated() {
                inputArray[index] = NSNumber(value: tokenId)
            }

            let provider = try MLDictionaryFeatureProvider(dictionary: [modelInputName: inputArray])

            // 2. Run Prediction
            let output = try model.prediction(from: provider)

            // 3. Process Output
            guard let outputLogits = output.featureValue(for: "logits")?.multiArrayValue else {
                throw OnDeviceAIError.inferenceFailed("Could not get logits from model output.")
            }

            // 4. Find the next token using argmax
            let nextTokenId = findNextToken(from: outputLogits, currentSequenceLength: generatedTokenIds.count)

            // 5. Check for stop condition
            if nextTokenId == endOfSequenceTokenId {
                break
            }

            // 6. Append the new token and continue the loop
            generatedTokenIds.append(nextTokenId)
        }

        // 7. Decode the final sequence of tokens
        return tokenizer.decode(tokens: generatedTokenIds)
    }

    /// Finds the token with the highest probability from the model's logit output.
    private func findNextToken(from logits: MLMultiArray, currentSequenceLength: Int) -> Int {
        // The logits tensor shape is [1, sequence_length, vocab_size].
        // We only care about the logits for the *last* token in the sequence.
        let lastTokenLogitsStartIndex = (currentSequenceLength - 1) * logits.strides[1].intValue

        var maxLogit: Double = -Double.infinity
        var maxIndex: Int = -1

        for i in 0..<tokenizer.vocabulary.count {
            let logitIndex = lastTokenLogitsStartIndex + i
            let currentLogit = logits[logitIndex].doubleValue
            if currentLogit > maxLogit {
                maxLogit = currentLogit
                maxIndex = i
            }
        }

        return maxIndex
    }
}
