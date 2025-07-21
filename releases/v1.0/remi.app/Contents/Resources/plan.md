# Remi App - Local Build & Distribution Guide

## 🎯 Objective
Build and export the Remi macOS app locally to create a `.app` file that can be run personally and shared with others.

---

## 📋 Prerequisites

### System Requirements
- **macOS 12.0+** (Monterey or later)
- **Xcode 14.0+** (latest recommended)
- **Apple Developer Account** (free tier sufficient for local development)
- **Code signing certificates** (automatically managed by Xcode for development)

### Verify Xcode Installation
```bash
xcode-select --version
xcrun --version
```

---

## 🛠️ Step-by-Step Build Process

### Phase 1: Project Preparation

#### 1. Open Project in Xcode
```bash
cd /Users/mohamedashrefbenabdallah/Workspaces/remi
open remi.xcodeproj
```

#### 2. Configure Project Settings
1. Select the **remi** project in the navigator
2. Go to **General** tab
3. Verify/update these settings:
   - **Bundle Identifier**: `com.yourname.remi` (must be unique)
   - **Version**: Current app version (e.g., `1.0.0`)
   - **Build**: Increment for each build (e.g., `1`)
   - **Minimum macOS Version**: `12.0`

#### 3. Set Up Team & Signing
1. In **Signing & Capabilities** tab:
   - **Team**: Select your Apple Developer account
   - **Automatically manage signing**: ✅ Enabled
   - **Bundle Identifier**: Ensure it's unique
2. Verify signing certificate is valid (green checkmark)

#### 4. Configure Entitlements
Ensure `remi.entitlements` includes necessary permissions:
```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>com.apple.security.app-sandbox</key>
    <true/>
    <key>com.apple.security.files.user-selected.read-write</key>
    <true/>
    <key>com.apple.security.network.client</key>
    <true/>
</dict>
</plist>
```

---

### Phase 2: Build Configuration

#### 5. Set Build Configuration
1. Select **remi** scheme in toolbar
2. Edit scheme (⌘ + <):
   - **Build Configuration**: Release
   - **Debug executable**: Unchecked for distribution

#### 6. Clean Build Environment
```bash
# In Xcode menu: Product → Clean Build Folder
# Or use keyboard shortcut: ⌘ + Shift + K
```

#### 7. Resolve Dependencies
1. In Xcode: **File** → **Packages** → **Resolve Package Versions**
2. Ensure all Swift packages are resolved correctly

---

### Phase 3: Local Development Build

#### 8. Build for Testing (Quick Method)
```bash
# Option A: Using Xcode
# Press ⌘ + B to build
# Press ⌘ + R to build and run

# Option B: Using xcodebuild command line
cd /Users/mohamedashrefbenabdallah/Workspaces/remi
xcodebuild -project remi.xcodeproj -scheme remi -configuration Release build
```

#### 9. Locate Built App
After successful build, find the app at:
```
~/Library/Developer/Xcode/DerivedData/remi-[hash]/Build/Products/Release/remi.app
```

---

### Phase 4: Distribution Build (Archive)

#### 10. Create Archive
1. In Xcode menu: **Product** → **Archive**
2. Wait for build to complete
3. **Organizer** window will open automatically

#### 11. Export Archive
1. In Organizer, select your archive
2. Click **Distribute App**
3. Choose distribution method:

**For Local Use:**
- Select **Copy App**
- Choose destination folder
- Click **Export**

**For Sharing (Recommended):**
- Select **Developer ID**
- Choose **Export**
- Select destination folder

---

### Phase 5: Alternative Methods

#### Method A: Direct Build Export
```bash
# Build and export directly
xcodebuild -project remi.xcodeproj \
    -scheme remi \
    -configuration Release \
    -archivePath ./build/remi.xcarchive \
    archive

xcodebuild -exportArchive \
    -archivePath ./build/remi.xcarchive \
    -exportPath ./build/export \
    -exportOptionsPlist exportOptions.plist
```

#### Method B: Create exportOptions.plist
Create `exportOptions.plist` in project root:
```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>method</key>
    <string>developer-id</string>
    <key>teamID</key>
    <string>YOUR_TEAM_ID</string>
    <key>signingStyle</key>
    <string>automatic</string>
    <key>stripSwiftSymbols</key>
    <true/>
</dict>
</plist>
```

---

## 📦 Distribution Options

### Option 1: Personal Use Only
- Build directly from Xcode (⌘ + R)
- App will be code-signed for development
- Works only on your Mac and development team devices

### Option 2: Local Sharing (Ad-hoc)
- Use **Copy App** export method
- Recipients must trust your developer certificate
- Limited to devices registered in your developer account

### Option 3: Developer ID Distribution
- **Requires paid Apple Developer account ($99/year)**
- Apps can run on any Mac (with user permission)
- Apps are notarized by Apple
- Recommended for broader sharing

### Option 4: Unsigned Distribution
- For testing only
- Recipients must disable Gatekeeper:
```bash
# Recipients run this command:
sudo spctl --master-disable
# Or right-click app → Open (bypass security warning)
```

---

## 🔧 Troubleshooting

### Common Issues & Solutions

#### Signing Errors
- **Problem**: "No signing certificate found"
- **Solution**: 
  1. Ensure Apple ID is logged in Xcode
  2. Go to Xcode → Preferences → Accounts
  3. Download certificates manually

#### Build Errors
- **Problem**: Swift package resolution fails
- **Solution**: 
  1. Delete `Package.resolved`
  2. Clean build folder
  3. Resolve packages again

#### Runtime Errors
- **Problem**: App crashes on launch
- **Solution**: 
  1. Check entitlements configuration
  2. Verify all required frameworks are included
  3. Test with debug build first

#### Gatekeeper Issues
- **Problem**: "App cannot be opened because developer cannot be verified"
- **Solutions**:
  1. Right-click → Open → Open anyway
  2. System Preferences → Security → Allow app
  3. Command line: `xattr -cr /path/to/remi.app`

---

## 📂 Final File Locations

After successful export, you'll have:
```
📁 Export Location/
├── remi.app                    # Main application bundle
├── DistributionSummary.plist   # Export information
└── ExportOptions.plist         # Export configuration
```

---

## 🚀 Quick Start Commands

### One-Command Build
```bash
cd /Users/mohamedashrefbenabdallah/Workspaces/remi
xcodebuild -project remi.xcodeproj -scheme remi -configuration Release -derivedDataPath ./build clean build
```

### Find Built App
```bash
find ~/Library/Developer/Xcode/DerivedData -name "remi.app" -type d
```

### Create Distributable ZIP
```bash
cd /path/to/exported/app
zip -r remi.zip remi.app
```

---

## ✅ Success Checklist

- [ ] Project builds without errors
- [ ] App launches successfully
- [ ] All features work as expected  
- [ ] Menu bar icon appears correctly
- [ ] Global hotkeys function properly
- [ ] AI integration works (if configured)
- [ ] App can be shared and run on other Macs

---

## 📚 Additional Resources

- [Apple Developer Documentation](https://developer.apple.com/documentation/)
- [Xcode Build System Guide](https://developer.apple.com/documentation/xcode/build-system)
- [Code Signing Guide](https://developer.apple.com/library/archive/documentation/Security/Conceptual/CodeSigningGuide/)
- [macOS App Distribution](https://developer.apple.com/distribute/)

---

*Last updated: July 21, 2025*
*Compatible with: macOS 12+, Xcode 14+*