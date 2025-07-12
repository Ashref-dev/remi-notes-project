# ✨ Remi - The AI-Powered macOS Notepad

<p align="center">
  <img src="Documentation/logo_placeholder.png" alt="Remi App Icon" width="150"/>
</p>

<p align="center">
  <strong>A smart, native macOS notepad for your tasks and ideas, supercharged by AI.</strong>
  <br /><br />
  <img src="https://img.shields.io/badge/platform-macOS-lightgrey.svg" alt="Platform: macOS" />
  <img src="https://img.shields.io/badge/swift-5.10-orange.svg" alt="Swift 5.10" />
  <img src="https://img.shields.io/badge/license-MIT-blue.svg" alt="License: MIT" />
  <img src="https://img.shields.io/github/actions/workflow/status/your-username/remi/build.yml?branch=main" alt="Build Status" />
</p>

---

Remi is a lightweight, beautifully designed notepad for macOS that seamlessly integrates into your workflow. It's built for speed and simplicity, allowing you to capture and organize your thoughts effortlessly. With its built-in AI assistant, Remi can help you edit, format, and brainstorm directly within your notes.

<p align="center">
  <img src="Documentation/screenshot_placeholder.png" alt="Remi Screenshot" width="700"/>
  <br />
  <em>(A screenshot of your app would be perfect here!)</em>
</p>

## 🌳 Project Structure

```
.
├── App
│   ├── AppDelegate.swift
│   ├── Assets.xcassets
│   │   ├── AccentColor.colorset
│   │   │   └── Contents.json
│   │   ├── AppIcon.appiconset
│   │   │   └── Contents.json
│   │   └── Contents.json
│   └── remiApp.swift
├── Core
│   ├── Models
│   │   └── Nook.swift
│   └── Services
│       ├── ErrorHandlingService.swift
│       ├── GroqDataModels.swift
│       ├── GroqService.swift
│       ├── NookManager.swift
│       └── SettingsManager.swift
├── Documentation
│   └── THEME_SETUP.md
├── Preview Content
│   └── Preview Assets.xcassets
│       └── Contents.json
├── UI
│   ├── Theme
│   │   ├── ColorPalette.swift
│   │   └── Theme.swift
│   ├── ViewModels
│   │   ├── NookListViewModel.swift
│   │   └── TaskEditorViewModel.swift
│   └── Views
│       ├── Components
│       │   ├── AIInputView.swift
│       │   └── NookCardView.swift
│       ├── ContentView.swift
│       ├── NookListView.swift
│       ├── OnboardingView.swift
│       ├── Reusable
│       │   ├── ElegantProgressView.swift
│       │   └── LiveMarkdownEditor.swift
│       ├── Settings
│       │   ├── HotkeyRecorderView.swift
│       │   └── SettingsView.swift
│       └── TaskEditorView.swift
├── Utils
│   └── HotkeyManager.swift
├── build_log.txt
├── plan.md
└── remi.entitlements
```