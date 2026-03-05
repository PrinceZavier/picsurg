//
//  PicSurgApp.swift
//  PicSurg
//
//  Created by Isabella Zorra on 1/2/26.
//

import SwiftUI

@main
struct PicSurgApp: App {
    @StateObject private var appState = AppState.shared
    @StateObject private var authService = AuthService.shared

    init() {
        AnalyticsService.shared.initialize()
        AnalyticsService.shared.checkForCrash()
    }

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(appState)
                .environmentObject(authService)
                .detectInactivity(authService: authService)
                .onReceive(NotificationCenter.default.publisher(for: UIApplication.willResignActiveNotification)) { _ in
                    AnalyticsService.shared.markCleanExit()
                    if authService.isAuthenticated {
                        authService.recordBackgroundTimestamp()
                        authService.stopInactivityTimer()
                    }
                }
                .onReceive(NotificationCenter.default.publisher(for: UIApplication.didBecomeActiveNotification)) { _ in
                    authService.checkGracePeriodOnForeground()
                    if authService.isAuthenticated {
                        authService.resetInactivityTimer()
                    }
                    AnalyticsService.shared.trackAppOpened()
                }
        }
    }
}
