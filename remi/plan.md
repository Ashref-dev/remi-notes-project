# Remi Enhancement Plan - Step-by-Step Implementation Guide

## Current Issues & Feature Requests
Implementation plan ordered by priority:

## 🛡️ **Phase 2: Fix Undo/Redo Crash with AI Processing** [HIGH PRIORITY]

### ✅ Current State Analysis
- Issue exists in `TaskEditorViewModel.processAIQuery()` and undo system
- Complex undo grouping in `LiveMarkdownEditor.swift` may conflict with AI operations
- Crash occurs when spamming Ctrl+Z after AI content generation

### 📋 Implementation Steps

#### **Step 2.1: Improve AI Processing Undo Safety**
- [x] Add undo stack validation before AI processing in `TaskEditorViewModel.swift`
- [x] Implement atomic AI operations that can't be interrupted by undo
- [x] Add debouncing to prevent rapid undo operations during AI processing

#### **Step 2.2: Fix Undo Manager Synchronization** 
- [x] Review and simplify undo grouping logic in `LiveMarkdownEditor.swift`
- [x] Ensure AI content changes register proper undo actions
- [x] Add safety checks in `registerAppLevelUndo()` method

#### **Step 2.3: Add Crash Prevention**
- [x] Implement try-catch blocks around all undo operations
- [x] Add undo manager state validation
- [x] Create fallback content recovery mechanism

#### **Step 2.4: Testing & Validation**
- [x] Add unit tests for undo/redo operations
- [x] Test AI processing with rapid undo operations
- [x] Validate memory management during complex operations

**✅ PHASE 2 COMPLETED** - AI features now work reliably with crash prevention

---

## ✅ **Phase 5: Copy All Button with Keyboard Shortcut** [COMPLETED]

### ✅ Current State Analysis
- Current editor is in `TaskEditorView.swift` with `LiveMarkdownEditor`
- ✅ Copy-all functionality implemented
- ✅ Compact, modern button design completed

### 📋 Implementation Steps

#### **Step 5.1: Add Copy All Functionality**
- [x] Create `copyAllContent()` method in `TaskEditorViewModel.swift`
- [x] Implement clipboard operations using `NSPasteboard`
- [x] Add success feedback (visual and haptic)

#### **Step 5.2: Design Compact Copy Button**
- [x] Add sleek copy button to top toolbar in `TaskEditorView.swift`
- [x] Use system clipboard icon with hover effects
- [x] Position near existing AI and settings buttons

#### **Step 5.3: Implement Keyboard Shortcut**
- [x] Add Cmd+Shift+C keyboard shortcut handling
- [x] Register shortcut in `HotkeyManager.swift`
- [x] Update keyboard shortcut hints in bottom bar

#### **Step 5.4: Enhanced Copy Features**
- [x] Add "Copy as Markdown" vs "Copy as Plain Text" options
- [x] Implement smart selection copying
- [x] Add copy history/clipboard manager integration

**✅ PHASE 5 COMPLETED** - Modern copy functionality with keyboard shortcut and elegant UI

---

## 🤖 **Phase 4: Configurable Groq Model Selection** [MEDIUM PRIORITY]

### ✅ Current State Analysis
- Model is hardcoded in `GroqService.swift` as "meta-llama/llama-4-scout-17b-16e-instruct"
- No UI for model selection in settings
- Need to add model configuration to `SettingsManager.swift`

### 📋 Implementation Steps

#### **Step 4.1: Add Model Configuration to Settings**
- [ ] Add `selectedGroqModel: String` property to `SettingsManager.swift`
- [ ] Create list of available Groq models with descriptions
- [ ] Add persistence for selected model preference

#### **Step 4.2: Update GroqService**
- [ ] Modify `GroqService.processQuery()` to use configurable model
- [ ] Replace hardcoded model string with settings value
- [ ] Add model validation and fallback logic

#### **Step 4.3: Add Model Selection UI**
- [ ] Create model picker in `IntegratedSettingsView.swift`
- [ ] Display model capabilities and descriptions
- [ ] Add model testing functionality

#### **Step 4.4: Enhanced Model Support**
- [ ] Add model-specific parameters (temperature, max tokens)
- [ ] Implement model performance indicators
- [ ] Add model switching without app restartlear

---

## �🖥️ **Phase 3: True Menu Bar Application (No Dock Icon)** [MEDIUM PRIORITY]

### ✅ Current State Analysis
- App currently uses `AppDelegate.swift` with status bar item
- Uses `@NSApplicationDelegateAdaptor` in `remiApp.swift`
- Need to remove dock icon while keeping menu bar functionality

