import AppKit
import ApplicationServices
import Foundation

enum TextCaptureError: Error {
    case accessibilityPermissionMissing
    case focusedElementUnavailable
    case nothingSelected
}

@MainActor
final class TextCaptureService {
    func captureSelectedText() throws -> String {
        guard AXIsProcessTrusted() else {
            throw TextCaptureError.accessibilityPermissionMissing
        }

        let systemWideElement = AXUIElementCreateSystemWide()
        guard let focusedElement = focusedElement(from: systemWideElement) else {
            throw TextCaptureError.focusedElementUnavailable
        }

        let kAXSelectedTextAttributedStringAttribute: CFString = "AXSelectedTextAttributedString" as CFString
        let kAXSelectedTextAttribute: CFString = "AXSelectedText" as CFString
        let kAXValueAttribute: CFString = "AXValue" as CFString

        if let attributed = copyAttribute(kAXSelectedTextAttributedStringAttribute, from: focusedElement) as? NSAttributedString {
            let result = attributed.string.trimmed
            if !result.isEmpty { return result }
        }

        if let selected = copyAttribute(kAXSelectedTextAttribute, from: focusedElement) as? String {
            let result = selected.trimmed
            if !result.isEmpty { return result }
        }

        if let value = copyAttribute(kAXValueAttribute, from: focusedElement) {
            if let string = value as? String {
                let result = string.trimmed
                if !result.isEmpty { return result }
            } else if let attributed = value as? NSAttributedString {
                let result = attributed.string.trimmed
                if !result.isEmpty { return result }
            }
        }

        throw TextCaptureError.nothingSelected
    }

    private func focusedElement(from systemWide: AXUIElement) -> AXUIElement? {
        var raw: AnyObject?
        let status = AXUIElementCopyAttributeValue(systemWide, kAXFocusedUIElementAttribute as CFString, &raw)
        guard status == .success, let raw else { return nil }
        guard CFGetTypeID(raw) == AXUIElementGetTypeID() else { return nil }
        // Bridge the CFType to AXUIElement without a conditional downcast that always succeeds
        return unsafeBitCast(raw, to: AXUIElement.self)
    }

    private func copyAttribute(_ attribute: CFString, from element: AXUIElement) -> AnyObject? {
        var raw: AnyObject?
        let status = AXUIElementCopyAttributeValue(element, attribute, &raw)
        guard status == .success else { return nil }
        return raw
    }
}
