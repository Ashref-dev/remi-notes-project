# Remi Theme Setup

For the new design to render correctly, you need to add the following color sets to `App/Assets.xcassets`.

## Instructions

1.  Open your project in Xcode.
2.  Navigate to `remi/App/Assets.xcassets` in the project navigator.
3.  Right-click in the asset list and choose "New Color Set".
4.  Name the color set exactly as listed below.
5.  For each color set, you can define different colors for "Any Appearance" (Light Mode) and "Dark" appearance.

## Required Colors

Here are the recommended colors. Feel free to adjust them to your liking.

### 1. `BackgroundColor`
- **Any Appearance (Light):** `(242, 242, 247)` or `#F2F2F7` (System Gray 6)
- **Dark Appearance:** `(28, 28, 30)` or `#1C1C1E` (System Gray 6 Dark)

### 2. `BackgroundSecondaryColor`
- **Any Appearance (Light):** `(229, 229, 234)` or `#E5E5EA` (System Gray 5)
- **Dark Appearance:** `(44, 44, 46)` or `#2C2C2E` (System Gray 5 Dark)

### 3. `TextPrimaryColor`
- **Any Appearance (Light):** `(0, 0, 0)` or `#000000` (Label Color)
- **Dark Appearance:** `(255, 255, 255)` or `#FFFFFF` (Label Color Dark)

### 4. `TextSecondaryColor`
- **Any Appearance (Light):** `(60, 60, 67)` opacity 60% or `#3C3C43` with 60% opacity (Secondary Label)
- **Dark Appearance:** `(235, 235, 245)` opacity 60% or `#EBEBF5` with 60% opacity (Secondary Label Dark)

### 5. `CardBackgroundColor`
- **Any Appearance (Light):** `(255, 255, 255)` or `#FFFFFF` (System Background)
- **Dark Appearance:** `(58, 58, 60)` or `#3A3A3C` (System Gray 4 Dark)

### 6. `CardBackgroundHoverColor`
- **Any Appearance (Light):** `(242, 242, 247)` or `#F2F2F7` (System Gray 6)
- **Dark Appearance:** `(72, 72, 74)` or `#48484A` (System Gray 3 Dark)

*Note: `CardBackgroundSelectedColor` and `BorderColor` are defined programmatically in `AppColors.swift` and do not need to be added to the asset catalog.*