### 📋 Implementation Steps

#### **Step 3.1: Configure Info.plist**
- [ ] Add `LSUIElement` key set to `true` in Info.plist
- [ ] This removes the app from dock and Application Switcher
- [ ] Verify menu bar icon remains functional

#### **Step 3.2: Update App Lifecycle**
- [ ] Modify `AppDelegate.swift` to handle app termination properly
- [ ] Add "Quit Remi" option to status bar menu
- [ ] Ensure app can be relaunched without dock icon

#### **Step 3.3: Handle Window Management**
- [ ] Update popover behavior for menu-bar-only app
- [ ] Ensure settings window can still be accessed
- [ ] Add proper window focus handling

#### **Step 3.4: User Experience Improvements**
- [ ] Add status bar menu with common actions
- [ ] Include "About Remi" and "Preferences" in menu
- [ ] Add visual indicators for active operations

---

## 🤖 **Phase 4: Configurable Groq Model Selection**

### ✅ Current State Analysis
- Model is hardcoded in `GroqService.swift` as "meta-llama/llama-4-scout-17b-16e-instruct"
- No UI for model selection in settings
- Need to add model configuration to `SettingsManager.swift`

### 📋 Implementation Steps

#### **Step 4.1: Add Model Configuration to Settings**
- [ ] Add `selectedGroqModel: String` property to `SettingsManager.swift`
- [ ] Create list of available Groq models with descriptions
- [ ] Add persistence for selected model preference

#### **Step 4.2: Update GroqService**
- [ ] Modify `GroqService.processQuery()` to use configurable model
- [ ] Replace hardcoded model string with settings value
- [ ] Add model validation and fallback logic

#### **Step 4.3: Add Model Selection UI**
- [ ] Create model picker in `IntegratedSettingsView.swift`
- [ ] Display model capabilities and descriptions
- [ ] Add model testing functionality

#### **Step 4.4: Enhanced Model Support**
- [ ] Add model-specific parameters (temperature, max tokens)
- [ ] Implement model performance indicators
- [ ] Add model switching without app restart

---

## 🎯 **Phase 1: Nook Drag & Drop Reordering** [LOWER PRIORITY]

### ✅ Current State Analysis
- Nooks are currently displayed in `SidebarView` using `ModernNookCard` components
- Ordering is alphabetical via `NookManager.fetchNooks()` which sorts by name
- No persistence layer for custom ordering exists

### 📋 Implementation Steps

#### **Step 1.1: Add Order Persistence to Data Model**
- [ ] Modify `Nook.swift` to include an `order: Int` property
- [ ] Update `NookManager.swift` to save/load order metadata alongside existing metadata
- [ ] Create migration logic for existing nooks without order

#### **Step 1.2: Implement Drag & Drop in UI**
- [ ] Add `.onDrag` and `.onDrop` to `ModernNookCard` in `SidebarView.swift`
- [ ] Update `NookListViewModel.swift` to handle reordering operations
- [ ] Implement visual feedback during drag operations (shadow, opacity changes)

#### **Step 1.3: Update Sorting Logic**
- [ ] Modify `NookManager.fetchNooks()` to sort by order instead of name
- [ ] Add fallback to alphabetical sorting for nooks with same order
- [ ] Update `NookListViewModel.filteredNooks` to respect custom ordering

#### **Step 1.4: Add Reorder Controls**
- [ ] Add optional up/down arrow buttons to each nook card
- [ ] Implement keyboard shortcuts for reordering (Cmd+Up/Down)
- [ ] Add "Reset to Alphabetical" option in context menu

---

## 📝 **Technical Implementation Notes**

### **Dependencies & Considerations**
- **SwiftUI Drag & Drop**: Requires iOS 16.0+ / macOS 13.0+
- **Groq API**: Need to research available models and their capabilities
- **Menu Bar App**: May affect app store distribution
- **Undo System**: Complex due to interaction with native NSTextView

### **Testing Strategy**
- Unit tests for each new feature
- Integration tests for undo/redo system
- Manual testing on different macOS versions
- Performance testing with large documents

### **Rollback Plans**
- Feature flags for new functionality
- Database migration rollback procedures
- Settings backup and restore mechanism

---

## ✅ **Definition of Done**

Each phase is complete when:
- [ ] Feature implemented and tested
- [ ] Documentation updated
- [ ] No regressions in existing functionality
- [ ] User experience is intuitive and consistent
- [ ] Performance meets or exceeds current standards

---

*This plan addresses all the original requests with a structured, implementable approach. Each phase can be developed independently with clear success criteria.*