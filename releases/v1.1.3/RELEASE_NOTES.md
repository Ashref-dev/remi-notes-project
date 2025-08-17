# Remi v1.1.3 Release Notes

## 🎉 New Features & Improvements

### 🔧 Critical Bug Fix - Edit Button Functionality Restored
- **Fixed broken edit button** - Edit buttons on nook cards in the sidebar now work properly
- **Restored nook editing modal** - Clicking edit buttons now properly opens the nook editor sheet
- **Improved state management** - Fixed communication between card overlay buttons and edit modal triggers

### AI Quick Actions Panel Overhaul
- **Eliminated distracting card animations** - Cards now appear instantly when the panel opens
- **Smooth panel-only animation** - Only the container slides up/down, creating a cleaner experience
- **Professional Apple-style animations** following Human Interface Guidelines
- **Improved performance** with optimized animation handling and reduced visual complexity

### User Experience Enhancements
- **Instant card display** - No more sliding cards from top that interrupt workflow
- **Cleaner visual hierarchy** - Static card layout reduces distractions and improves focus
- **Consistent animation behavior** across all Quick Actions interactions
- **Minimalist design approach** emphasizing content over effects

### Technical Improvements
- Removed implicit animation propagation to child components
- Disabled unnecessary transitions on individual action cards
- Scoped animations to container-level only for better performance
- Stabilized card identities to prevent unwanted insertion animations
- Enhanced animation transaction management

## 🐛 Bug Fixes
- Fixed Quick Actions cards sliding in from top when panel opens
- Resolved animation conflicts between panel container and card content
- Eliminated visual jank during Quick Actions panel transitions
- Fixed hover/press animations interfering with panel show/hide
- Corrected implicit animation bleeding into card components

## 💻 Developer Experience
- Cleaner animation architecture with explicit scope control
- Better separation between container and content animations
- Improved code organization for animation handling
- Enhanced performance through reduced animation overhead

---

**Download**: [Remi-v1.1.3-macOS.zip](./Remi-v1.1.3-macOS.zip)

**System Requirements**: macOS 14.5 or later

**Installation**: Download the zip file, extract it, and move the `remi.app` to your Applications folder.

**Note**: This release focuses on polish and user experience improvements, making the AI Quick Actions panel feel more responsive and professional.

## 🎯 Major Improvements

### ✨ Enhanced AI Input Experience
- **Auto-Focus**: AI input now automatically focuses when activated - simply click the AI button and start typing immediately
- **Smooth Animations**: Redesigned slide-up/slide-down animations with spring physics for premium feel
- **Visual Feedback**: AI button now provides better visual states (active/inactive) with enhanced shadows and gradients
- **Better Timing**: Optimized focus timing to work seamlessly with animations

### 🔧 Hotkey Conflict Fix
- **System-Wide Fix**: Resolved Command+Shift+C conflict with other applications (browsers, etc.)
- **Local Shortcuts**: Copy shortcut now works locally within Remi when focused, respecting system app focus
- **Better UX**: Other apps can now use their native shortcuts without interference from Remi

## 🎨 UI/UX Improvements

### Modern AI Button Design
- Dynamic icon changes based on state
- Enhanced gradient backgrounds with depth
- Hierarchical symbol rendering for iOS-style polish
- Improved shadow effects and scaling feedback

### Refined Animations
- Spring-based animations for natural feel
- Asymmetric transitions (different entrance/exit animations)
- Optimized timing for smoother interactions
- Scale and opacity combinations for premium polish

## 🔧 Technical Improvements
- Better focus state management between parent and child components
- Improved animation coordination
- Enhanced component communication patterns
- More responsive UI interactions

## 🐛 Bug Fixes
- Fixed global hotkey conflicts with system applications
- Resolved AI input focus issues
- Improved animation consistency
- Better error handling in focus management

---

**This release focuses on user experience refinements and resolving system conflicts. The AI assistant is now more intuitive and responsive, while ensuring Remi plays nicely with other applications.**