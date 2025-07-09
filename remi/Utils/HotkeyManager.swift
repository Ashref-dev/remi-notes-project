import Foundation
import HotKey

class HotkeyManager {
    static let shared = HotkeyManager()
    private var hotKey: HotKey?

    private init() {}

    func register(hotkey: HotKey, callback: @escaping () -> Void) {
        self.hotKey = hotkey
        self.hotKey?.keyDownHandler = callback
    }

    func unregisterAllHotKeys() {
        hotKey = nil
    }

    func registerDefaultHotkey(callback: @escaping () -> Void) {
        let defaultHotkey = HotKey(key: .r, modifiers: [.command, .option])
        register(hotkey: defaultHotkey, callback: callback)
    }
}
