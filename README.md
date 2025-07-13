# ⚡ Remi - Your AI-Powered Knowledge Hub

<p align="center">
  <img src="Documentation/logo_placeholder.png" alt="Remi App Icon" width="120"/>
</p>

<p align="center">
  <strong>Lightning-fast access to your most valuable knowledge, right from your macOS menu bar.</strong>
  <br />
  <em>Never lose a brilliant idea, useful command, or important note again.</em>
</p>

<p align="center">
  <img src="https://img.shields.io/badge/platform-macOS%2012%2B-lightgrey.svg" alt="Platform: macOS 12+" />
  <img src="https://img.shields.io/badge/swift-5.10-orange.svg" alt="Swift 5.10" />
  <img src="https://img.shields.io/badge/AI-Groq%20Powered-blue.svg" alt="AI: Groq Powered" />
  <img src="https://img.shields.io/badge/license-MIT-green.svg" alt="License: MIT" />
</p>

---

## 🎯 What is Remi?

Remi transforms your macOS menu bar into a **supercharged knowledge management system**. It's your personal assistant for storing, organizing, and instantly accessing:

- 🤖 **AI Prompts** you use daily
- 💻 **Terminal commands** and code snippets  
- 📝 **Quick notes** and brilliant ideas
- 🔧 **Useful tips** and workflows
- 📚 **Reference materials** and documentation

**Access everything with a single hotkey.** No more hunting through files, bookmarks, or sticky notes.

<p align="center">
  <img src="Documentation/screenshot_placeholder.png" alt="Remi in action" width="700"/>
  <br />
  <em>Your knowledge, instantly accessible from anywhere on macOS</em>
</p>

---

## ✨ Key Features

### 🚀 **Instant Access**
- **Global hotkey** (⌘+Shift+R) - summon Remi from anywhere
- **Menu bar integration** - always one click away
- **Lightning-fast search** through all your nooks

### 🧠 **AI-Powered Intelligence**
- **Smart editing** with Groq AI integration
- **Content enhancement** - improve clarity and organization
- **Context-aware suggestions** based on your workflow

### 📁 **Nooks System**
Organize your knowledge into focused "**Nooks**" - think of them as smart, AI-enhanced notepads:

```
📂 My Nooks/
├── 🤖 AI Prompts/          # Daily prompts for ChatGPT, Claude, etc.
├── 🐳 Docker Commands/     # Container management snippets
├── 🔧 Terminal Shortcuts/  # Bash/Zsh one-liners
├── 💡 Project Ideas/       # Brilliant thoughts and concepts
├── 📝 Meeting Notes/       # Quick capture during calls
└── 🎯 Daily Workflows/     # Step-by-step processes
```

### 🎨 **Beautiful, Native Design**
- **macOS-native interface** that feels right at home
- **Dark/Light mode support** 
- **Elegant typography** and spacing
- **Smooth animations** and transitions

---

## 🏃‍♂️ Real-World Use Cases

### **For Developers**
```markdown
# Docker Nook
🐳 Quick Docker Commands

## Container Management
docker ps -a                    # List all containers
docker logs -f container_name   # Follow logs
docker exec -it container_name bash  # Interactive shell

## Cleanup Commands  
docker system prune -a          # Clean everything
docker volume prune             # Remove unused volumes

## Useful One-liners
docker run --rm -v $(pwd):/app node:16 npm install
```

### **For AI Power Users**
```markdown
# AI Prompts Nook
🤖 Daily AI Prompts

## Code Review
"Review this code for security, performance, and best practices. 
Provide specific suggestions with examples."

## Content Creation
"Transform this rough draft into polished, engaging content while 
maintaining the original tone and key messages."

## Problem Solving
"Break down this complex problem into manageable steps and suggest 
the most efficient approach."
```

### **For System Administrators**
```markdown
# Server Management Nook
🖥️ Server Commands

## System Monitoring
htop                             # Interactive process viewer
df -h                           # Disk usage
netstat -tulpn                  # Network connections
journalctl -f                   # Follow system logs

## Quick Diagnostics
curl -I website.com             # Check HTTP headers
ping -c 4 8.8.8.8              # Test connectivity
```

---

## 🚀 Getting Started

