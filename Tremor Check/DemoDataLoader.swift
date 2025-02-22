import SwiftUI
import SwiftData

struct DemoDataLoader: View {
    @Environment(\.modelContext) var context
    @AppStorage("isNewUser") private var isNewUser: Bool = true

    var body: some View {
        // An invisible view that performs the insertion onAppear.
        Color.clear.onAppear {
            if isNewUser {
                insertDemoData()
                isNewUser = false
            }
        }
    }
    
    private func insertDemoData() {
        let demoCount = 10
        // Define a fixed base date.
        if let monthInt = Calendar.current.dateComponents([.month], from: Date()).month {
            let baseDate = Calendar.current.date(from: DateComponents(year: 2025, month: monthInt, day: 2))!
            for i in 0..<demoCount {
                // Spread each demo TremorCheck 3 days apart.
                let demoCheckDate = Calendar.current.date(byAdding: .day, value: i * 3, to: baseDate)!
                
                // Create a new VoiceAssessment instance.
                let assessment = VoiceAssessment()
                var demoResults: [PhraseResult] = []
                
                // For each phrase (4 total) in the assessment, create a demo PhraseResult.
                for (index, phrase) in assessment.phrases.enumerated() {
                    let resultDate = Calendar.current.date(byAdding: .hour, value: index, to: demoCheckDate)!
                    
                    let demoResult = PhraseResult(
                        phrase: phrase,
                        jitter: Double.random(in: 8.0...25.0),
                        shimmer: Double.random(in: 10.0...30.0),
                        jitterAbs: Double.random(in: 0.5...1.5),
                        rap: Double.random(in: 0.2...0.8),
                        ppq: Double.random(in: 0.2...0.8),
                        hnr: Double.random(in: 15.0...25.0),
                        nhr: Double.random(in: 10.0...20.0),
                        ppe: Double.random(in: 0.1...0.5),
                        f0Mean: Double.random(in: 100.0...150.0),
                        f0Max: Double.random(in: 150.0...200.0),
                        f0Min: Double.random(in: 80.0...100.0),
                        spread1: Double.random(in: 2.0...5.0),
                        spread2: Double.random(in: 2.0...5.0),
                        audioURL: URL(fileURLWithPath: "/demo/audio_\(i)_\(index).wav"),
                        date: resultDate,
                        id: UUID().uuidString
                    )
                    demoResults.append(demoResult)
                }
                
                // Update the assessment with the complete set of results.
                assessment.results = demoResults
                assessment.currentPhraseIndex = demoResults.count
                assessment.isComplete = true
                assessment.averageJitter = demoResults.map { $0.jitter }.reduce(0, +) / Double(demoResults.count)
                assessment.averageShimmer = demoResults.map { $0.shimmer }.reduce(0, +) / Double(demoResults.count)
                
                // Create a TremorCheck with the demo VoiceAssessment and a random shakeAssessment.
                let shakeAssessment = Double.random(in: 40.0...100.0)
                let demoCheck = TremorCheck(voiceAssessment: assessment, shakeAssessment: shakeAssessment, isDemoData: true)
                
                demoCheck.date = demoCheckDate
                
                // Insert the demo TremorCheck into the model context.
                context.insert(demoCheck)
            }
            
            do {
                try context.save()
                print("Demo data inserted successfully with hard-set dates.")
            } catch {
                print("Error inserting demo data: \(error)")
            }
        }
    }
}
