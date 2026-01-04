import SwiftUI

/// Root view that handles navigation between onboarding, auth, and main app
struct RootView: View {
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var authService: AuthService

    var body: some View {
        ZStack {
            if !appState.isOnboardingComplete {
                OnboardingView()
                    .transition(.asymmetric(
                        insertion: .opacity,
                        removal: .opacity.combined(with: .scale(scale: 0.95))
                    ))
            } else if authService.isLocked {
                LockScreenView()
                    .transition(.asymmetric(
                        insertion: .opacity.combined(with: .scale(scale: 1.05)),
                        removal: .opacity.combined(with: .scale(scale: 0.95))
                    ))
            } else {
                MainTabView()
                    .transition(.asymmetric(
                        insertion: .opacity.combined(with: .scale(scale: 0.95)),
                        removal: .opacity
                    ))
            }
        }
        .animation(.spring(response: 0.4, dampingFraction: 0.8), value: appState.isOnboardingComplete)
        .animation(.spring(response: 0.4, dampingFraction: 0.8), value: authService.isLocked)
    }
}

#Preview {
    RootView()
        .environmentObject(AppState.shared)
        .environmentObject(AuthService.shared)
}
