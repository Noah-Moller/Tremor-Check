import SwiftUI

struct TabsView: View {
    @StateObject private var assessment = VoiceAssessment()
    @State private var selectedTab = 0
    @State private var showingSheet = false
    @AppStorage("isNew") private var isNew: Bool = true
    var body: some View {
        TabView(selection: $selectedTab) {
            TestView(selectedTab: $selectedTab)
                .tabItem {
                    Label("Check", systemImage: "hand.draw")
                }
                .tag(0)
            
            AudioAnalyticsView(selectedTab: $selectedTab)
                .tabItem {
                    Label("Analytics", systemImage: "chart.bar")
                }
                .tag(1)
            
            ArticlesView()
                .tabItem {
                    Label("Learn", systemImage: "book")
                }
                .tag(2)
        }
        .onAppear() {
            if isNew {
                showingSheet = true
            }
        }
        .fullScreenCover(isPresented: $showingSheet) {
            WelcomeView()
        }
        .onChange(of: selectedTab) { oldValue, newValue in
            if newValue == 0 && oldValue != 0 {
                assessment.reset()
            }
        }
    }
}

#Preview {
    TabsView()
}
