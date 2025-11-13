import Combine
import Foundation

final class AppState: ObservableObject {
    @Published var showConfirmationModal = false
    @Published var pendingLLMOutput: String = ""
    @Published var lastErrorMessage: String?
    @Published var showAccessibilityPrompt = false
}
