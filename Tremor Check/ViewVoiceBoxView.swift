import SwiftUI

struct ViewVoiceBoxView: View {
    var latestCheck: [TremorCheck]
    var body: some View {
        ZStack {
            LinearGradient(
                gradient: Gradient(colors: [Color.purple.opacity(0.6), Color.blue.opacity(0.6)]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            VStack {
                
                Spacer()
                
                Text("View Your Voice Box (Beta)")
                    .bold()
                    .padding()
                    .multilineTextAlignment(.center)
                    .font(.largeTitle)
                
                Image("Larynx Diagram")
                    .resizable()
                    .cornerRadius(15)
                    .scaledToFit()
                    .frame(maxWidth: 300, maxHeight: 300)
                    .shadow(radius: 10)
                
                Text("By using the data recorded in your tests we are able to get an *accurate 3D representation of your voice box. This allows medical professionals to better understand how Parkinson's is affecting your vocal muscles. This feature isn't 100% complete and currently is not very accurate.")
                    .bold()
                    .padding()
                    .multilineTextAlignment(.center)
                    .font(.title2)
                
                Spacer()
                
                NavigationLink {
                    VoiceBoxARContainer(latestCheck: latestCheck.first)
                } label: {
                    Text("Get Started")
                        .font(.title2.bold())
                        .foregroundColor(.white)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.blue.opacity(0.7))
                        .cornerRadius(15)
                        .padding(.horizontal, 40)
                }
                .padding(.bottom)
            }
        }
    }
}
