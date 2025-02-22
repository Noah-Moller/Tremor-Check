import SwiftUI

class VoiceBoxViewModel: ObservableObject {
    @Published var rotationAngle: Float = 0
    
    @Published var commentaryText: String = "Analyzing voice box..."

    func updateState(basedOn check: TremorCheck?) {
        guard let check = check else {
            commentaryText = "No data available"
            rotationAngle = 0
            return
        }

        let jitter = check.voiceAssessment.averageJitter
        let shimmer = check.voiceAssessment.averageShimmer
        if jitter > 20.0 && shimmer > 25.0 {
            commentaryText = """
            Your recent voice test shows elevated jitter, suggesting potential vocal tremor.
            The laryngeal muscles might be more tense, leading to pitch instability.
            """
        } else {
            commentaryText = """
            Your voice test is within normal ranges. Vocal folds appear stable with minimal tremor.
            """
        }
    }
}
