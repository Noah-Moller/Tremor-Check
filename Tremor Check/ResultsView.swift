import SwiftUI
import SwiftData
import Charts

struct ResultsView: View {
    var selectedCheck: TremorCheck
    @Binding var selectedTab: Int
    @Environment(\.dismiss) private var dismiss
    var isSheet: Bool
    @State private var animateHeader = false
    @State private var animateHandStability = false
    @State private var animateVoiceAnalysis = false
    var onRedo: () -> Void
    var body: some View {
        NavigationStack {
            ZStack {
                LinearGradient(
                    gradient: Gradient(colors: [.purple.opacity(0.3), .blue.opacity(0.3)]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 30) {
                        HStack {
                            VStack(alignment: .leading) {
                                Text("Test Completed")
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                                Text(selectedCheck.date.formatted(date: .abbreviated, time: .shortened))
                                    .font(.title2.bold())
                            }
                            Spacer()
                        }
                        .padding(.horizontal)
                        .opacity(animateHeader ? 1 : 0)
                        .scaleEffect(animateHeader ? 1 : 0.9)
                        .offset(y: animateHeader ? 0 : 20)
                        
                        VStack(spacing: 15) {
                            Text("Hand Stability")
                                .font(.title2.bold())
                            
                            if let shakeAssessment = selectedCheck.shakeAssessment {
                                ZStack {
                                    Circle()
                                        .stroke(Color.gray.opacity(0.2), lineWidth: 20)
                                        .frame(width: 200, height: 200)
                                    
                                    
                                    Circle()
                                        .trim(from: 0, to: shakeAssessment / 100)
                                        .stroke(scoreColor(shakeAssessment), style: StrokeStyle(lineWidth: 20, lineCap: .round))
                                        .frame(width: 200, height: 200)
                                        .rotationEffect(.degrees(-90))
                                    
                                    VStack {
                                        Text(String(format: "%.1f", shakeAssessment))
                                            .font(.system(size: 50, weight: .bold))
                                        Text("out of 100")
                                            .font(.subheadline)
                                            .foregroundStyle(.secondary)
                                    }
                                }
                                
                                .padding()
                                
                                Text(stabilityAssessment(score: shakeAssessment))
                                    .font(.headline)
                                    .multilineTextAlignment(.center)
                                    .padding(.horizontal)
                            }
                        }
                        .padding()
                        .background(Color.gray.opacity(0.1))
                        .cornerRadius(15)
                        .padding(.horizontal)
                        .opacity(animateHandStability ? 1 : 0)
                        .scaleEffect(animateHandStability ? 1 : 0.9)
                        .offset(y: animateHandStability ? 0 : 20)
                        
                        VStack(alignment: .leading, spacing: 15) {
                            Text("Voice Analysis")
                                .font(.title2.bold())
                                .padding(.horizontal)
                            
                            
                            VStack(spacing: 20) {
                                HStack(spacing: 20) {
                                    VoiceMetricView(
                                        title: "Average Jitter",
                                        value: selectedCheck.voiceAssessment.averageJitter,
                                        unit: "%",
                                        description: "Variation in pitch between cycles"
                                    )
                                    
                                    Divider()
                                    
                                    VoiceMetricView(
                                        title: "Average Shimmer",
                                        value: selectedCheck.voiceAssessment.averageShimmer,
                                        unit: "%",
                                        description: "Variation in amplitude between cycles"
                                    )
                                }
                                
                                Divider()
                                
                                VStack(alignment: .leading, spacing: 15) {
                                    Text("Detailed Voice Metrics")
                                        .font(.headline)
                                    
                                    ScrollView(.horizontal, showsIndicators: false) {
                                        HStack(spacing: 20) {
                                            ForEach(selectedCheck.voiceAssessment.results) { result in
                                                DetailedVoiceCard(result: result)
                                            }
                                        }
                                        .padding(.horizontal)
                                    }
                                }
                                
                                VStack(alignment: .leading, spacing: 10) {
                                    Text("Assessment")
                                        .font(.headline)
                                    
                                    Text(voiceAssessment(jitter: selectedCheck.voiceAssessment.averageJitter,
                                                         shimmer: selectedCheck.voiceAssessment.averageShimmer))
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                                }
                            }
                            .padding()
                            .background(Color.gray.opacity(0.1))
                            .cornerRadius(15)
                            .padding(.horizontal)
                        }
                        .opacity(animateVoiceAnalysis ? 1 : 0)
                        .scaleEffect(animateVoiceAnalysis ? 1 : 0.9)
                        .offset(y: animateVoiceAnalysis ? 0 : 20)
                        
                        if !isSheet {
                            Button {
                                onRedo()
                            } label: {
                                HStack {
                                    Text("Redo Test")
                                        .font(.title3)
                                    Image(systemName: "arrow.uturn.right")
                                }
                                .padding(.horizontal, 40)
                                .padding(.vertical, 20)
                                .background(Color.blue)
                                .foregroundColor(.white)
                                .cornerRadius(20)
                            }
                        }
                    }
                    .padding(.vertical)
                }
            }
            .toolbar(content: {
                ToolbarItem {
                    if isSheet {
                        Button("Done") {
                            dismiss()
                        }
                    }
                }
            })
            .navigationTitle(selectedCheck.voiceAssessment.isComplete ? "Test Results" : "Results")
            .onAppear {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    withAnimation(.spring(response: 0.7, dampingFraction: 0.7, blendDuration: 0.2)) {
                        animateHeader = true
                    }
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
                    withAnimation(.spring(response: 0.7, dampingFraction: 0.7, blendDuration: 0.2)) {
                        animateHandStability = true
                    }
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.9) {
                    withAnimation(.spring(response: 0.7, dampingFraction: 0.7, blendDuration: 0.2)) {
                        animateVoiceAnalysis = true
                    }
                }
            }
        }
    }
    
    private func scoreColor(_ score: Double) -> Color {
        switch score {
        case 0..<40: return .red
        case 40..<70: return .orange
        default: return .green
        }
    }
    
    private func stabilityAssessment(score: Double) -> String {
        switch score {
        case 0..<40:
            return "Significant tremor detected. Consider consulting a healthcare professional."
        case 40..<70:
            return "Mild tremor detected. Monitor your symptoms and consider regular check-ups."
        default:
            return "No significant tremor detected. Continue monitoring regularly."
        }
    }
    
    private func voiceAssessment(jitter: Double, shimmer: Double) -> String {
        var assessment = ""
        
        if jitter > 20 || shimmer > 25 {
            assessment = "Potential vocal tremor detected. "
            
            if jitter > 20 {
                assessment += "The jitter value (\(String(format: "%.2f", jitter))%) is above the typical threshold of 20%. "
            }
            
            if shimmer > 25 {
                assessment += "The shimmer value (\(String(format: "%.2f", shimmer))%) is above the typical threshold of 25%. "
            }
            
            assessment += "\nThese measurements suggest variations in vocal stability that might indicate tremor. Consider consulting with a healthcare professional for further evaluation."
        } else {
            assessment = "Voice measurements are within typical ranges. No significant vocal tremor detected. Continue monitoring for any changes over time."
        }
        
        return assessment
    }
}

