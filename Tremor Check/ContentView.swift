import SwiftUI
import CoreML
import Dispatch
import SwiftData
import Speech
import TipKit

struct ContentView: View {
    var startRecordingTip = StartRecordingTip()
    var analyzeRecordingTip = AnalyzeRecordingTip()
    @StateObject private var audioRecorder = AudioRecorder()

    var currentCheck: TremorCheck
    @State private var showingSheet: Bool = false
    @State var showingStats: Bool = false
    @AppStorage("isNew") private var isNew: Bool = true
    @Environment(\.modelContext) var modelContext
    
    let columns = [
        GridItem(.adaptive(minimum: 80))
    ]
    
    @State private var animateImage = false
    @State private var animateProgress = false
    @State private var animateStatus = false
    @State private var animateRecordButton = false
    @State private var animateResults = false
    @State private var animateAnalyzeButton = false
    @State private var words: [Word] = []
    @State private var lastRecognizedText: String = ""
    @State private var showPopover = false
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 30) {
                    
                    HStack() {
                        ForEach(words) { word in
                            WordView(word: word)
                        }
                    }
                    .scaleEffect(animateImage ? 1 : 0.8)
                    .offset(y: animateImage ? 0 : 30)
                    .opacity(animateImage ? 1 : 0)
                    .animation(.spring(response: 0.7, dampingFraction: 0.7).delay(0.3), value: animateImage)
                    
                    if currentCheck.voiceAssessment.phrases.count > 0 {
                        VStack(spacing: 10) {
                            ProgressView(value: currentCheck.voiceAssessment.progress)
                                .padding(.horizontal, 40)
                                .opacity(animateProgress ? 1 : 0)
                                .scaleEffect(animateProgress ? 1 : 0.8)
                                .offset(y: animateProgress ? 0 : 20)
                                .animation(.spring(response: 0.7, dampingFraction: 0.7).delay(0.6), value: animateProgress)
                            
                            Text("Phrase \(min(currentCheck.voiceAssessment.currentPhraseIndex + 1, currentCheck.voiceAssessment.phrases.count)) of \(currentCheck.voiceAssessment.phrases.count)")
                                .font(.headline)
                                .foregroundColor(.gray)
                                .opacity(animateProgress ? 1 : 0)
                                .scaleEffect(animateProgress ? 1 : 0.8)
                                .offset(y: animateProgress ? 0 : 20)
                                .animation(.spring(response: 0.7, dampingFraction: 0.7).delay(0.7), value: animateProgress)
                        }
                    }
                    
                    if !currentCheck.voiceAssessment.isAllPhrasesRecorded {
                        VStack(spacing: 20) {
                            if audioRecorder.isRecording {
                                StatusCard(
                                    title: "Recording...",
                                    message: "Please say:\n\"\(currentCheck.voiceAssessment.currentPhrase)\"",
                                    color: .blue
                                )
                            } else {
                                StatusCard(
                                    title: "Instructions",
                                    message: "When ready, press start and say:\n\"\(currentCheck.voiceAssessment.currentPhrase)\"",
                                    color: .gray
                                )
                            }
                            
                            if currentCheck.voiceAssessment.results.count <= 4 {
                                Button(action: {
                                    withAnimation(.easeInOut(duration: 0.3)) {
                                        audioRecorder.isRecording ? audioRecorder.stopRecording() :
                                        audioRecorder.startRecording()
                                        if !audioRecorder.isRecording {
                                            withAnimation(.easeInOut(duration: 0.3)) {
                                                if let audioURL = audioRecorder.audioFileURL {
                                                    analyzeRecording(audioURL: audioURL)
                                                }
                                                words = []
                                            }
                                        }
                                    }
                                }) {
                                    Text(audioRecorder.isRecording ? "Continue" : "Start")
                                        .font(.title3)
                                        .padding(.horizontal, 40)
                                        .padding(.vertical, 20)
                                        .background(audioRecorder.isRecording ? Color.red : Color.blue)
                                        .foregroundColor(.white)
                                        .cornerRadius(20)
                                        .shadow(color: (audioRecorder.isRecording ? Color.red : Color.blue).opacity(0.4), radius: 10, x: 0, y: 5)
                                }
                                .scaleEffect(animateRecordButton ? 1 : 0.8)
                                .offset(y: animateRecordButton ? 0 : 30)
                                .opacity(animateRecordButton ? 1 : 0)
                                .animation(.spring(response: 0.7, dampingFraction: 0.7).delay(1.0), value: animateRecordButton)
                                .animation(.easeInOut(duration: 0.3), value: audioRecorder.isRecording)
                            }
                            
                        }
                        .padding(.horizontal, 40)
                        .scaleEffect(animateStatus ? 1 : 0.95)
                        .offset(y: animateStatus ? 0 : 30)
                        .opacity(animateStatus ? 1 : 0)
                        .animation(.spring(response: 0.7, dampingFraction: 0.7).delay(0.9), value: animateStatus)
                    }
                    
                    if !currentCheck.voiceAssessment.results.isEmpty {
                        VStack(alignment: .leading, spacing: 15) {
                            Text("Recorded Phrases")
                                .font(.title2)
                                .bold()
                                .padding(.horizontal, 40)
                            
                            VStack(spacing: 20) {
                                HStack(spacing: 20) {
                                    ForEach(0..<min(2, currentCheck.voiceAssessment.results.count), id: \.self) { index in
                                        PhraseResultCard(result: currentCheck.voiceAssessment.results[index], index: index)
                                    }
                                }
                                
                                if currentCheck.voiceAssessment.results.count > 2 {
                                    HStack(spacing: 20) {
                                        ForEach(2..<currentCheck.voiceAssessment.results.count, id: \.self) { index in
                                            PhraseResultCard(result: currentCheck.voiceAssessment.results[index], index: index)
                                        }
                                        
                                        if currentCheck.voiceAssessment.results.count == 3 {
                                            Color.clear
                                                .frame(width: 300)
                                        }
                                    }
                                }
                            }
                            .padding(.horizontal, 40)
                            .scaleEffect(animateResults ? 1 : 0.95)
                            .offset(y: animateResults ? 0 : 30)
                            .opacity(animateResults ? 1 : 0)
                            .animation(.spring(response: 0.7, dampingFraction: 0.7).delay(1.2), value: animateResults)
                        }
                    }
                }
                .padding(.vertical, 20)
            }
            .fullScreenCover(isPresented: $showingSheet) {
                WelcomeView()
            }
            //Run animations
            .onAppear {
                if isNew {
                    showingSheet.toggle()
                }
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    animateImage = true
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                    animateProgress = true
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    animateStatus = true
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
                    animateRecordButton = true
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.1) {
                    animateResults = true
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.3) {
                    animateAnalyzeButton = true
                }
            }
            .navigationTitle("Tremor Check")
        }
        .onChange(of: audioRecorder.recognizedText) { oldValue, newValue in
            let previousWords = lastRecognizedText.components(separatedBy: " ")
            let currentWords = newValue.components(separatedBy: " ")
            
            if currentWords.count > previousWords.count {
                let newWords = currentWords.dropFirst(previousWords.count)
                withAnimation(.easeOut(duration: 0.5)) {
                    words.append(contentsOf: newWords.map { Word(text: $0) })
                }
            }
            
            lastRecognizedText = newValue
        }
    }
    
    //Determines a potential tremor using the Jitter and Shimmer values.
    func generatePrediction(jitter: Double, shimmer: Double) -> String {
        if jitter > 20.0 || shimmer > 25.0 {
            return String(format: "Potential tremor detected (Average Jitter: %.2f%%, Average Shimmer: %.2f%%)", jitter, shimmer)
        } else {
            return String(format: "No significant tremor (Average Jitter: %.2f%%, Average Shimmer: %.2f%%)", jitter, shimmer)
        }
    }
    
    //Run the audio feature extraction function and updates the voice assessment and the current check.
    func analyzeRecording(audioURL: URL) {
        
        print("Analyzing recording for phrase \(currentCheck.voiceAssessment.currentPhraseIndex + 1)")
        
        DispatchQueue.global(qos: .userInitiated).async {
            let features = extractAudioFeatures(from: audioURL)
            
            DispatchQueue.main.async {
                // Modify the voiceAssessment
                currentCheck.addVoiceResult(features: features!, audioURL: audioURL)
                if currentCheck.voiceAssessment.currentPhraseIndex == 2 {
                    currentCheck.voiceAssessment.averageJitter = currentCheck.voiceAssessment.results.map{ $0.jitter }.reduce(0, +) / Double(currentCheck.voiceAssessment.results.count)
                    currentCheck.voiceAssessment.averageShimmer = currentCheck.voiceAssessment.results.map{ $0.shimmer }.reduce(0, +) / Double(currentCheck.voiceAssessment.results.count)
                }
            }
        }
    }
}

struct StatusCard: View {
    let title: String
    let message: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 10) {
            Text(title)
                .font(.headline)
            Text(message)
                .multilineTextAlignment(.center)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 15)
                .fill(color.opacity(0.1))
        )
        .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
    }
}

struct PhraseResultCard: View {
    let result: PhraseResult
    let index: Int
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.green)
                    .imageScale(.large)
                Text("Phrase \(index + 1)")
                    .font(.headline)
            }
            
            Text(result.phrase)
                .font(.subheadline)
                .foregroundColor(.gray)
            
            Divider()
            
            Text(String(format: "Jitter: %.1f%%", result.jitter))
            Text(String(format: "Shimmer: %.1f%%", result.shimmer))
                .foregroundColor(.gray)
        }
        .padding()
        .frame(width: 300)
        .background(Color.gray.opacity(0.1))
        .cornerRadius(15)
        .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
        .transition(.asymmetric(
            insertion: .opacity.combined(with: .offset(x: 0, y: 50)),
            removal: .opacity
        ))
    }
}

///Used to animate words in. The data for each word comes from the AudioRecorder model.
///
struct Word: Identifiable, Equatable {
    let id = UUID()
    let text: String
}
