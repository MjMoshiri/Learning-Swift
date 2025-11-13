import Foundation

final class SettingsStore {
    private let defaults = UserDefaults.standard

    var apiKey: String {
        get { defaults.string(forKey: "apiKey") ?? "" }
        set { defaults.set(newValue, forKey: "apiKey") }
    }

    var autoPasteEnabled: Bool {
        get { defaults.bool(forKey: "autoPaste") }
        set { defaults.set(newValue, forKey: "autoPaste") }
    }

    var saveDirectory: URL? {
        get {
            guard let path = defaults.string(forKey: "saveDir") else { return nil }
            return URL(fileURLWithPath: path)
        }
        set {
            defaults.set(newValue?.path, forKey: "saveDir")
        }
    }
}
