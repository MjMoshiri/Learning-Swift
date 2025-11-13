import Carbon
import Foundation

private let grammarFixSignature: OSType = 0x514C4746 // 'QLGF'
private let grammarFixHotKeyID: UInt32 = 1

private func hotKeyEventHandler(callRef: EventHandlerCallRef?, eventRef: EventRef?, userData: UnsafeMutableRawPointer?) -> OSStatus {
    guard let userData else { return noErr }
    let manager = Unmanaged<HotkeyManager>.fromOpaque(userData).takeUnretainedValue()
    return manager.handleHotKeyEvent(eventRef)
}

final class HotkeyManager {
    private var grammarFixHotKey: EventHotKeyRef?
    private var eventHandler: EventHandlerRef?
    private var grammarFixHandler: (() -> Void)?

    func registerGrammarFixHotkey(_ handler: @escaping () -> Void) {
        unregisterHotkeys()
        grammarFixHandler = handler

        var eventSpec = EventTypeSpec(eventClass: OSType(kEventClassKeyboard), eventKind: UInt32(kEventHotKeyPressed))
        let installStatus = InstallEventHandler(
            GetEventDispatcherTarget(),
            hotKeyEventHandler,
            1,
            &eventSpec,
            Unmanaged.passUnretained(self).toOpaque(),
            &eventHandler
        )

        guard installStatus == noErr else {
            #if DEBUG
            print("Failed to install hotkey event handler:", installStatus)
            #endif
            eventHandler = nil
            grammarFixHandler = nil
            return
        }

        let hotKeyID = EventHotKeyID(signature: grammarFixSignature, id: grammarFixHotKeyID)
        let modifiers = UInt32(controlKey) | UInt32(optionKey) | UInt32(shiftKey)
        let registerStatus = RegisterEventHotKey(
            UInt32(kVK_ANSI_F),
            modifiers,
            hotKeyID,
            GetEventDispatcherTarget(),
            0,
            &grammarFixHotKey
        )

        if registerStatus != noErr {
            #if DEBUG
            print("Failed to register grammar fix hotkey:", registerStatus)
            #endif
            unregisterHotkeys()
        }
    }

    func unregisterHotkeys() {
        if let hotKey = grammarFixHotKey {
            UnregisterEventHotKey(hotKey)
            grammarFixHotKey = nil
        }

        if let handler = eventHandler {
            RemoveEventHandler(handler)
            eventHandler = nil
        }

        grammarFixHandler = nil
    }

    deinit {
        unregisterHotkeys()
    }

    fileprivate func handleHotKeyEvent(_ eventRef: EventRef?) -> OSStatus {
        guard let eventRef else { return noErr }

        var hotKeyID = EventHotKeyID()
        let status = GetEventParameter(
            eventRef,
            EventParamName(kEventParamDirectObject),
            EventParamType(typeEventHotKeyID),
            nil,
            MemoryLayout<EventHotKeyID>.size,
            nil,
            &hotKeyID
        )

        guard status == noErr else { return status }

        if hotKeyID.id == grammarFixHotKeyID {
            grammarFixHandler?()
        }

        return noErr
    }
}
