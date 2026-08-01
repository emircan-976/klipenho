import Foundation
import AVFoundation
import CoreImage
import AppKit

public final class VideoProcessorService: @unchecked Sendable {
    
    private let textRenderer = TextOverlayRenderer()
    
    public init() {}
    
    /// Video asset'i için 1080x1920 dikey formatlı AVComposition ve AVVideoComposition oluşturur
    public func createComposition(
        for asset: AVAsset,
        captionText: String,
        foregroundRatio: AppConstants.ForegroundAspectRatio = .ratio3x4,
        textSettings: AppConstants.TextOverlaySettings = AppConstants.TextOverlaySettings()
    ) async throws -> (composition: AVComposition, videoComposition: AVVideoComposition) {
        
        let composition = AVMutableComposition()
        
        guard let videoTrack = composition.addMutableTrack(
            withMediaType: .video,
            preferredTrackID: kCMPersistentTrackID_Invalid
        ) else {
            throw NSError(domain: "VideoProcessorService", code: 1, userInfo: [NSLocalizedDescriptionKey: "Video kanalı oluşturulamadı."])
        }
        
        let tracks = try await asset.loadTracks(withMediaType: .video)
        guard let sourceVideoTrack = tracks.first else {
            throw NSError(domain: "VideoProcessorService", code: 2, userInfo: [NSLocalizedDescriptionKey: "Kaynak video kanalı bulunamadı."])
        }
        
        let duration = try await asset.load(.duration)
        let timeRange = CMTimeRange(start: .zero, duration: duration)
        
        try videoTrack.insertTimeRange(timeRange, of: sourceVideoTrack, at: .zero)
        
        // Ses kanalı varsa ekle
        if let sourceAudioTrack = try await asset.loadTracks(withMediaType: .audio).first {
            if let audioTrack = composition.addMutableTrack(withMediaType: .audio, preferredTrackID: kCMPersistentTrackID_Invalid) {
                try? audioTrack.insertTimeRange(timeRange, of: sourceAudioTrack, at: .zero)
            }
        }
        
        // Preferred Transform (Orientation) bilgisini al
        let preferredTransform = try await sourceVideoTrack.load(.preferredTransform)
        
        // Custom AVVideoComposition oluşturma (CIFilter Handler ile)
        let videoComposition = AVMutableVideoComposition(asset: composition) { [weak self] request in
            guard let self = self else {
                request.finish(with: request.sourceImage, context: nil)
                return
            }
            
            let sourceImage = request.sourceImage.transformed(by: preferredTransform)
            let srcExtent = sourceImage.extent
            
            // Kaynağı (0,0) orijinine taşı
            let normSource = sourceImage.transformed(
                by: CGAffineTransform(translationX: -srcExtent.origin.x, y: -srcExtent.origin.y)
            )
            
            let srcW = normSource.extent.width
            let srcH = normSource.extent.height
            
            guard srcW > 0, srcH > 0 else {
                request.finish(with: request.sourceImage, context: nil)
                return
            }
            
            let canvasW = AppConstants.Canvas.width
            let canvasH = AppConstants.Canvas.height
            
            // 1. ARKA PLAN: 1080x1920 Aspect Fill + Optimize Downsampled Gaussian Blur
            let scaleBg = max(canvasW / srcW, canvasH / srcH)
            let scaledBgW = srcW * scaleBg
            let scaledBgH = srcH * scaleBg
            let offX = (scaledBgW - canvasW) / 2.0
            let offY = (scaledBgH - canvasH) / 2.0
            
            let scaledBg = normSource
                .transformed(by: CGAffineTransform(scaleX: scaleBg, y: scaleBg))
                .transformed(by: CGAffineTransform(translationX: -offX, y: -offY))
                .cropped(to: CGRect(x: 0, y: 0, width: canvasW, height: canvasH))
            
            // Blur işlemini 0.25x küçültülmüş boyutta uygulayıp tekrar ölçeklendirerek %80 performans kazanımı sağla
            let downscaleFactor: CGFloat = 0.25
            let downscaledBg = scaledBg.transformed(by: CGAffineTransform(scaleX: downscaleFactor, y: downscaleFactor))
            let blurredDownscaled = downscaledBg
                .clampedToExtent()
                .applyingFilter("CIGaussianBlur", parameters: [kCIInputRadiusKey: AppConstants.Background.blurRadius * downscaleFactor])
                .cropped(to: CGRect(x: 0, y: 0, width: canvasW * downscaleFactor, height: canvasH * downscaleFactor))
            
            let blurredBg = blurredDownscaled
                .transformed(by: CGAffineTransform(scaleX: 1.0 / downscaleFactor, y: 1.0 / downscaleFactor))
                .cropped(to: CGRect(x: 0, y: 0, width: canvasW, height: canvasH))
            
            // 2. ÖN PLAN: Selected Aspect Ratio (3:4 or 4:3) Crop + Scale + Canvas Dikey Ortalama
            let targetAspect: CGFloat = foregroundRatio.numericRatio
            let srcAspect = srcW / srcH
            
            var cropW: CGFloat
            var cropH: CGFloat
            var cropX: CGFloat
            var cropY: CGFloat
            
            if srcAspect > targetAspect {
                cropH = srcH
                cropW = srcH * targetAspect
                cropX = (srcW - cropW) / 2.0
                cropY = 0
            } else {
                cropW = srcW
                cropH = srcW / targetAspect
                cropX = 0
                cropY = (srcH - cropH) / 2.0
            }
            
            let croppedSrc = normSource.cropped(to: CGRect(x: cropX, y: cropY, width: cropW, height: cropH))
            let zeroCropped = croppedSrc.transformed(by: CGAffineTransform(translationX: -cropX, y: -cropY))
            
            let fgWidth = foregroundRatio.width
            let fgHeight = foregroundRatio.height
            let scaleFgX = fgWidth / cropW
            let scaleFgY = fgHeight / cropH
            
            let placedFg = zeroCropped
                .transformed(by: CGAffineTransform(scaleX: scaleFgX, y: scaleFgY))
                .transformed(by: CGAffineTransform(translationX: 0, y: foregroundRatio.topMargin))
                .cropped(to: foregroundRatio.frame)
            
            // 3. BİRLEŞTİRME (Foreground over Background)
            let compositedVideo = placedFg.composited(over: blurredBg)
            
            // 4. METİN / CAPTION OVERLAY
            var finalOutput = compositedVideo
            if let textCI = self.textRenderer.createTextOverlayCIImage(text: captionText, canvasSize: AppConstants.Canvas.size, settings: textSettings) {
                finalOutput = textCI.composited(over: compositedVideo)
            }
            
            request.finish(with: finalOutput, context: nil)
        }
        
        videoComposition.renderSize = AppConstants.Canvas.size
        videoComposition.frameDuration = CMTime(value: 1, timescale: 30) // 30 FPS
        
        return (composition, videoComposition)
    }
}
