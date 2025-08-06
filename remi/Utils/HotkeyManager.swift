import Foundation
import AppKit
import HotKey

class HotkeyManager {
    static let shared = HotkeyManager()
    private var hotKey: HotKey?
    private var nookHotkeys: [HotKey] = []
    private var copyAllHotkey: HotKey?
    private var callback: (() -> Void)?
    private var nookCallbacks: [(Int) -> Void] = []
    private var copyAllCallback: (() -> Void)?

    private init() {}

    func register(hotkey: HotKey, callback: @escaping () -> Void) {
        self.callback = callback
        update(hotkey: hotkey)
    }
    
    func update(hotkey: HotKey) {
        self.hotKey = hotkey
        self.hotKey?.keyDownHandler = self.callback
    }
    
    // Register hotkeys for nooks (Cmd+Shift+1, Cmd+Shift+2, etc.)
    func registerNookHotkeys(callback: @escaping (Int) -> Void) {
        unregisterNookHotkeys()
        
        let nookKeys: [Key] = [.one, .two, .three, .four, .five, .six, .seven, .eight, .nine]
        let modifiers: NSEvent.ModifierFlags = [.command, .shift]
        
        for (index, key) in nookKeys.enumerated() {
            let hotkey = HotKey(key: key, modifiers: modifiers)
            hotkey.keyDownHandler = {
                callback(index)
            }
            nookHotkeys.append(hotkey)
        }
    }
    
    // Register custom nook hotkeys with user-defined modifiers
    func registerCustomNookHotkeys(modifiers: NSEvent.ModifierFlags, callback: @escaping (Int) -> Void) {
        unregisterNookHotkeys()
        
        let nookKeys: [Key] = [.one, .two, .three, .four, .five, .six, .seven, .eight, .nine]
        
        for (index, key) in nookKeys.enumerated() {
            let hotkey = HotKey(key: key, modifiers: modifiers)
            hotkey.keyDownHandler = {
                callback(index)
            }
            nookHotkeys.append(hotkey)
        }
    }
    
    // Register copy all hotkey (Cmd+Shift+C)
    func registerCopyAllHotkey(callback: @escaping () -> Void) {
        unregisterCopyAllHotkey()
        copyAllCallback = callback
        
        copyAllHotkey = HotKey(key: .c, modifiers: [.command, .shift])
        copyAllHotkey?.keyDownHandler = callback
    }
    
    func unregisterCopyAllHotkey() {
        copyAllHotkey = nil
        copyAllCallback = nil
    }
    
    func unregister() {
        hotKey = nil
        unregisterNookHotkeys()
        unregisterCopyAllHotkey()
    }
    
    func unregisterNookHotkeys() {
        nookHotkeys.removeAll()
    }
}
