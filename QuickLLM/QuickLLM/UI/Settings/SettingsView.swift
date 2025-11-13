import AppKit
import ApplicationServices
import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var coordinator: MainAppCoordinator
    @EnvironmentObject var appState: AppState
    @State private var apiKey: String = ""
    @State private var autoPasteEnabled = false

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("QuickLLM Settings")
                .font(.title2)
                .fontWeight(.semibold)

            VStack(alignment: .leading, spacing: 8) {
                Text("OpenAI API Key")
                    .font(.caption)
                    .foregroundColor(.secondary)

                SecureField("sk-...", text: $apiKey)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .onSubmit(storeAPISettings)
            }

            Toggle("Auto paste corrected text", isOn: $autoPasteEnabled)
                .onChange(of: autoPasteEnabled) { _ in
                    coordinator.settings.autoPasteEnabled = autoPasteEnabled
                }

            Button("Fix Grammar for Selection") {
                storeAPISettings()
                coordinator.handleGrammarFixTrigger(appState: appState)
            }
            .buttonStyle(.borderedProminent)

            if let error = appState.lastErrorMessage {
                Text(error)
                    .font(.footnote)
                    .foregroundColor(.red)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer()
        }
        .padding(24)
        .frame(width: 420, height: 320, alignment: .topLeading)
        .onAppear {
            apiKey = coordinator.settings.apiKey
            autoPasteEnabled = coordinator.settings.autoPasteEnabled
            checkAccessibilityPermissionStatus()
            coordinator.bindHotkeys(appState: appState)
        }
        .sheet(isPresented: $appState.showConfirmationModal) {
            ConfirmationView()
                .environmentObject(appState)
                .environmentObject(coordinator)
        }
        .alert("Enable Accessibility Permissions", isPresented: $appState.showAccessibilityPrompt) {
            Button("Open Settings") {
                openAccessibilityPreferences()
            }
            Button("Not Now", role: .cancel) {}
        } message: {
            Text("QuickLLM needs Accessibility access to read selected text. Grant permission in System Settings → Privacy & Security → Accessibility.")
        }
    }

    private func storeAPISettings() {
        coordinator.settings.apiKey = apiKey.trimmed
    }

    private func checkAccessibilityPermissionStatus() {
        if AXIsProcessTrusted() {
            return
        }

        // Trigger the system Accessibility permission prompt so the app shows up in the list.
        let options: CFDictionary = [
            kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true
        ] as CFDictionary
        let trusted = AXIsProcessTrustedWithOptions(options)

        // Show in-app guidance if the user dismissed the system prompt.
        appState.showAccessibilityPrompt = !trusted
    }

    private func openAccessibilityPreferences() {
        if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility") {
            NSWorkspace.shared.open(url)
        }
    }
}
