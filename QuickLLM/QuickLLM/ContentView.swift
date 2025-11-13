//
//  ContentView.swift
//  QuickLLM
//
//  Created by MJ Moshiri on 11/12/25.
//

import SwiftUI

struct ContentView: View {
    var body: some View {
        SettingsView()
    }
}

#Preview {
    ContentView()
        .environmentObject(AppState())
        .environmentObject(MainAppCoordinator())
}
