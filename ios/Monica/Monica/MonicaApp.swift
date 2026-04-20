import SwiftUI

@main
struct MonicaApp: App {
    @State private var appState = AppState()

    var body: some Scene {
        WindowGroup {
            if appState.isConfigured {
                VaultListView()
                    .environment(appState)
            } else {
                OnboardingView()
                    .environment(appState)
            }
        }
    }
}
