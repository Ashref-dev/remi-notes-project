# Remi v1.1.1 Release Notes

## 🐛 Critical Bug Fixes

### ⌨️ Keyboard Shortcuts Restored
- **Fixed Undo/Redo Shortcuts**: Restored ⌘Z (undo) and ⌘⇧Z (redo) functionality that was broken in v1.1.0
- **Fixed Copy Shortcut**: ⌘C now works correctly again for copying selected text
- **Fixed Copy All Shortcut**: ⌘⇧C continues to work for copying entire document content
- **Eliminated System Beeps**: No more annoying beeps when using standard keyboard shortcuts

### 🤖 AI Edit System Overhaul
- **Native Undo Integration**: AI text edits now properly integrate with macOS native undo system
- **Fixed Content Jumbling**: Resolved issue where undoing AI edits would append old content instead of replacing it
- **Single Atomic Operations**: AI replacements now register as single undoable actions for clean undo behavior
- **Crash Prevention**: AI edits no longer cause application crashes when using undo/redo

### 🔧 Technical Improvements
- **Enhanced Text Synchronization**: Improved synchronization between SwiftUI binding and NSTextView
- **Proper Undo Stack Management**: Fixed undo stack integrity to prevent duplicate or corrupted entries
- **Native macOS Compliance**: Better adherence to macOS text editing standards and behaviors

## 📋 What Was Fixed

In v1.1.0, users experienced:
- Keyboard shortcuts (⌘Z, ⌘⇧Z, ⌘C) producing system beeps instead of working
- AI edits causing content to become jumbled when undoing
- Application crashes when using undo after AI modifications
- Inconsistent text editing behavior

v1.1.1 completely resolves these issues by:
- Restoring default system command groups for standard shortcuts
- Implementing proper NSTextView-based undo registration for AI edits
- Using native macOS text replacement methods for seamless undo/redo

## 🔧 System Requirements

- macOS 14.5 or later
- Apple Silicon (M1/M2/M3) or Intel processors
- Active internet connection for AI features

## 📦 Installation

1. Download `Remi-v1.1.1-macOS.zip`
2. Extract the ZIP file
3. Move `remi.app` to your Applications folder
4. Launch Remi from Applications or find it in your menu bar

## 🎯 Coming Soon

- Nook drag & drop reordering
- Enhanced keyboard shortcuts and hotkeys
- Additional AI model providers
- Improved document organization features

---

**Full Changelog**: Compare v1.1.0...v1.1.1
**Download**: Remi-v1.1.1-macOS.zip

Made with ❤️ by [ashref.tn](https://ashref.tn)
