import AppKit
import Carbon.HIToolbox
import Foundation

@MainActor
final class PasteService {
    func paste(_ text: String) {
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(text, forType: .string)

        guard let eventSource = CGEventSource(stateID: .hidSystemState) else {
            return
        }

        let keyDown = CGEvent(keyboardEventSource: eventSource, virtualKey: CGKeyCode(kVK_ANSI_V), keyDown: true)
        keyDown?.flags.insert(.maskCommand)

        let keyUp = CGEvent(keyboardEventSource: eventSource, virtualKey: CGKeyCode(kVK_ANSI_V), keyDown: false)
        keyUp?.flags.insert(.maskCommand)

        keyDown?.post(tap: .cghidEventTap)
        keyUp?.post(tap: .cghidEventTap)
    }
}
