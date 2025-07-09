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

## 🚀 Features

-   **AI-Powered Editing**: Use natural language to instruct Remi's AI to format lists, correct grammar, summarize text, or even generate ideas.
-   **Nook Organization**: Group your notes into "Nooks"—separate, focused workspaces for different projects or contexts.
-   **Full Markdown Support**: Write in Markdown with a live-rendering editor to see your formatting as you type.
-   **Global Hotkey**: Access Remi from anywhere in macOS with a customizable global hotkey.
-   **Modern, Minimalist UI**: A clean, distraction-free interface that respects your focus and the native macOS aesthetic.
-   **Themed Experience**: Supports both light and dark modes with a custom-designed theme.
-   **Undo/Redo Support**: Full support for undo and redo, so you never lose a change.

## 🔧 Tech Stack

Remi is a fully native macOS application built with the latest Apple technologies.

-   **Framework**: **SwiftUI** for a modern, declarative user interface.
-   **Language**: **Swift 5**
-   **Core Dependencies**:
    -   [**Groq**](https://groq.com/): Powers the lightning-fast AI capabilities.
    -   [**HotKey**](https://github.com/soffes/HotKey): For capturing the global hotkey.
    -   [**Alamofire**](https://github.com/Alamofire/Alamofire): For robust networking.
    -   [**SwiftyJSON**](https://github.com/SwiftyJSON/SwiftyJSON): To make handling JSON a breeze.

## 🛠️ Getting Started

To get a local copy up and running, follow these simple steps.

### Prerequisites

-   macOS 14.0 or later
-   Xcode 15.0 or later

### Installation

1.  **Clone the repository:**
    ```sh
    git clone https://github.com/your-username/remi.git
    ```
2.  **Navigate to the project directory:**
    ```sh
    cd remi
    ```
3.  **Open the project in Xcode:**
    ```sh
    open remi.xcodeproj
    ```
    Xcode will automatically resolve all Swift Package Manager dependencies.

4.  **Configure API Keys (if necessary):**
    You will need to add your Groq API key to the `GroqService.swift` file to enable AI features.
    ```swift
    // In Core/Services/GroqService.swift
    private let apiKey = "YOUR_GROQ_API_KEY" 
    ```

5.  **Build & Run:**
    Select the `remi` scheme and press the Run button (or `Cmd+R`).

## 💡 Usage

1.  **Set Your Hotkey**: Go to Settings to configure a global hotkey that works for you.
2.  **Create a Nook**: Open Remi and create your first Nook to hold your notes.
3.  **Start Writing**: Write your tasks, ideas, or meeting notes using Markdown.
4.  **Summon the AI**: Click the ✨ button in the editor to bring up the AI prompt.
5.  **Give Instructions**: Ask the AI to perform an action, such as:
    -   *"Format this into a numbered list."*
    -   *"Summarize the key points above."*
    -   *"Correct any spelling or grammar mistakes."*

## 🙌 Contributing

Contributions are what make the open-source community such an amazing place to learn, inspire, and create. Any contributions you make are **greatly appreciated**.

1.  Fork the Project
2.  Create your Feature Branch (`git checkout -b feature/AmazingFeature`)
3.  Commit your Changes (`git commit -m 'Add some AmazingFeature'`)
4.  Push to the Branch (`git push origin feature/AmazingFeature`)
5.  Open a Pull Request

Please try to match the existing code style and add comments where necessary.

## 📄 License

Distributed under the MIT License. See `LICENSE.md` for more information.

## 🙏 Acknowledgments

-   The teams behind the great open-source libraries used in this project.
-   Everyone who provides feedback and contributes to making Remi better.