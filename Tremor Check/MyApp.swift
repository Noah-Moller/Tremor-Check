import SwiftUI
import SwiftData
import TipKit

/*
 //MARK: - Note
 The audio analysis algorithm can be found in the ExtractAudioFeatures.swift file.
 */

@main
struct MyApp: App {
    let container: ModelContainer
    
    // Use an AppStorage flag to check if it's a new user.
    @AppStorage("isNewUser") private var isNewUser: Bool = true
    
    init() {
        do {
            container = try ModelContainer(for: TremorCheck.self)
        } catch {
            fatalError("Failed to initialize ModelContainer")
        }
    }
    
    var body: some Scene {
        WindowGroup {
            // Overlay the demo data loader on the TabsView.
            TabsView()
                .overlay(DemoDataLoader())
                .preferredColorScheme(.light)
        }
        .modelContainer(container)
    }
}
