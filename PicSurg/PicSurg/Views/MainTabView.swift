import SwiftUI

/// Main tab bar navigation
struct MainTabView: View {
    @EnvironmentObject var appState: AppState

    var body: some View {
        TabView(selection: $appState.selectedTab) {
            HomeView()
                .tabItem {
                    Label("Home", systemImage: "house.fill")
                }
                .tag(AppState.Tab.home)

            VaultView()
                .tabItem {
                    Label("Vault", systemImage: "lock.fill")
                }
                .tag(AppState.Tab.vault)

            SettingsView()
                .tabItem {
                    Label("Settings", systemImage: "gear")
                }
                .tag(AppState.Tab.settings)
        }
    }
}

#Preview {
    MainTabView()
        .environmentObject(AppState.shared)
}
