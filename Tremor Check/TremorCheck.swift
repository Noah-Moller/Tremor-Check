import Foundation
import SwiftData

struct StoredVoiceResult: Codable {
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
    let date: Date
    let id: String
}

struct StoredVoiceAssessment: Codable {
    var results: [StoredVoiceResult]
    var averageJitter: Double
    var averageShimmer: Double
    
    init(from assessment: VoiceAssessment) {
        print("Creating StoredVoiceAssessment from VoiceAssessment")
        print("Input results count: \(assessment.results.count)")
        
        self.results = assessment.results.map { result in
            StoredVoiceResult(
                phrase: result.phrase,
                jitter: result.jitter,
                shimmer: result.shimmer,
                jitterAbs: result.jitterAbs,
                rap: result.rap,
                ppq: result.ppq,
                hnr: result.hnr,
                nhr: result.nhr,
                ppe: result.ppe,
                f0Mean: result.f0Mean,
                f0Max: result.f0Max,
                f0Min: result.f0Min,
                spread1: result.spread1,
                spread2: result.spread2,
                date: result.date,
                id: result.id
            )
        }
        self.averageJitter = assessment.averageJitter
        self.averageShimmer = assessment.averageShimmer
        
        print("Created StoredVoiceAssessment with \(self.results.count) results")
    }
}

@Model
class TremorCheck: Identifiable {
    var id: String
    var date: Date
    var storedVoiceData: Data
    var shakeAssessment: Double?
    var isDemoData: Bool
    
    @Transient
    private var cachedVoiceAssessment: VoiceAssessment?
    
    @Transient
    var voiceAssessment: VoiceAssessment {
        get {
            if let cached = cachedVoiceAssessment {
                return cached
            }
            
            if let stored = try? JSONDecoder().decode(StoredVoiceAssessment.self, from: storedVoiceData) {
                let assessment = VoiceAssessment(fromStoredResults: stored.results)
                cachedVoiceAssessment = assessment
                return assessment
            }
            let empty = VoiceAssessment()
            cachedVoiceAssessment = empty
            return empty
        }
        set {
            let stored = StoredVoiceAssessment(from: newValue)
            if let data = try? JSONEncoder().encode(stored) {
                storedVoiceData = data
                cachedVoiceAssessment = newValue
            }
        }
    }
    
    func clearCache() {
        cachedVoiceAssessment = nil
    }
    
    init(id: String = UUID().uuidString,
         date: Date = Date(),
         voiceAssessment: VoiceAssessment = VoiceAssessment(),
         shakeAssessment: Double = 0.0, isDemoData: Bool = false) {
        self.id = id
        self.date = date
        self.storedVoiceData = Data()
        self.shakeAssessment = shakeAssessment
        self.cachedVoiceAssessment = nil
        self.isDemoData = isDemoData
        self.voiceAssessment = voiceAssessment
    }
}

extension TremorCheck {
    func addVoiceResult(features: [String: Double], audioURL: URL) {
        var currentAssessment = self.voiceAssessment
        let result = currentAssessment.addResult(features: features, audioURL: audioURL)
        currentAssessment.results.append(result)
        self.voiceAssessment = currentAssessment
    }
}
