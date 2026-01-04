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

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(appState)
                .environmentObject(authService)
                .onReceive(NotificationCenter.default.publisher(for: UIApplication.willResignActiveNotification)) { _ in
                    // Lock app when going to background
                    authService.lock()
                }
        }
    }
}
