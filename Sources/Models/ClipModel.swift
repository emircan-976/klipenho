import Foundation
import AVFoundation
import AppKit

/// İşleme durumunu gösteren enum
public enum ProcessingStatus: Equatable {
    case idle
    case loading
    case ready
    case processing(progress: Double)
    case completed(outputURL: URL)
    case failed(error: String)
}

/// Yüklenen klip modelini temsil eden sınıf/yapı
public struct ClipModel: Identifiable, Equatable {
    public let id: UUID
    public let fileURL: URL
    public let fileName: String
    public let duration: Double
    public let naturalSize: CGSize
    public var thumbnail: NSImage?
    public var captionText: String
    public var foregroundRatio: AppConstants.ForegroundAspectRatio
    public var status: ProcessingStatus
    
    public init(
        id: UUID = UUID(),
        fileURL: URL,
        duration: Double = 0,
        naturalSize: CGSize = .zero,
        thumbnail: NSImage? = nil,
        captionText: String = "",
        foregroundRatio: AppConstants.ForegroundAspectRatio = .ratio3x4,
        status: ProcessingStatus = .idle
    ) {
        self.id = id
        self.fileURL = fileURL
        self.fileName = fileURL.lastPathComponent
        self.duration = duration
        self.naturalSize = naturalSize
        self.thumbnail = thumbnail
        self.captionText = captionText
        self.foregroundRatio = foregroundRatio
        self.status = status
    }
    
    /// Biçimlendirilmiş caption metnini ayarlara göre döndürür
    public func getFormattedCaption(settings: AppConstants.TextOverlaySettings) -> String {
        let trimmed = captionText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return "" }
        
        if !settings.showPrefix {
            return trimmed
        }
        
        let prefix = settings.prefixText.isEmpty ? "POV: " : settings.prefixText
        if trimmed.lowercased().hasPrefix(prefix.lowercased().trimmingCharacters(in: .whitespaces)) {
            return trimmed
        }
        return "\(prefix)\(trimmed)"
    }
    
    public var formattedCaption: String {
        getFormattedCaption(settings: AppConstants.TextOverlaySettings())
    }
    
    public static func == (lhs: ClipModel, rhs: ClipModel) -> Bool {
        return lhs.id == rhs.id &&
               lhs.fileURL == rhs.fileURL &&
               lhs.captionText == rhs.captionText &&
               lhs.foregroundRatio == rhs.foregroundRatio &&
               lhs.status == rhs.status
    }
}