### **Installation**
1. **Download** the latest release from GitHub
2. **Drag Remi** to your Applications folder
3. **Launch Remi** - it'll appear in your menu bar
4. **Set your hotkey** in Preferences (default: ⌘+Shift+R)

### **Quick Setup**
1. **Create your first Nook** - click the "+" button
2. **Add your content** - paste in your most-used commands or notes
3. **Use the hotkey** to access instantly from anywhere
4. **Optional: Add Groq API key** for AI features

### **Pro Tips**
- Use **descriptive nook names** like "Docker Commands" or "AI Prompts"
- **Organize by context** rather than by type
- **Keep frequently used items** at the top of each nook
- **Use the AI assistant** to improve and organize your content

---

## 🎛️ Configuration

### **Global Hotkey**
Customize your hotkey in Settings:
- Default: `⌘ + Shift + R`
- Choose any combination that works for your workflow

### **AI Integration**
Add your Groq API key for intelligent features:
1. Get a free key from [console.groq.com](https://console.groq.com/keys)
2. Paste it in Remi's Settings
3. Enjoy AI-powered editing and suggestions

### **Launch at Login**
Enable in Settings to have Remi ready when you start your Mac.

---

## 🏗️ Technical Architecture

Remi is built with modern macOS development practices:

```
🏛️ Architecture Overview
├── 🎯 SwiftUI Interface       # Native, responsive UI
├── 🧠 AI Integration         # Groq-powered intelligence  
├── 📁 File-based Storage     # Simple, portable nooks
├── ⚡ Global Hotkey System   # System-wide accessibility
├── 🎨 Theme Management       # Dark/Light mode support
└── 🛡️ Error Handling        # Robust, user-friendly errors
```

### **Core Technologies**
- **SwiftUI** - Modern, declarative UI framework
- **Alamofire** - Reliable networking for AI features
- **HotKey** - Global keyboard shortcut management
- **Groq AI** - Fast, efficient language model integration

---

## 🤝 Contributing

We welcome contributions! Here's how you can help:

### **Development Setup**
```bash
# Clone the repository
git clone https://github.com/Ashref-dev/remi-notes-project.git
cd remi-notes-project

# Open in Xcode
open remi.xcodeproj

# Build and run
⌘ + R
```

### **Ways to Contribute**
- 🐛 **Report bugs** or suggest features
- 📝 **Improve documentation** 
- 🎨 **Design improvements**
- 🔧 **Code contributions**
- 🌍 **Localization** support

---

## 🗺️ Roadmap

### **Coming Soon**
- [ ] 🔄 **Sync across devices** via iCloud
- [ ] 📱 **iOS companion app** 
- [ ] 🏷️ **Tags and smart filtering**
- [ ] 📊 **Usage analytics** and insights
- [ ] 🔗 **Integration with popular tools** (Notion, Obsidian)

### **Future Vision**
- [ ] 🤖 **Advanced AI workflows**
- [ ] 👥 **Team collaboration** features
- [ ] 🔌 **Plugin system** for extensibility
- [ ] 🎯 **Smart suggestions** based on context

---

## 💬 Community & Support

- **GitHub Issues**: [Report bugs or request features](https://github.com/Ashref-dev/remi-notes-project/issues)
- **Discussions**: [Join the community](https://github.com/Ashref-dev/remi-notes-project/discussions)
- **Email**: Send feedback to `support@remi-app.com`

---

## 📄 License

Remi is open source software licensed under the **MIT License**. See [LICENSE](LICENSE) for details.

---

## 🙏 Acknowledgments

Built with ❤️ using:
- [Groq](https://groq.com) - Lightning-fast AI inference
- [Alamofire](https://github.com/Alamofire/Alamofire) - Swift networking
- [HotKey](https://github.com/soffes/HotKey) - Global shortcuts
- [Swift](https://swift.org) & [SwiftUI](https://developer.apple.com/swiftui/) - Apple's modern development stack

---

<p align="center">
  <strong>Transform your workflow with Remi - where knowledge meets convenience.</strong>
  <br />
  <br />
  <a href="https://github.com/Ashref-dev/remi-notes-project/releases">⬇️ Download Latest Release</a>
  ·
  <a href="https://github.com/Ashref-dev/remi-notes-project/discussions">💬 Join Community</a>
  ·
  <a href="https://github.com/Ashref-dev/remi-notes-project/issues">🐛 Report Bug</a>
</p>