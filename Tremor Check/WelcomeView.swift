import SwiftUI

struct WelcomeView: View {
    @AppStorage("isNew") private var isNew = true
    
    @State private var currentTitle: String = "Welcome to Tremor Check"
    @State private var currentImage: String = "Tremor Check Icon"
    @State private var currentDescription: String = "Tremor Check starts the conversation about the effects of Parkinson's, and the importance of symptom tracking."
    @State private var pageIndex: Int = 0
    
    @Environment(\.dismiss) var dismiss
    
    @State private var animateContent = false
    
    private let totalPages = 4
    
    var body: some View {
        ZStack {
            LinearGradient(
                gradient: Gradient(colors: [Color.purple.opacity(0.6), Color.blue.opacity(0.6)]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            VStack(spacing: 30) {
                Spacer()
                
                Image(currentImage)
                    .resizable()
                    .cornerRadius(15)
                    .scaledToFit()
                    .frame(maxWidth: 300, maxHeight: 300)
                    .shadow(radius: 10)
                    .opacity(animateContent ? 1 : 0)
                    .scaleEffect(animateContent ? 1 : 0.8)
                    .animation(.easeOut(duration: 0.6), value: animateContent)
                
                Text(currentTitle)
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .multilineTextAlignment(.center)
                    .foregroundColor(.white)
                    .padding(.horizontal, 40)
                    .opacity(animateContent ? 1 : 0)
                    .scaleEffect(animateContent ? 1 : 0.9)
                    .animation(.easeOut(duration: 0.6).delay(0.2), value: animateContent)
                
                Text(currentDescription)
                    .font(.title2)
                    .multilineTextAlignment(.center)
                    .foregroundColor(.white.opacity(0.9))
                    .padding(.horizontal, 40)
                    .opacity(animateContent ? 1 : 0)
                    .scaleEffect(animateContent ? 1 : 0.9)
                    .animation(.easeOut(duration: 0.6).delay(0.4), value: animateContent)
                
                Spacer()
                
                HStack {
                    
                    Button(action: {
                        withAnimation {
                            if pageIndex > 0 {
                                pageIndex -= 1
                            }
                        }
                    }) {
                        Image(systemName: "arrow.left.circle.fill")
                            .resizable()
                            .frame(width: 40, height: 40)
                            .foregroundColor(pageIndex > 0 ? .white : .gray.opacity(0.5))
                    }
                    .disabled(pageIndex == 0)
                    
                    Spacer()
                    
                    if pageIndex < totalPages - 1 {
                        Button(action: {
                            withAnimation {
                                if pageIndex < totalPages - 1 {
                                    pageIndex += 1
                                }
                            }
                        }) {
                            Image(systemName: "arrow.right.circle.fill")
                                .resizable()
                                .frame(width: 40, height: 40)
                                .foregroundColor(.white)
                        }
                    } else {
                        Button(action: {
                            isNew = false
                            withAnimation {
                                dismiss()
                            }
                        }) {
                            Text("Get Started")
                                .font(.title2.bold())
                                .foregroundColor(.white)
                                .padding()
                                .frame(maxWidth: .infinity)
                                .background(Color.blue.opacity(0.7))
                                .cornerRadius(15)
                                .padding(.horizontal, 40)
                        }
                        .transition(.opacity)
                    }
                }
                .padding(.horizontal, 60)
                .padding(.bottom, 20)
                
                HStack(spacing: 12) {
                    ForEach(0..<totalPages, id: \.self) { index in
                        Circle()
                            .fill(index == pageIndex ? Color.white : Color.white.opacity(0.5))
                            .frame(width: 12, height: 12)
                            .scaleEffect(index == pageIndex ? 1.2 : 1.0)
                            .animation(.spring(response: 0.4, dampingFraction: 0.6), value: pageIndex)
                    }
                }
                .padding(.bottom, 40)
            }
            .padding()
        }
        .onAppear {
            withAnimation {
                animateContent = true
            }
        }
        .onChange(of: pageIndex) { newValue, oldValue in
            updateContent(for: pageIndex)
        }
    }
    
    private func updateContent(for index: Int) {
        withAnimation(.easeInOut(duration: 0.5)) {
            switch index {
            case 0:
                currentTitle = "Welcome to Tremor Check"
                currentImage = "Tremor Check Icon"
                currentDescription = "Tremor Check is an experience designed to help inform the general public about the effects of Parkinson's and the importance of symptom tracking"
            case 1:
                currentTitle = "Over 10,000,000 live with Parkinson's"
                currentImage = "Large Crowd Picture"
                currentDescription = "Over 10 million people have Parkinson's today and tracking symptoms can be difficult, costly and time consuming."
            case 2:
                currentTitle = "Modern Intelligence"
                currentImage = "Swift Programming Lang"
                currentDescription = "Tremor Check uses on-device intelligence to accurately track the symptoms of Parkinson's, powered by Swift and Apple Silicon. \n\nYour data remains private and never leaves your device."
            case 3:
                currentTitle = "Getting Started"
                currentImage = "waveform"
                currentDescription = "Repeat a few verbal phrases, and take a finger stability test once a day to track and observe your symptoms."
            default:
                currentTitle = "Welcome to Tremor Check"
                currentImage = "Tremor Check Icon"
                currentDescription = "Tremor Check starts the conversation about the effects of Parkinson's, and the importance of symptom tracking."
            }
        }
    }
}
