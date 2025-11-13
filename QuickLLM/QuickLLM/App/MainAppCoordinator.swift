import Combine
import Foundation

@MainActor
final class MainAppCoordinator: ObservableObject {
    let hotkeys = HotkeyManager()
    let textCapture = TextCaptureService()
    let llm = LLMService()
    let paste = PasteService()
    let files = FileOutputService()
    let settings = SettingsStore()
    private weak var boundAppState: AppState?

    func bindHotkeys(appState: AppState) {
        guard boundAppState !== appState else { return }
        boundAppState = appState

        hotkeys.registerGrammarFixHotkey { [weak self, weak appState] in
            Task { [weak self, weak appState] in
                guard let self, let appState else { return }
                await MainActor.run {
                    self.handleGrammarFixTrigger(appState: appState)
                }
            }
        }
    }

    func handleGrammarFixTrigger(appState: AppState) {
        do {
            let selectedText = try textCapture.captureSelectedText().trimmed
#if DEBUG
            print("QuickLLM Debug — captured text:\n---\n\(selectedText)\n---")
#endif
            guard !selectedText.isEmpty else {
                appState.lastErrorMessage = describeGrammarError(TextCaptureError.nothingSelected)
                return
            }

            appState.lastErrorMessage = nil
            let apiKey = settings.apiKey

            Task { [weak self, weak appState] in
                guard let self, let appState else { return }
                do {
                    let fixed = try await llm.runGrammarTask(input: selectedText, apiKey: apiKey)
#if DEBUG
                    print("QuickLLM Debug — LLM response:\n---\n\(fixed)\n---")
#endif
                    await MainActor.run {
                        appState.pendingLLMOutput = fixed
                        appState.lastErrorMessage = nil

                        if self.settings.autoPasteEnabled {
                            self.paste.paste(fixed)
                            appState.showConfirmationModal = false
                        } else {
                            appState.showConfirmationModal = true
                        }
                    }
                } catch {
                    await MainActor.run {
                        appState.pendingLLMOutput = ""
                        appState.showConfirmationModal = false
                        appState.lastErrorMessage = self.describeGrammarError(error)
                    }
                    #if DEBUG
                    print("Grammar fix failed:", error)
                    #endif
                }
            }
        } catch {
            appState.lastErrorMessage = describeGrammarError(error)
        }
    }

    func handleResumeTuneTrigger() {
        // pipeline placeholder
    }

    private func describeGrammarError(_ error: Error) -> String {
        if let captureError = error as? TextCaptureError {
            switch captureError {
            case .accessibilityPermissionMissing:
                return "Grant Accessibility permissions to QuickLLM in System Settings → Privacy & Security to capture selected text."
            case .focusedElementUnavailable:
                return "Could not find the focused control. Click inside the text field and try again."
            case .nothingSelected:
                return "No text was captured to correct. Highlight some text and try again."
            }
        }

        if let serviceError = error as? LLMServiceError {
            switch serviceError {
            case .missingAPIKey:
                return "Add an OpenAI API key in Settings before running the grammar fixer."
            case .emptyInput:
                return "No text was captured to correct. Highlight some text and try again."
            case .emptyResponse, .missingFixedGrammarTag:
                return "The language model returned an unexpected response. Please try again."
            case .libraryUnavailable:
                return "OpenAI SDK is not available. Add the MacPaw OpenAI package to the project."
            }
        }

        return error.localizedDescription
    }
}
