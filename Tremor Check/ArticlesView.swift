import SwiftUI
import PDFKit
import TipKit

//MARK: - ArticlesView
///Displays Articles used in the research and creation of the app

struct ArticlesView: View {
    var articleTip = ArticleTip()
    
    let documentURL = Bundle.main.url(forResource: "Audio Feature Analysis", withExtension: "pdf")!
    
    @State private var isPresented: Bool = false
    @State private var animateFirstCard = false
    @State private var animateSecondCard = false
    @State private var animateThirdCard = false
    
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
                    VStack(spacing: 20) {
                        //Card that displays source and its content.
                        SourceCardView(
                            imageName: "Tremor Check Icon",
                            title: "Audio analysis in Tremor Check",
                            description: "This documentation explains my thinking behind the creation of the audio analysis algorithm"
                        )
                        .popoverTip(articleTip)
                        .onTapGesture {
                            isPresented = true
                        }
                        .opacity(animateFirstCard ? 1 : 0)
                        .scaleEffect(animateFirstCard ? 1 : 0.95)
                        .offset(y: animateFirstCard ? 0 : 20)
                        .animation(.spring(response: 0.7, dampingFraction: 0.7).delay(0.3), value: animateFirstCard)
                        
                        Link(destination: URL(string: "https://pmc.ncbi.nlm.nih.gov/articles/PMC8564663/")!) {
                            SourceCardView(
                                imageName: "Pub med logo",
                                title: "Detecting Parkinson's using audio analysis",
                                description: "This article explains how using complex mathematics in audio analysis can be used to detect early signs of Parkinson's."
                            )
                        }
                        .opacity(animateSecondCard ? 1 : 0)
                        .scaleEffect(animateSecondCard ? 1 : 0.95)
                        .offset(y: animateSecondCard ? 0 : 20)
                        .animation(.spring(response: 0.7, dampingFraction: 0.7).delay(0.6), value: animateSecondCard)
                        
                        Link(destination: URL(string: "https://speechprocessingbook.aalto.fi/Representations/Jitter_and_shimmer.html")!) {
                            SourceCardView(
                                imageName: "Function Symbol",
                                title: "Jitter and shimmer",
                                description: "This section of a book focuses on the equations in audio analysis for detecting jitter and shimmer."
                            )
                            .padding(.bottom, 20)
                        }
                        .opacity(animateThirdCard ? 1 : 0)
                        .scaleEffect(animateThirdCard ? 1 : 0.95)
                        .offset(y: animateThirdCard ? 0 : 20)
                        .animation(.spring(response: 0.7, dampingFraction: 0.7).delay(0.9), value: animateThirdCard)
                    }
                    .padding(.vertical)
                }
            }
            .navigationTitle("Learn")
            .onAppear {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    animateFirstCard = true
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
                    animateSecondCard = true
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.9) {
                    animateThirdCard = true
                }
            }
        }
        .sheet(isPresented: $isPresented) {
            PDFKitRepresentedView(documentURL)
                .frame(minWidth: 800, minHeight: 800)
        }
    }
}

struct SourceCardView: View {
    let imageName: String
    let title: String
    let description: String
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 12) {
                Text(title)
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundStyle(.black)
                
                Text(description)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .lineLimit(nil)
                    .multilineTextAlignment(.leading)
            }
            Spacer()
            Image(imageName)
                .resizable()
                .scaledToFill()
                .frame(width: 200, height: 200)
                .cornerRadius(15)
                .clipped()
        }
        .padding()
        .background(Color.gray.opacity(0.1))
        .cornerRadius(15)
        .padding(.horizontal)
        .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
    }
}

#Preview {
    ArticlesView()
}