struct VoiceMetricView: View {
    let title: String
    let value: Double
    let unit: String
    let description: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.headline)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            HStack(alignment: .firstTextBaseline) {
                Text(String(format: "%.2f", value))
                    .font(.system(size: 34, weight: .bold))
                Text(unit)
                    .font(.title2)
                    .foregroundStyle(.secondary)
            }
            
            Text(description)
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
    }
}

struct DetailedVoiceCard: View {
    let result: PhraseResult
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Phrase \(result.phrase)")
                .font(.headline)
                .lineLimit(2)
            
            VStack(alignment: .leading, spacing: 8) {
                DetailMetricRow(title: "Jitter", value: result.jitter, unit: "%")
                DetailMetricRow(title: "Shimmer", value: result.shimmer, unit: "%")
                DetailMetricRow(title: "HNR", value: result.hnr, unit: "dB")
                DetailMetricRow(title: "NHR", value: result.nhr)
                DetailMetricRow(title: "PPE", value: result.ppe)
            }
        }
        .padding()
        .frame(width: 280)
        .background(Color.white)
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.05), radius: 5)
    }
}

struct DetailMetricRow: View {
    let title: String
    let value: Double
    var unit: String = ""
    
    var body: some View {
        HStack {
            Text(title)
                .font(.subheadline)
                .foregroundStyle(.secondary)
            Spacer()
            Text("\(String(format: "%.2f", value))\(unit)")
                .font(.subheadline.bold())
        }
    }
}
