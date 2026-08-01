import Foundation
import CoreGraphics
import CoreImage
import AppKit

public final class TextOverlayRenderer: @unchecked Sendable {
    
    private struct CacheKey: Equatable {
        let text: String
        let canvasSize: CGSize
        let settings: AppConstants.TextOverlaySettings
    }
    
    private var cachedKey: CacheKey?
    private var cachedCIImage: CIImage?
    private let lock = NSLock()
    
    public init() {}
    
    /// Verilen metni 1080x1920 tuvali için özelleştirilmiş siyah kutu içinde CIImage olarak çizer (Cache destekli)
    public func createTextOverlayCIImage(
        text: String,
        canvasSize: CGSize,
        settings: AppConstants.TextOverlaySettings = AppConstants.TextOverlaySettings()
    ) -> CIImage? {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            lock.lock()
            cachedKey = nil
            cachedCIImage = nil
            lock.unlock()
            return nil
        }
        
        let key = CacheKey(text: trimmed, canvasSize: canvasSize, settings: settings)
        
        lock.lock()
        if cachedKey == key, let cachedImage = cachedCIImage {
            lock.unlock()
            return cachedImage
        }
        lock.unlock()
        
        let width = Int(canvasSize.width)
        let height = Int(canvasSize.height)
        
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        guard let context = CGContext(
            data: nil,
            width: width,
            height: height,
            bitsPerComponent: 8,
            bytesPerRow: 0,
            space: colorSpace,
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        ) else {
            return nil
        }
        
        let nsContext = NSGraphicsContext(cgContext: context, flipped: false)
        NSGraphicsContext.saveGraphicsState()
        NSGraphicsContext.current = nsContext
        
        // Dinamik Font Boyutu Hesaplama (Auto Font Scaling)
        var fontSize: CGFloat = settings.fontSize
        let minFontSize: CGFloat = 22.0
        let maxTextWidth = AppConstants.TextOverlay.maxTextWidth
        let maxAllowedHeight: CGFloat = 180.0 // Üst blur marjin alanına sığma sınırı
        
        var font: NSFont
        if settings.fontName == "System-Bold" {
            font = NSFont.boldSystemFont(ofSize: fontSize)
        } else {
            font = NSFont(name: settings.fontName, size: fontSize) ?? NSFont.boldSystemFont(ofSize: fontSize)
        }
        
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.alignment = .center
        paragraphStyle.lineBreakMode = .byWordWrapping
        
        var attributes: [NSAttributedString.Key: Any] = [
            .font: font,
            .foregroundColor: NSColor.white,
            .paragraphStyle: paragraphStyle
        ]
        
        var attributedString = NSAttributedString(string: trimmed, attributes: attributes)
        var textRect = attributedString.boundingRect(
            with: CGSize(width: maxTextWidth, height: 600),
            options: [.usesLineFragmentOrigin, .usesFontLeading]
        )
        
        // Metin çok uzunsa font boyutunu sığana kadar küçült
        while textRect.height > maxAllowedHeight && fontSize > minFontSize {
            fontSize -= 2.0
            if settings.fontName == "System-Bold" {
                font = NSFont.boldSystemFont(ofSize: fontSize)
            } else {
                font = NSFont(name: settings.fontName, size: fontSize) ?? NSFont.boldSystemFont(ofSize: fontSize)
            }
            attributes[.font] = font
            attributedString = NSAttributedString(string: trimmed, attributes: attributes)
            textRect = attributedString.boundingRect(
                with: CGSize(width: maxTextWidth, height: 600),
                options: [.usesLineFragmentOrigin, .usesFontLeading]
            )
        }
        
        let horizontalPadding = AppConstants.TextOverlay.boxPaddingHorizontal
        let verticalPadding = AppConstants.TextOverlay.boxPaddingVertical
        
        let boxWidth = min(textRect.width + (horizontalPadding * 2), canvasSize.width - 40)
        let boxHeight = textRect.height + (verticalPadding * 2)
        
        // Kutunun Canvas Üzerindeki Konumu (Top Offset - 1080x1920 dikey koordinat düzlemi)
        let boxX = (canvasSize.width - boxWidth) / 2.0
        let boxY = canvasSize.height - settings.topOffset - boxHeight
        
        let boxRect = CGRect(x: boxX, y: boxY, width: boxWidth, height: boxHeight)
        
        // Yarı Saydam Siyah Yuvarlatılmış Kutuyu Çiz
        let path = NSBezierPath(roundedRect: boxRect, xRadius: AppConstants.TextOverlay.boxCornerRadius, yRadius: AppConstants.TextOverlay.boxCornerRadius)
        let boxColor = NSColor(white: 0.0, alpha: CGFloat(settings.boxAlpha))
        boxColor.setFill()
        path.fill()
        
        // Metni Kutu İçine Çiz
        let drawTextRect = CGRect(
            x: boxX + horizontalPadding,
            y: boxY + verticalPadding,
            width: boxWidth - (horizontalPadding * 2),
            height: textRect.height
        )
        attributedString.draw(in: drawTextRect)
        
        NSGraphicsContext.restoreGraphicsState()
        
        guard let cgImage = context.makeImage() else { return nil }
        let ciImage = CIImage(cgImage: cgImage)
        
        lock.lock()
        cachedKey = key
        cachedCIImage = ciImage
        lock.unlock()
        
        return ciImage
    }
}
