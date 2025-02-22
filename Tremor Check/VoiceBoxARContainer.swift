import SwiftUI

struct VoiceBoxARContainer: View {
    @StateObject private var viewModel = VoiceBoxViewModel()

    var latestCheck: TremorCheck?
    @State private var text = "As Parkinson's progresses, the muscles that\ncontrol in the epiglottis will become weaker."
    var body: some View {
        ZStack {
            VoiceBoxARView(text: text)
                .ignoresSafeArea()
            
            Text(viewModel.commentaryText)
                .font(.headline)
                .padding()
                .multilineTextAlignment(.center)
                .foregroundStyle(.white)
                .padding(.top, 800)
        }
        .onAppear {
            viewModel.updateState(basedOn: latestCheck)
            text = "As Parkinson's progresses, the muscles that\ncontrol in the epiglottis will become weaker."
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
                if (latestCheck?.voiceAssessment.averageJitter ?? 0.0) > 20.0 && (latestCheck?.voiceAssessment.averageShimmer ?? 0.0) > 25.0 {
                    text = "Your epiglottis could have lesser muscle\ncontrol than what is normal based on your latest Tremor Check."
                } else {
                    text = "Your epiglottis has the expected amount of muscle control as indicated on your latest Tremor Check."
                }
            }
        }
        .onAppear {
            viewModel.updateState(basedOn: latestCheck)
        }
    }
}
