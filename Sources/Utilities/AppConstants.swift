import Foundation
import CoreGraphics
import SwiftUI

/// Uygulama genelinde kullanılan teknik ve görsel sabitler
public enum AppConstants {
    
    // MARK: - Video Dimensions (1080x1920 - 9:16)
    public enum Canvas {
        public static let width: CGFloat = 1080
        public static let height: CGFloat = 1920
        public static let size = CGSize(width: width, height: height)
        public static let aspectRatio: CGFloat = 9.0 / 16.0
    }
    
    // MARK: - Foreground Aspect Ratio Selection (3:4 or 4:3)
    public enum ForegroundAspectRatio: String, CaseIterable, Identifiable, Codable, Sendable {
        case ratio3x4 = "3:4"
        case ratio4x3 = "4:3"
        
        public var id: String { rawValue }
        
        public var width: CGFloat { 1080 }
        
        public var height: CGFloat {
            switch self {
            case .ratio3x4: return 1440.0 // 1080 * (4/3)
            case .ratio4x3: return 810.0  // 1080 / (4/3)
            }
        }
        
        public var numericRatio: CGFloat {
            switch self {
            case .ratio3x4: return 3.0 / 4.0
            case .ratio4x3: return 4.0 / 3.0
            }
        }
        
        public var topMargin: CGFloat {
            (1920.0 - height) / 2.0
        }
        
        public var frame: CGRect {
            CGRect(x: 0, y: topMargin, width: width, height: height)
        }
    }
    
    // MARK: - Foreground Crop Dimensions (Default 3:4 ratio, centered)
    public enum Foreground {
        public static let width: CGFloat = 1080
        public static let height: CGFloat = 1440 // 1080 * (4/3)
        public static let size = CGSize(width: width, height: height)
        public static let aspectRatio: CGFloat = 3.0 / 4.0
        public static let topMargin: CGFloat = 240 // (1920 - 1440) / 2
        public static let frame = CGRect(x: 0, y: topMargin, width: width, height: height)
    }
    
    // MARK: - Arka Plan Blur Ayarları
    public enum Background {
        /// Gaussian Blur yarıçapı (Core Image CIGaussianBlur)
        public static let blurRadius: Double = 35.0
    }
    
    // MARK: - Caption / Metin Overlay Ayarları & Stili
    public struct TextOverlaySettings: Codable, Equatable, Sendable {
        public var fontName: String = "HelveticaNeue-Bold"
        public var fontSize: CGFloat = 46.0
        public var boxAlpha: Double = 0.75
        public var prefixText: String = "POV: "
        public var showPrefix: Bool = true
        public var topOffset: CGFloat = 110.0
        
        public init(
            fontName: String = "HelveticaNeue-Bold",
            fontSize: CGFloat = 46.0,
            boxAlpha: Double = 0.75,
            prefixText: String = "POV: ",
            showPrefix: Bool = true,
            topOffset: CGFloat = 110.0
        ) {
            self.fontName = fontName
            self.fontSize = fontSize
            self.boxAlpha = boxAlpha
            self.prefixText = prefixText
            self.showPrefix = showPrefix
            self.topOffset = topOffset
        }
    }
    
    public enum AvailableFonts {
        public static let list: [(name: String, displayName: String)] = [
            ("HelveticaNeue-Bold", "Helvetica Neue Bold"),
            ("Impact", "Impact (Meme / Gaming)"),
            ("Futura-Bold", "Futura Bold"),
            ("AvenirNext-Heavy", "Avenir Next Heavy"),
            ("System-Bold", "System Bold (SF Pro)")
        ]
    }
    
    public enum TextOverlay {
        public static let defaultPrefix = "POV: "
        public static let fontName = "HelveticaNeue-Bold"
        public static let fontSize: CGFloat = 46.0
        public static let textColor = NSColor.white
        
        // Yarı saydam siyah arka plan kutusu (box)
        public static let boxCornerRadius: CGFloat = 18.0
        public static let boxPaddingHorizontal: CGFloat = 32.0
        public static let boxPaddingVertical: CGFloat = 18.0
        
        // Canvas üzerindeki dikey konum (Y ekseni, üstten uzaklık)
        public static let topOffset: CGFloat = 110.0
        public static let maxTextWidth: CGFloat = 920.0 // Canvas genişliği 1080 - kenar boşlukları
    }
    
    // MARK: - Desteklenen Dosya Formatları
    public enum SupportedFiles {
        public static let extensions = ["mp4", "mov", "m4v"]
        public static let utTypes = ["public.mpeg-4", "com.apple.quicktime-movie"]
    }
    
    // MARK: - Modern Professional Desktop App Design System (Slate Indigo Theme)
    public enum Colors {
        /// Slate Indigo primary accent (#5E6AD2) - Flat, solid, professional accent
        public static let slateIndigo = Color(red: 0.369, green: 0.416, blue: 0.824) // #5E6AD2
        public static let primaryAccent = slateIndigo
        public static let secondaryAccent = slateIndigo
        
        /// Neutral Pro Text Colors
        public static let textPrimary = Color(red: 0.953, green: 0.957, blue: 0.965) // #F3F4F6 Off-White
        public static let textSecondary = Color(red: 0.612, green: 0.639, blue: 0.686) // #9CA3AF Cool Gray
        
        /// Flat Solid Surface Backgrounds (No artificial gradients)
        public static let appBackground = Color(red: 0.059, green: 0.067, blue: 0.090) // #0F1117 Obsidian
        public static let cardBackground = Color(red: 0.094, green: 0.106, blue: 0.141) // #181B24 Charcoal Surface
        public static let inputBackground = Color(red: 0.133, green: 0.149, blue: 0.204) // #222634 Input Surface
        
        /// Precise 1px Card Border Stroke
        public static let cardBorder = Color(red: 0.165, green: 0.184, blue: 0.239).opacity(0.8) // #2A2F3D
        public static let cardBorderHover = slateIndigo.opacity(0.8)
        
        /// Compatibility Solid Fill (Flat color wrapper)
        public static let gamingGradient = LinearGradient(
            colors: [slateIndigo, slateIndigo],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        
        public static let buttonGradient = LinearGradient(
            colors: [slateIndigo, slateIndigo],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
}

// Custom Cursor Modifier for macOS
extension View {
    public func cursorHand() -> some View {
        self.onHover { inside in
            if inside {
                NSCursor.pointingHand.set()
            } else {
                NSCursor.arrow.set()
            }
        }
    }
}
