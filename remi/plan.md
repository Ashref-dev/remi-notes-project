# Remi macOS App - Detailed Implementation Plan

This plan outlines the step-by-step implementation for building Remi, a macOS menu bar app for managing task lists ("Nooks") with local Markdown files and Groq AI assistant integration.

---

## Project Structure

This is the proposed project structure to keep the codebase organized and maintainable.

```
remi/
├── App/
│   ├── remiApp.swift           # Main app entry point
│   ├── AppDelegate.swift       # App lifecycle, menu bar, and hotkey setup
│   └── Assets.xcassets       # App icons and colors
├── Core/
│   ├── Models/
│   │   └── Nook.swift          # Data model for a Nook
│   └── Services/
│       ├── NookManager.swift   # Handles all file system operations for Nooks
│       ├── GroqService.swift   # Manages API calls to the Groq service
│       └── SettingsManager.swift # Manages app settings via UserDefaults
├── UI/
│   ├── Views/
│   │   ├── ContentView.swift     # Main view, acts as a router
│   │   ├── NookListView.swift    # Displays the list of all Nooks
│   │   └── TaskEditorView.swift  # The editor for a Nook's tasks.md file
│   └── ViewModels/
│       ├── NookListViewModel.swift # State and logic for NookListView
│       └── TaskEditorViewModel.swift # State and logic for TaskEditorView
└── Utils/
    ├── HotkeyManager.swift     # Wrapper for the HotKey library
    └── Dependencies.swift      # Clean wrapper for imported packages
```

---

## Phase 1: Core App Functionality

### 1.1. Project Setup
- [x] Create Xcode Project (`remi`).
- [x] Add Swift Package Manager dependencies: `HotKey`, `Alamofire`, `LaunchAtLogin`.

### 1.2. Application Delegate
- [x] Create `AppDelegate.swift` to manage app lifecycle events.
- [x] In `remiApp.swift`, set up `NSApplicationDelegateAdaptor` to use `AppDelegate`.

### 1.3. Menu Bar Item
- [x] In `AppDelegate.swift`, add a function to create an `NSStatusItem` in the system menu bar.
- [x] Assign a default icon (e.g., SF Symbol) to the status item.
- [x] Implement an action to show/hide the main window when the menu bar icon is clicked.

### 1.4. Main Window
- [x] Create a borderless, non-resizable `NSPanel` subclass for the main window.
- [x] Implement logic to make the window appear in the center of the screen.
- [x] Add functionality to dismiss the window when the user clicks outside of it or presses the `Esc` key.

### 1.5. Global Hotkey
- [x] Create `HotkeyManager.swift` to encapsulate the `HotKey` library.
- [x] In `AppDelegate.swift`, use `HotkeyManager` to register a global hotkey (e.g., `Cmd + Option + R`).
- [x] Bind the hotkey to the same action that shows/hides the main window.

---

## Phase 2: Nook Management

### 2.1. Nook Model
- [x] Create `Nook.swift` with a struct representing a Nook, containing properties like `id`, `name`, and `url` to its folder.

### 2.2. NookManager Service
- [x] Create `NookManager.swift`.
- [x] Implement a function to create the `~/Remi/Nooks/` directory on first launch if it doesn't exist.
- [x] Create a default "Welcome" Nook with an introductory `tasks.md` file.
- [x] Implement a function to scan the `Nooks` directory and return an array of `Nook` objects.
- [x] Implement functions to create, rename, and delete Nook folders.
- [x] Implement functions to read from and write to a `tasks.md` file within a specific Nook folder.

---

## Phase 3: User Interface (SwiftUI)

### 3.1. Nook List View
- [x] Create `NookListView.swift`.
- [x] Create `NookListViewModel.swift` to fetch and manage the list of Nooks from `NookManager`.
- [x] Design a view that displays each Nook as a card with its name and a preview of its content.
- [x] Add a "New Nook" button that prompts the user for a name and uses `NookManager` to create it.
- [x] Add a context menu (or swipe action) to rename or delete a Nook, with confirmation alerts.
- [x] Implement navigation to the `TaskEditorView` when a Nook card is clicked.

### 3.2. Task Editor View
- [x] Create `TaskEditorView.swift`.
- [x] Create `TaskEditorViewModel.swift` to load, manage, and save the content of a selected Nook's `tasks.md`.
- [x] Use a `TextEditor` bound to the content of the `tasks.md` file.
- [x] Implement debouncing to save file changes automatically after a short delay of inactivity.
- [x] Add a text input field at the bottom for adding new tasks or sending queries to the AI.
- [x] Add a "Back" button to return to the `NookListView`.

---

## Phase 4: AI Integration

### 4.1. Groq Service
- [x] Create `GroqService.swift`.
- [x] Implement a function to make API calls to the Groq chat completions endpoint using `Alamofire`.
- [x] Securely manage the API key (e.g., from a configuration file or user settings, not hardcoded).
- [x] Structure the request payload with the model, messages, and other parameters.
- [x] Implement error handling for network requests and API responses.

### 4.2. AI in Task Editor
- [x] In `TaskEditorViewModel.swift`, add logic to differentiate between a plain task and an AI query.
- [x] If the input is a query, call `GroqService` with the user's input.
- [x] Prepend the existing `tasks.md` content as context in the prompt to the AI.
- [x] On receiving a response, parse the Markdown and merge the new tasks into the `tasks.md` file.
- [x] Refresh the `TextEditor` to display the updated content.

---

## Phase 5: Final Touches

### 5.1. Settings
- [x] Create `SettingsManager.swift` to handle `UserDefaults`.
- [x] Create a simple settings view where users can:
    - [ ] Set the global hotkey combination.
    - [x] Enter their Groq API key.
    - [x] Toggle "Launch at Login" using the `LaunchAtLogin` package.
- [x] Persist the last-viewed Nook using `UserDefaults`.

### 5.2. UI/UX Polish
- [x] Ensure the UI is fully compatible with both light and dark mode.
- [x] Add subtle animations and transitions for a smoother user experience.
- [x] Use SF Symbols consistently for all icons and buttons.
- [x] Refine the layout, spacing, and typography.

---

## Phase 6: Testing and Distribution

### 6.1. Manual Testing Checklist
- [x] Verify app starts correctly and menu bar icon appears.
- [x] Test hotkey and menu bar icon to ensure they toggle the window.
- [x] Create, rename, and delete Nooks.
- [x] Add, edit, and delete tasks manually in the editor.
- [x] Add tasks using the AI assistant and verify the list updates correctly.
- [x] Check that all settings are saved and loaded correctly.
- [x] Confirm "Launch at Login" works as expected.

### 6.2. Distribution
- [x] Archive the app in Xcode.
- [x] Sign with a Developer ID for distribution outside the App Store.
- [x] Consider notarizing the app to ensure it runs smoothly on other machines.