import SwiftUI

struct PhraseResult: Equatable, Codable, Identifiable {
    let phrase: String
    let jitter: Double
    let shimmer: Double
    let jitterAbs: Double
    let rap: Double
    let ppq: Double
    let hnr: Double
    let nhr: Double
    let ppe: Double
    let f0Mean: Double
    let f0Max: Double
    let f0Min: Double
    let spread1: Double
    let spread2: Double
    let audioURL: URL
    let date: Date
    let id: String
    
    enum CodingKeys: String, CodingKey {
        case phrase, jitter, shimmer, jitterAbs, rap, ppq, hnr, nhr, ppe, f0Mean, f0Max, f0Min, spread1, spread2, audioURL
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(phrase, forKey: .phrase)
        try container.encode(jitter, forKey: .jitter)
        try container.encode(shimmer, forKey: .shimmer)
        try container.encode(jitterAbs, forKey: .jitterAbs)
        try container.encode(rap, forKey: .rap)
        try container.encode(ppq, forKey: .ppq)
        try container.encode(hnr, forKey: .hnr)
        try container.encode(nhr, forKey: .nhr)
        try container.encode(ppe, forKey: .ppe)
        try container.encode(f0Mean, forKey: .f0Mean)
        try container.encode(f0Max, forKey: .f0Max)
        try container.encode(f0Min, forKey: .f0Min)
        try container.encode(spread1, forKey: .spread1)
        try container.encode(spread2, forKey: .spread2)
        try container.encode(audioURL.absoluteString, forKey: .audioURL)
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        phrase = try container.decode(String.self, forKey: .phrase)
        jitter = try container.decode(Double.self, forKey: .jitter)
        shimmer = try container.decode(Double.self, forKey: .shimmer)
        jitterAbs = try container.decode(Double.self, forKey: .jitterAbs)
        rap = try container.decode(Double.self, forKey: .rap)
        ppq = try container.decode(Double.self, forKey: .ppq)
        hnr = try container.decode(Double.self, forKey: .hnr)
        nhr = try container.decode(Double.self, forKey: .nhr)
        ppe = try container.decode(Double.self, forKey: .ppe)
        f0Mean = try container.decode(Double.self, forKey: .f0Mean)
        f0Max = try container.decode(Double.self, forKey: .f0Max)
        f0Min = try container.decode(Double.self, forKey: .f0Min)
        spread1 = try container.decode(Double.self, forKey: .spread1)
        spread2 = try container.decode(Double.self, forKey: .spread2)
        let urlString = try container.decode(String.self, forKey: .audioURL)
        audioURL = URL(string: urlString)!
        date = Date()
        id = UUID().uuidString
    }
    
    init(phrase: String, jitter: Double, shimmer: Double, jitterAbs: Double, rap: Double, ppq: Double, hnr: Double, nhr: Double, ppe: Double, f0Mean: Double, f0Max: Double, f0Min: Double, spread1: Double, spread2: Double, audioURL: URL, date: Date, id: String) {
        self.phrase = phrase
        self.jitter = jitter
        self.shimmer = shimmer
        self.jitterAbs = jitterAbs
        self.rap = rap
        self.ppq = ppq
        self.hnr = hnr
        self.nhr = nhr
        self.ppe = ppe
        self.f0Mean = f0Mean
        self.f0Max = f0Max
        self.f0Min = f0Min
        self.spread1 = spread1
        self.spread2 = spread2
        self.audioURL = audioURL
        self.date = date
        self.id = id
    }
    
    static func == (lhs: PhraseResult, rhs: PhraseResult) -> Bool {
        return lhs.phrase == rhs.phrase &&
        lhs.jitter == rhs.jitter &&
        lhs.shimmer == rhs.shimmer &&
        lhs.jitterAbs == rhs.jitterAbs &&
        lhs.rap == rhs.rap &&
        lhs.ppq == rhs.ppq &&
        lhs.hnr == rhs.hnr &&
        lhs.nhr == rhs.nhr &&
        lhs.ppe == rhs.ppe &&
        lhs.f0Mean == rhs.f0Mean &&
        lhs.f0Max == rhs.f0Max &&
        lhs.f0Min == rhs.f0Min &&
        lhs.spread1 == rhs.spread1 &&
        lhs.spread2 == rhs.spread2 &&
        lhs.audioURL == rhs.audioURL
    }
}

class VoiceAssessment: ObservableObject {
    // MARK: - Published Properties
    
