# Remi v2.0.0 — Remy Version 2 🪟✨

## 🎉 Major Release: Liquid Glass Design

This is a landmark release for Remi, introducing the all-new **Liquid Glass** visual language powered by Xcode 26 / macOS 26 APIs and Apple's new design system.

## ✨ What's New

### 🔮 Liquid Glass UI Overhaul
- **Full Liquid Glass redesign** across all panels, sidebars, and overlays
- **Native macOS 26 materials** with dynamic depth, refraction, and blur
- **Apple-standard system materials** used throughout for legibility and platform coherence
- **Glassmorphism sidebar and nook cards** with refined translucency layers

### 🪄 Refined Interactions
- Smoother hover and press feedback across all interactive elements
- Improved animation curves aligned with Apple's motion guidelines
- Enhanced focus and keyboard navigation throughout the app

### 🏗️ Architecture Improvements
- Cleaner component boundaries with better state isolation
- Improved `@MainActor` boundary enforcement for UI updates
- Reduced implicit animation propagation for predictable transitions

### 🧹 Code Quality
- Significant simplification of `IntegratedSettingsView`, `TaskEditorViewModel`, and `FloatingNookStrip`
- Removed duplication across view components
- Production-ready codebase with no placeholder TODOs

## 🐛 Bug Fixes
- Resolved hotkey conflict issues with system-wide shortcuts
- Fixed edit button state management in nook sidebar cards
- Improved AI input focus handling and animation timing

---

**Download**: [Remi-v2.0.0-macOS.zip](./Remi-v2.0.0-macOS.zip)

**System Requirements**: macOS 14.5 or later (Liquid Glass features require macOS 26+)

**Installation**: Download the zip file, extract it, and move `remi.app` to your Applications folder.

---

*Remi v2.0.0 — Built with Xcode 26.3 · macOS 26 SDK*
