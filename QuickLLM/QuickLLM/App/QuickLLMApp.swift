//
//  QuickLLMApp.swift
//  QuickLLM
//
//  Created by MJ Moshiri on 11/12/25.
//

import SwiftUI

@main
struct QuickLLMApp: App {
    @StateObject private var appState = AppState()
    private let coordinator = MainAppCoordinator()

    var body: some Scene {
        WindowGroup {
            SettingsView()
                .environmentObject(appState)
                .environmentObject(coordinator)
        }
    }
}
