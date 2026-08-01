import Foundation
import AVFoundation
import AppKit

@MainActor
public final class ExportManager: ObservableObject {
    
    private var activeExportSession: AVAssetExportSession?
    private var progressTimer: Timer?
    
    public init() {}
    
    /// Video composition ve asset'i verilen hedef URL'ye export eder
    public func exportVideo(
        composition: AVComposition,
        videoComposition: AVVideoComposition,
        outputURL: URL,
        progressCallback: @escaping (Double) -> Void
    ) async throws -> URL {
        
        let standardPath = outputURL.standardizedFileURL.path
        if FileManager.default.fileExists(atPath: standardPath) {
            try? FileManager.default.removeItem(atPath: standardPath)
        }
        
        guard let exportSession = AVAssetExportSession(
            asset: composition,
            presetName: AVAssetExportPresetHighestQuality
        ) else {
            throw NSError(domain: "ExportManager", code: 101, userInfo: [NSLocalizedDescriptionKey: "AVAssetExportSession oluşturulamadı."])
        }
        
        exportSession.outputURL = outputURL
        exportSession.outputFileType = .mp4
        exportSession.shouldOptimizeForNetworkUse = true
        exportSession.videoComposition = videoComposition
        
        nonisolated(unsafe) let session = exportSession
        
        // Progress izleyici (Main Queue)
        let timer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { _ in
            let progress = Double(session.progress)
            progressCallback(progress)
        }
        self.progressTimer = timer
        
        nonisolated(unsafe) let safeTimer = timer
        
        return try await withCheckedThrowingContinuation { continuation in
            session.exportAsynchronously { [weak self] in
                Task { @MainActor in
                    safeTimer.invalidate()
                    
                    guard let self = self else { return }
                    self.progressTimer = nil
                    self.activeExportSession = nil
                    
                    switch session.status {
                    case .completed:
                        progressCallback(1.0)
                        continuation.resume(returning: outputURL)
                    case .failed:
                        let error = session.error ?? NSError(domain: "ExportManager", code: 102, userInfo: [NSLocalizedDescriptionKey: "Video export işlemi başarısız oldu."])
                        continuation.resume(throwing: error)
                    case .cancelled:
                        let error = NSError(domain: "ExportManager", code: 103, userInfo: [NSLocalizedDescriptionKey: "Export işlemi iptal edildi."])
                        continuation.resume(throwing: error)
                    default:
                        let error = NSError(domain: "ExportManager", code: 104, userInfo: [NSLocalizedDescriptionKey: "Bilinmeyen export hatası."])
                        continuation.resume(throwing: error)
                    }
                }
            }
        }
    }
    
    /// Aktif export işlemini iptal etme
    public func cancelExport() {
        progressTimer?.invalidate()
        progressTimer = nil
        activeExportSession?.cancelExport()
        activeExportSession = nil
    }
}
