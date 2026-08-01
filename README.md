# 🎬 Klipenho - Native macOS Gaming Clip to Reels & TikTok Converter

[![Swift 5.9](https://img.shields.io/badge/Swift-5.9-orange.svg?style=flat&logo=swift)](https://swift.org)
[![macOS 13.0+](https://img.shields.io/badge/macOS-13.0%2B-blue.svg?style=flat&logo=apple)](https://apple.com/macos)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

**Klipenho** is an open-source, ultra-fast native macOS desktop application designed for gamers and content creators. It automatically transforms 16:9 widescreen landscape gaming clips (Fortnite, Valorant, GTA V, Call of Duty, CS2, etc.) into ready-to-publish vertical 9:16 (1080x1920) videos optimized for Instagram Reels, TikTok, and YouTube Shorts.

No external dependencies, no FFmpeg bloatware — built 100% with native Apple frameworks (`SwiftUI`, `AVFoundation`, `Core Image`).

---

## ✨ Features

- **🚀 Automated 9:16 Canvas Generation:** Converts landscape clips to 1080x1920 vertical canvas seamlessly.
- **🖼️ Foreground Aspect Ratio Toggle (`3:4` & `4:3`):** Choose between vertical 3:4 crop (1080x1440) or landscape 4:3 crop (1080x810) centered on screen.
- **✨ Real-Time CIGaussianBlur Background:** Creates a blurred background from the original clip using hardware-accelerated Core Image filters with downsampled optimization.
- **💬 Dynamic POV Caption Overlay:**
  - Auto-formats captions with custom or default prefixes (`POV: ...`).
  - **Auto Font Scaling:** Automatically scales down long text so it never overflows.
  - **Customizable Fonts & Opacity:** Supports Impact, Helvetica Neue, Futura, Avenir Next, and SF Pro with adjustable box opacity.
  - **Vertical Y-Offset Control:** Precise slider (30px – 450px) to move text boxes up or down.
- **⚡ Unlimited Batch Queue Exporting:** Drag & drop dozens of clips at once, click **"Apply to All"**, and export all clips sequentially to a chosen output directory.
- **👁️ Live Real-Time Interactive Player:** Real-time preview powered by `AVPlayer` with frame-accurate scrubbing slider, play/pause controls, and volume mute toggle.

---

## 🛠️ Tech Stack & Architecture

- **Language:** Swift 5.9
- **Frameworks:** SwiftUI, AVFoundation, Core Image, AppKit
- **Minimum OS:** macOS 13.0 (Ventura) or newer
- **Rendering Pipeline:** Custom `AVMutableComposition` + `AVMutableVideoComposition` with custom filter handlers (`CIGaussianBlur` & Core Graphics bitmap canvas composition).

---

## 💻 Building from Source

### Prerequisites
- macOS 13.0+
- Xcode 15+ or Command Line Tools (`swift build`)

### Quick Start

1. **Clone the repository:**
   ```bash
   git clone https://github.com/emircan-976/klipenho.git
   cd klipenho
   ```

2. **Build and Run:**
   ```bash
   swift run
   ```

3. **Build Release Application Package (`Klipenho.app`):**
   ```bash
   swift build -c release
   mkdir -p "Klipenho.app/Contents/MacOS" "Klipenho.app/Contents/Resources"
   cp .build/release/Klipenho "Klipenho.app/Contents/MacOS/Klipenho"
   cp Info.plist "Klipenho.app/Contents/Info.plist"
   cp AppIcon.icns "Klipenho.app/Contents/Resources/AppIcon.icns"
   open "Klipenho.app"
   ```

---

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

---

## 🤝 Contributing

Contributions, issues, and feature requests are welcome! Feel free to check the [issues page](https://github.com/emircan-976/klipenho/issues).

---

Made with ❤️ for content creators.
