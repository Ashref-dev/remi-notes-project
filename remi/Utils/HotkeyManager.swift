import Foundation
import HotKey

class HotkeyManager {
    private var hotKey: HotKey?

    func register(callback: @escaping () -> Void) {
        hotKey = HotKey(key: .r, modifiers: [.command, .option])
        hotKey?.keyDownHandler = callback
    }

    func unregister() {
        hotKey = nil
    }
}