    /// The current phrase index (zero-based).
    @Published var currentPhraseIndex: Int
    /// Flag indicating whether all phrases have been recorded.
    @Published var isComplete: Bool
    /// The average jitter calculated from the results.
    @Published var averageJitter: Double
    /// The average shimmer calculated from the results.
    @Published var averageShimmer: Double
    /// An array of all recorded phrase results.
    @Published var results: [PhraseResult]
    
    /// The list of phrases that the user is expected to record.
    let phrases = [
        "The rainbow appears after the rain",
        "Today is a sunny day in the park",
        "She sells seashells by the seashore",
        "Please call Stella and ask her to bring these things"
    ]
    
    // MARK: - Initializers
    
    /// Default initializer: starts with no results.
    init() {
        self.currentPhraseIndex = 0
        self.isComplete = false
        self.averageJitter = 0.0
        self.averageShimmer = 0.0
        self.results = []
    }
    
    /// Convenience initializer to rebuild from stored voice results.
    /// This is used when decoding the JSON stored in your parent model.
    convenience init(fromStoredResults storedResults: [StoredVoiceResult]) {
        self.init()
        self.results = storedResults.map { storedResult in
            PhraseResult(
                phrase: storedResult.phrase,
                jitter: storedResult.jitter,
                shimmer: storedResult.shimmer,
                jitterAbs: storedResult.jitterAbs,
                rap: storedResult.rap,
                ppq: storedResult.ppq,
                hnr: storedResult.hnr,
                nhr: storedResult.nhr,
                ppe: storedResult.ppe,
                f0Mean: storedResult.f0Mean,
                f0Max: storedResult.f0Max,
                f0Min: storedResult.f0Min,
                spread1: storedResult.spread1,
                spread2: storedResult.spread2,
                audioURL: URL(fileURLWithPath: ""),
                date: storedResult.date,
                id: storedResult.id
            )
        }
        self.currentPhraseIndex = self.results.count
        self.isComplete = self.results.count >= self.phrases.count
        if isComplete {
            self.calculateAverages()
        }
    }
    
    // MARK: - Computed Properties
    
    /// Returns the current phrase that the user should record.
    var currentPhrase: String {
        return phrases[currentPhraseIndex]
    }
    
    /// Returns the progress as a value between 0 and 1.
    var progress: Double {
        return Double(results.count) / Double(phrases.count)
    }
    
    /// Indicates whether all phrases have been recorded.
    var isAllPhrasesRecorded: Bool {
        return results.count >= phrases.count
    }
    
    // MARK: - Methods
    
    /// Creates a new result for the current phrase from the given features and audio URL.
    /// (Note: This method only creates and returns the result—it does not add it to `results`.)
    func addResult(features: [String: Double], audioURL: URL) -> PhraseResult {
        let result = PhraseResult(
            phrase: phrases[currentPhraseIndex],
            jitter: features["jitter_percent"] ?? 0.0,
            shimmer: features["shimmer_percent"] ?? 0.0,
            jitterAbs: features["jitter_abs"] ?? 0.0,
            rap: features["rap"] ?? 0.0,
            ppq: features["ppq"] ?? 0.0,
            hnr: features["hnr"] ?? 0.0,
            nhr: features["nhr"] ?? 0.0,
            ppe: features["ppe"] ?? 0.0,
            f0Mean: features["f0_mean"] ?? 0.0,
            f0Max: features["f0_max"] ?? 0.0,
            f0Min: features["f0_min"] ?? 0.0,
            spread1: features["spread1"] ?? 0.0,
            spread2: features["spread2"] ?? 0.0,
            audioURL: audioURL,
            date: Date(),
            id: UUID().uuidString
        )
        
        // Update the current phrase index or mark as complete.
        if currentPhraseIndex < phrases.count - 1 {
            currentPhraseIndex += 1
        } else {
            calculateAverages()
            isComplete = true
        }
        
        return result
    }
    
    /// Calculates the average jitter and shimmer from the recorded results.
    private func calculateAverages() {
        guard !results.isEmpty else { return }
        averageJitter = results.map { $0.jitter }.reduce(0, +) / Double(results.count)
        averageShimmer = results.map { $0.shimmer }.reduce(0, +) / Double(results.count)
    }
    
    /// Resets the voice assessment to its initial state.
    func reset() {
        currentPhraseIndex = 0
        results = []
        isComplete = false
        averageJitter = 0.0
        averageShimmer = 0.0
    }
    
    /// Adds an already-created result (for example, when copying an existing result).
    func copyResult(_ result: PhraseResult) {
        results.append(result)
        if currentPhraseIndex < phrases.count - 1 {
            currentPhraseIndex += 1
        } else {
            calculateAverages()
            isComplete = true
        }
    }
}
