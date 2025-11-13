import SwiftUI

struct ConfirmationView: View {
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var coordinator: MainAppCoordinator

    var body: some View {
        VStack {
            TextEditor(text: $appState.pendingLLMOutput)
                .frame(minHeight: 200)

            HStack {
                Button("Paste") {
                    coordinator.paste.paste(appState.pendingLLMOutput)
                    appState.showConfirmationModal = false
                }
                Button("Save") {
                    if let dir = coordinator.settings.saveDirectory {
                        coordinator.files.saveResume(content: appState.pendingLLMOutput, to: dir)
                    }
                    appState.showConfirmationModal = false
                }
                Button("Close") {
                    appState.showConfirmationModal = false
                }
            }
        }
        .padding()
    }
}
