import SwiftUI
import SwiftData

struct FingerStabilityTestView: View {
    @State private var isHolding = false
    @State private var timerActive = false
    @State private var elapsedTime: Double = 0
    @State private var positions: [CGPoint] = []
    @State private var startPoint: CGPoint? = nil
    @State private var score: Double?
    @State private var testCompleted = false
    @Environment(\.modelContext) var modelContext
    @AppStorage("shakeScore") var shakeScore: Double = 0.0
    
    @State private var animateInstructions = false
    @State private var animateCircle = false
    @State private var animateStatusText = false
    @State private var showingErrorMessage = false
    var currentCheck: TremorCheck
    var onTestComplete: () -> Void
    var body: some View {
        VStack {
            Spacer()
            
            if showingErrorMessage {
                if !testCompleted {
                    Text("There was an error please retake the test")
                        .font(.headline)
                        .multilineTextAlignment(.center)
                }
            }
            
            Text("Keep your finger still inside the circle for 15 seconds")
                .font(.headline)
                .multilineTextAlignment(.center)
                .padding()
                .opacity(animateInstructions ? 1 : 0)
                .scaleEffect(animateInstructions ? 1 : 0.9)
                .offset(y: animateInstructions ? 0 : 20)
                .animation(.spring(response: 0.6, dampingFraction: 0.7).delay(0.3), value: animateInstructions)
            
            Group {
                if testCompleted  {
                    if score == nil {
                        Text("There was an issue with your test data please retry.")
                            .padding()
                            .bold()
                    }else {
                        if let score = score {
                            Text("Your score: \(String(format: "%.1f", score))/100")
                                .font(.title)
                                .foregroundColor(.black)
                        } else {
                            Text("Your score was lower than expected. It is recommended that you contact your primary care physician.")
                        }
                    }
                } else if isHolding && !testCompleted {
                    Text("\(Int(totalDuration - elapsedTime))s")
                        .font(.title)
                        .foregroundColor(.black)
                } else {
                    Text("Place your finger to begin")
                        .font(.title)
                        .foregroundColor(.gray)
                }
            }
            .padding(.bottom, 20)
            .opacity(animateStatusText ? 1 : 0)
            .scaleEffect(animateStatusText ? 1 : 0.9)
            .offset(y: animateStatusText ? 0 : 20)
            .animation(.spring(response: 0.6, dampingFraction: 0.7).delay(0.6), value: animateStatusText)
            
            ZStack {
                if testCompleted {
                    Image(systemName: "checkmark.circle.fill")
                        .resizable()
                        .frame(width: 200, height: 200)
                        .foregroundStyle(.green)
                        .transition(.scale)
                        .shadow(color: .green, radius: 10)
                        .opacity(animateCircle ? 1 : 0)
                        .scaleEffect(animateCircle ? 1 : 0.8)
                        .animation(.spring(response: 0.6, dampingFraction: 0.7).delay(0.8), value: animateCircle)
                } else {
                    Circle()
                        .fill(Color.blue.opacity(0.2))
                        .frame(width: 200, height: 200)
                        .opacity(animateCircle ? 1 : 0)
                        .scaleEffect(animateCircle ? 1 : 0.8)
                        .offset(y: animateCircle ? 0 : 20)
                        .animation(.spring(response: 0.6, dampingFraction: 0.7).delay(0.9), value: animateCircle)
                }
            }
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { value in
                        if !isHolding && !testCompleted {
                            isHolding = true
                            startPoint = value.location
                            positions = [value.location]
                            startTimer()
                        } else if isHolding && !testCompleted {
                            positions.append(value.location)
                        }
                    }
                    .onEnded { _ in
                        if isHolding && !testCompleted {
                            stopTimer(wasCancelled: true)
                        }
                    }
            )
            
            Spacer()
            Spacer()
        }
        .onChange(of: isHolding, { oldValue, newValue in
            if newValue == false {
                if score == 0.0 {
                    resetTest()
                    showingErrorMessage = true
                }
            }
        })
        .onAppear {
            resetTest()
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                animateInstructions = true
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                animateStatusText = true
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                animateCircle = true
            }
        }
        .onChange(of: testCompleted) { _, newValue in
            if testCompleted  {
                if score == nil {
                    currentCheck.shakeAssessment = score
                } else {
                    if newValue {
                        currentCheck.shakeAssessment = score
                        onTestComplete()
                    }
                }
            }
            
        }
    }
    
    private let totalDuration: Double = 15.0
    private let updateInterval: Double = 0.05
    
    private func startTimer() {
        elapsedTime = 0
        timerActive = true
        
        Timer.scheduledTimer(withTimeInterval: updateInterval, repeats: true) { timer in
            guard self.timerActive else {
                timer.invalidate()
                return
            }
            
            self.elapsedTime += self.updateInterval
            if self.elapsedTime >= self.totalDuration {
                timer.invalidate()
                self.stopTimer(wasCancelled: false)
            }
        }
    }
    
    private func stopTimer(wasCancelled: Bool) {
        timerActive = false
        isHolding = false
        
        withAnimation {
            testCompleted = true
        }
        
        if wasCancelled {
            score = 0.0
        } else {
            computeScore()
        }
    }
    
    private func computeScore() {
        guard positions.count > 1, let _ = startPoint else {
            score = 100.0
            return
        }
        
        var totalDistance: CGFloat = 0.0
        for i in 1..<positions.count {
            let prev = positions[i-1]
            let current = positions[i]
            let dist = hypot(current.x - prev.x, current.y - prev.y)
            totalDistance += dist
        }
        
        let maxDistance: CGFloat = 300.0
        let rawScore = max(0, 100 - (totalDistance / maxDistance * 100))
        score = Double(rawScore)
    }
    
    private func resetTest() {
        isHolding = false
        timerActive = false
        elapsedTime = 0
        positions = []
        startPoint = nil
        score = nil
        testCompleted = false
    }
}
