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
                    Label("Vault", systemImage: "lock.square.stack.fill")
                }
                .tag(AppState.Tab.vault)

            // Camera placeholder - will show coming soon alert
            CameraPlaceholderView()
                .tabItem {
                    Label("Camera", systemImage: "camera.fill")
                }
                .tag(AppState.Tab.camera)
        }
    }
}

/// Placeholder view for future in-app camera feature
struct CameraPlaceholderView: View {
    @State private var showingAlert = false

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                Spacer()

                Image(systemName: "camera.fill")
                    .font(.system(size: 80))
                    .foregroundColor(Theme.Colors.primary.opacity(0.5))

                Text("Coming Soon")
                    .font(.title)
                    .fontWeight(.bold)

                Text("Take photos directly in PicSurg\nfor automatic secure storage")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)

                Spacer()
            }
            .padding()
            .navigationTitle("Camera")
        }
    }
}

#Preview {
    MainTabView()
        .environmentObject(AppState.shared)
}
