import SwiftUI

struct WordView: View {
    let word: Word
    @State private var offsetY: CGFloat = 20
    @State private var opacity: Double = 0
    @State private var rotation: Double = -10
    @State private var scale: CGFloat = 0.8
    
    var body: some View {
        Text(word.text)
            .font(.title2)
            .fontWeight(.bold)
            .multilineTextAlignment(.center)
            .padding(.vertical, 5)
            .offset(y: offsetY)
            .opacity(opacity)
            .rotationEffect(.degrees(rotation))
            .scaleEffect(scale)
            .onAppear {
                withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                    offsetY = 0
                    opacity = 1
                    rotation = 0
                    scale = 1.0
                }
            }
    }
}
