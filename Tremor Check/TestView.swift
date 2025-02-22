import SwiftUI
import SwiftData

enum TestStage {
    case intro
    case voiceTest
    case fingerTest
    case results
}

struct TestView: View {
    @Binding var selectedTab: Int
    @State private var stage: TestStage = .intro
    @State private var isVisible = false
    @Environment(\.modelContext) var modelContext
    @State private var currentCheck: TremorCheck? = nil
    @StateObject private var assessment = VoiceAssessment()
    
    var body: some View {
        NavigationStack {
            ZStack {
                LinearGradient(
                    gradient: Gradient(colors: [.purple.opacity(0.3), .blue.opacity(0.3)]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                switch stage {
                case .intro:
                    IntroStageView(isVisible: $isVisible) {
                        // When starting a test, create a new TremorCheck with the (reset) assessment.
                        let newCheck = TremorCheck(voiceAssessment: assessment, shakeAssessment: 0.0)
                        currentCheck = newCheck
                        print("New TremorCheck created with ID: \(newCheck.id)")
                        withAnimation(.easeInOut) {
                            stage = .voiceTest
                        }
                    }
                    .transition(.move(edge: .leading).combined(with: .opacity))
                    
                case .voiceTest:
                    VoiceTestStageView(assessment: assessment, currentCheck: currentCheck!) {
                        withAnimation(.easeInOut) {
                            stage = .fingerTest
                        }
                    }
                    .transition(.asymmetric(
                        insertion: .move(edge: .trailing).combined(with: .opacity),
                        removal: .move(edge: .leading).combined(with: .opacity)
                    ))
                    
                case .fingerTest:
                    if let currentCheck = currentCheck {
                        FingerTestStageView(currentCheck: currentCheck) {
                            guard currentCheck.shakeAssessment != nil else { return }
                            withAnimation(.easeInOut) {
                                stage = .results
                            }
                        }
                        .transition(.asymmetric(
                            insertion: .move(edge: .trailing).combined(with: .opacity),
                            removal: .move(edge: .leading).combined(with: .opacity)
                        ))
                    }
                    
                case .results:
                    if let currentCheck = currentCheck {
                        ResultsView(selectedCheck: currentCheck, selectedTab: $selectedTab, isSheet: false) {
                            // When the user taps the redo test button, reset the assessment and create a new TremorCheck.
                            assessment.reset() // Reset all internal data of the assessment.
                            self.currentCheck = TremorCheck(voiceAssessment: assessment, shakeAssessment: 0.0)
                            withAnimation(.easeInOut) {
                                stage = .intro
                            }
                        }
                        .transition(.asymmetric(
                            insertion: .move(edge: .trailing).combined(with: .opacity),
                            removal: .move(edge: .leading).combined(with: .opacity)
                        ))
                        .onAppear {
                            modelContext.insert(currentCheck)
                        }
                    }
                }
            }
            .navigationBarTitle("Tremor Check")
            .animation(.easeInOut, value: stage)
        }
    }
}

struct IntroStageView: View {
    @Binding var isVisible: Bool
    @State private var showButton = false
    var onNext: () -> Void
    
    var body: some View {
        VStack(spacing: 40) {
            if isVisible {
                AnimatedTextView(
                    fullText: "You will be asked to repeat some phrases. These phrases will allow tremor check to detect degradation over the muscle control in your mouth. After this test, you will be asked to hold your finger still to detect potential issues with fine motor control.",
                    animationDuration: 0.8,
                    lineDelay: 0.7
                )
                .padding(.horizontal)
                .onAppear {
                    let totalDelay = 0.5 + (2 * 0.7) + 0.8
                    DispatchQueue.main.asyncAfter(deadline: .now() + totalDelay) {
                        withAnimation(.spring(response: 0.6, dampingFraction: 0.65, blendDuration: 0.2)) {
                            showButton = true
                        }
                    }
                }
            }
            
            if showButton {
                Button {
                    onNext()
                } label: {
                    Text("Begin")
                        .font(.title3)
                        .padding(.horizontal, 40)
                        .padding(.vertical, 20)
                        .foregroundColor(.white)
                        .background(Color.blue)
                        .cornerRadius(20)
                        .shadow(color: .blue.opacity(0.4), radius: 10, x: 0, y: 5)
                        .scaleEffect(showButton ? 1.0 : 0.8)
                        .offset(y: showButton ? 0 : 30)
                        .animation(.spring(response: 0.6, dampingFraction: 0.65, blendDuration: 0.2), value: showButton)
                }
            }
        }
        .padding()
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                withAnimation(.easeIn) {
                    isVisible = true
                }
            }
        }
    }
}

struct VoiceTestStageView: View {
    var assessment: VoiceAssessment
    var currentCheck: TremorCheck
    var onNext: () -> Void
    
    var body: some View {
        VStack {
            ContentView(currentCheck: currentCheck)
            
            if assessment.results.count == 4 {
                Button {
                    onNext()
                } label: {
                    HStack {
                        Text("Continue")
                            .font(.title3)
                        Image(systemName: "arrow.right")
                    }
                    .padding(.horizontal, 40)
                    .padding(.vertical, 20)
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(20)
                }
            }
        }
    }
}

struct FingerTestStageView: View {
    var currentCheck: TremorCheck
    var onNext: () -> Void
    @State private var showingResultsButton = false
    var body: some View {
        VStack {
            FingerStabilityTestView(currentCheck: currentCheck) {
                showingResultsButton = true
            }
            
            if showingResultsButton {
                Button {
                    onNext()
                } label: {
                    HStack {
                        Text("View Results")
                            .font(.title3)
                        Image(systemName: "arrow.right")
                    }
                    .padding(.horizontal, 40)
                    .padding(.vertical, 20)
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(20)
                }
            }
        }
    }
}

struct ResultsStageView: View {
    @Binding var selectedTab: Int
    var currentCheck: TremorCheck
    var onNext: () -> Void
    var isSheet: Bool
    var body: some View {
        VStack {
            ResultsView(selectedCheck: currentCheck, selectedTab: $selectedTab, isSheet: isSheet) {
                onNext()
            }
        }
    }
}

struct AnimatedTextView: View {
    let fullText: String
    var animationDuration: Double = 0.8
    var lineDelay: Double = 0.4
    
    @State private var displayedLines: [String] = []
    @State private var lineStates: [Bool] = []
    
    private var lines: [String] {
        fullText
            .components(separatedBy: ". ")
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
    }
    
    var body: some View {
        VStack(alignment: .center, spacing: 20) {
            ForEach(lines.indices, id: \.self) { index in
                Text(lines[index] + (index < lines.count - 1 ? "." : ""))
                    .font(.system(.title, design: .rounded, weight: .semibold))
                    .multilineTextAlignment(.center)
                    .opacity(lineStates.indices.contains(index) && lineStates[index] ? 1 : 0)
                    .scaleEffect(lineStates.indices.contains(index) && lineStates[index] ? 1.0 : 0.8)
                    .offset(y: lineStates.indices.contains(index) && lineStates[index] ? 0 : 30)
                    .animation(.interactiveSpring(response: 0.6, dampingFraction: 0.65, blendDuration: 0.2).delay(Double(index) * lineDelay), value: lineStates)
            }
        }
        .onAppear {
            lineStates = Array(repeating: false, count: lines.count)
            for i in lines.indices {
                DispatchQueue.main.asyncAfter(deadline: .now() + Double(i) * lineDelay) {
                    lineStates[i] = true
                }
            }
        }
    }
}
