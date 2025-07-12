# Project Plan

This document outlines the plan to refactor the Remi application's UI, implement robust theme support, and update project documentation.

## v3 Design Plan

### 1. UI Color Refactoring

- **Objective:** Ensure the entire application UI consistently uses the new `ColorPalette` for all color definitions, eliminating any remaining dependencies on the old `AppColors` system.
- **Tasks:**
    - [ ] Thoroughly scan all UI files for any lingering references to `AppColors`.
    - [ ] Replace any found references with the appropriate color from `ColorPalette.swift`.
    - [ ] Verify that all UI elements are now using the centralized `ColorPalette`.

### 2. Dark and Light Theme Implementation

- **Objective:** Implement full support for both dark and light system themes, ensuring all UI components are visually correct and legible in both modes.
- **Tasks:**
    - [ ] Review and adjust all UI components to ensure they adapt correctly to theme changes.
    - [ ] Pay special attention to the markdown editor to ensure text is always legible against the background in both dark and light themes.
    - [ ] Test the application in both dark and light modes to identify and fix any visual inconsistencies.

### 3. Documentation Update

- **Objective:** Update the project's `README.md` to reflect the current state of the codebase and project structure.
- **Tasks:**
    - [ ] Regenerate the project structure tree.
    - [ ] Update the `README.md` file with the new project structure.
