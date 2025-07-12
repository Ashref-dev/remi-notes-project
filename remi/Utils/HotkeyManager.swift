import Foundation
import HotKey

class HotkeyManager {
    static let shared = HotkeyManager()
    private var hotKey: HotKey?
    private var callback: (() -> Void)?

    private init() {}

    func register(hotkey: HotKey, callback: @escaping () -> Void) {
        self.callback = callback
        update(hotkey: hotkey)
    }
    
    func update(hotkey: HotKey) {
        self.hotKey = hotkey
        self.hotKey?.keyDownHandler = self.callback
    }

    func unregister() {
        hotKey = nil
    }
}
