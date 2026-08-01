import Foundation
import SwiftUI
import Combine
import AVFoundation
import AppKit

@MainActor
public final class MainViewModel: ObservableObject {
    
    // MARK: - Published State
    @Published public var clipQueue: [ClipModel] = []
    @Published public var selectedClipID: UUID?
    @Published public var captionInput: String = ""
    @Published public var selectedForegroundRatio: AppConstants.ForegroundAspectRatio = .ratio3x4 {
        didSet {
            updateSelectedClipRatio()
            updatePreviewComposition()
        }
    }
    
    @Published public var textSettings: AppConstants.TextOverlaySettings = AppConstants.TextOverlaySettings() {
        didSet {
            updatePreviewComposition()
        }
    }
    
    @Published public var isExporting: Bool = false
    @Published public var exportProgress: Double = 0.0
    @Published public var errorMessage: String?
    @Published public var showErrorAlert: Bool = false
    @Published public var exportSuccessURL: URL?
    @Published public var showSuccessAlert: Bool = false
    
    // Preview AVPlayer State & Observer
    @Published public var player: AVPlayer?
    @Published public var currentTime: Double = 0.0
    @Published public var isPlaying: Bool = true
    @Published public var isMuted: Bool = false
    
    // Services
    private let videoProcessor = VideoProcessorService()
    private let exportManager = ExportManager()
    private var cancellables = Set<AnyCancellable>()
    
    public var currentClip: ClipModel? {
        guard let id = selectedClipID else { return clipQueue.first }
        return clipQueue.first(where: { $0.id == id })
    }
    
    public init() {
        setupCaptionDebounce()
    }
    
    private func setupCaptionDebounce() {
        $captionInput
            .dropFirst()
            .debounce(for: .milliseconds(300), scheduler: DispatchQueue.main)
            .sink { [weak self] _ in
                guard let self = self else { return }
                self.updateSelectedClipCaption()
                self.updatePreviewComposition()
            }
            .store(in: &cancellables)
    }
    
    // Observer tokens
    private var playerLoopObserver: NSObjectProtocol?
    private var timeObserverToken: Any?
    
    private func removePlayerObserver() {
        if let observer = playerLoopObserver {
            NotificationCenter.default.removeObserver(observer)
            playerLoopObserver = nil
        }
        if let token = timeObserverToken, let player = player {
            player.removeTimeObserver(token)
            timeObserverToken = nil
        }
    }
    
    private func setupTimeObserver() {
        if let token = timeObserverToken, let player = player {
            player.removeTimeObserver(token)
            timeObserverToken = nil
        }
        
        guard let player = player else { return }
        let interval = CMTime(seconds: 0.05, preferredTimescale: 600)
        timeObserverToken = player.addPeriodicTimeObserver(forInterval: interval, queue: .main) { [weak self] time in
            let secs = time.seconds
            if !secs.isNaN && !secs.isInfinite {
                Task { @MainActor [weak self] in
                    self?.currentTime = secs
                }
            }
        }
    }
    
    public func seek(to seconds: Double, isScrubbing: Bool = false) {
        guard let player = player else { return }
        let targetTime = CMTime(seconds: max(0, seconds), preferredTimescale: 600)
        Task {
            if isScrubbing {
                let tolerance = CMTime(seconds: 0.08, preferredTimescale: 600)
                await player.seek(to: targetTime, toleranceBefore: tolerance, toleranceAfter: tolerance)
            } else {
                await player.seek(to: targetTime, toleranceBefore: .zero, toleranceAfter: .zero)
            }
        }
        self.currentTime = seconds
    }
    
    public func togglePlayPause() {
        guard let player = player else { return }
        if isPlaying {
            player.pause()
            isPlaying = false
        } else {
            player.play()
            isPlaying = true
        }
    }
    
    public func toggleMute() {
        guard let player = player else { return }
        player.isMuted.toggle()
        isMuted = player.isMuted
    }
    
    // MARK: - Clip Loading
    
    public func loadClips(from urls: [URL]) async {
        for url in urls {
            await loadClip(from: url)
        }
    }
    
    /// Verilen URL'den yeni klip yükleme
    public func loadClip(from url: URL) async {
        let ext = url.pathExtension.lowercased()
        guard AppConstants.SupportedFiles.extensions.contains(ext) else {
            showError("Desteklenmeyen dosya formatı (.\(ext)). Lütfen MP4 veya MOV dosyası seçin.")
            return
        }
        
        let asset = AVURLAsset(url: url)
        
        do {
            let tracks = try await asset.loadTracks(withMediaType: .video)
            guard let videoTrack = tracks.first else {
                showError("Seçilen video dosyasında geçerli bir video kanalı bulunamadı.")
                return
            }
            
            let durationValue = try await asset.load(.duration)
            let durationSeconds = CMTimeGetSeconds(durationValue)
            let naturalSize = try await videoTrack.load(.naturalSize)
            
            guard durationSeconds > 0.3, naturalSize.width > 50, naturalSize.height > 50 else {
                showError("Seçilen video dosyası bozuk veya çok kısa (geçersiz çözünürlük).")
                return
            }
            
            let thumbnail = await generateThumbnail(for: asset)
            
            let newClip = ClipModel(
                fileURL: url,
                duration: durationSeconds,
                naturalSize: naturalSize,
                thumbnail: thumbnail,
                captionText: captionInput,
                foregroundRatio: selectedForegroundRatio,
                status: .ready
            )
            
            self.clipQueue.append(newClip)
            if selectedClipID == nil {
                self.selectedClipID = newClip.id
                await setupPreviewPlayer(with: asset)
            }
            
        } catch {
            showError("Video yüklenirken bir hata oluştu: \(error.localizedDescription)")
        }
    }
    
    public func selectClip(_ id: UUID) {
        self.selectedClipID = id
        if let clip = currentClip {
            self.captionInput = clip.captionText
            self.selectedForegroundRatio = clip.foregroundRatio
            let asset = AVURLAsset(url: clip.fileURL)
            Task {
                await setupPreviewPlayer(with: asset)
            }
        }
    }
    
    @Published public var currentExportIndex: Int = 0
    @Published public var totalExportCount: Int = 0
    
    /// Mevcut caption'ı kuyruktaki TÜM kliplere uygular
    public func applyCaptionToAll() {
        for index in clipQueue.indices {
            clipQueue[index].captionText = captionInput
        }
        updatePreviewComposition()
    }
    
    /// Mevcut ön plan oranını (3:4 / 4:3) kuyruktaki TÜM kliplere uygular
    public func applyRatioToAll() {
        for index in clipQueue.indices {
            clipQueue[index].foregroundRatio = selectedForegroundRatio
        }
        updatePreviewComposition()
    }
    
    /// Belirtilen klibin caption metnini doğrudan günceller
    public func updateClipCaption(id: UUID, newCaption: String) {
        if let index = clipQueue.firstIndex(where: { $0.id == id }) {
            clipQueue[index].captionText = newCaption
            if selectedClipID == id && captionInput != newCaption {
                captionInput = newCaption
            }
            updatePreviewComposition()
        }
    }
    
    /// Belirtilen klibin ön plan oranını (3:4 <-> 4:3) değiştirir
    public func toggleClipRatio(id: UUID) {
        if let index = clipQueue.firstIndex(where: { $0.id == id }) {
            let newRatio: AppConstants.ForegroundAspectRatio = clipQueue[index].foregroundRatio == .ratio3x4 ? .ratio4x3 : .ratio3x4
            clipQueue[index].foregroundRatio = newRatio
            if selectedClipID == id {
                selectedForegroundRatio = newRatio
            }
            updatePreviewComposition()
        }
    }
    
    /// Belirtilen klibi kuyruktan kaldırır
    public func removeClip(_ id: UUID) {
        clipQueue.removeAll(where: { $0.id == id })
        if selectedClipID == id {
            if let first = clipQueue.first {
                selectClip(first.id)
            } else {
                clearCurrentClip()
            }
        }
    }
    
    private func updateSelectedClipCaption() {
        guard let id = selectedClipID, let index = clipQueue.firstIndex(where: { $0.id == id }) else { return }
        if clipQueue[index].captionText != captionInput {
            clipQueue[index].captionText = captionInput
        }
    }
    
    private func updateSelectedClipRatio() {
        guard let id = selectedClipID, let index = clipQueue.firstIndex(where: { $0.id == id }) else { return }
        if clipQueue[index].foregroundRatio != selectedForegroundRatio {
            clipQueue[index].foregroundRatio = selectedForegroundRatio
        }
    }
    
    public func addMoreClips() {
        let panel = NSOpenPanel()
        panel.allowedContentTypes = [.mpeg4Movie, .quickTimeMovie]
        panel.allowsMultipleSelection = true
        panel.canChooseDirectories = false
        panel.canChooseFiles = true
        panel.message = "Oyun klip dosyalarını seçin"
        
        if panel.runModal() == .OK {
            let urls = panel.urls
            Task {
                await loadClips(from: urls)
            }
        }
    }
    
    // MARK: - Preview Player Setup
    
    private func setupPreviewPlayer(with asset: AVAsset) async {
        do {
            let formattedCaption = currentClip?.getFormattedCaption(settings: textSettings) ?? captionInput
            let ratio = currentClip?.foregroundRatio ?? selectedForegroundRatio
            let (composition, videoComp) = try await videoProcessor.createComposition(
                for: asset,
                captionText: formattedCaption,
                foregroundRatio: ratio,
                textSettings: textSettings
            )
            
            let playerItem = AVPlayerItem(asset: composition)
            playerItem.videoComposition = videoComp
            
            if let player = self.player {
                player.replaceCurrentItem(with: playerItem)
            } else {
                self.player = AVPlayer(playerItem: playerItem)
            }
            
            self.player?.actionAtItemEnd = .none
            
            // Eski observer'ı temizle
            removePlayerObserver()
            
            playerLoopObserver = NotificationCenter.default.addObserver(
                forName: .AVPlayerItemDidPlayToEndTime,
                object: playerItem,
                queue: .main
            ) { [weak self] _ in
                Task { @MainActor in
                    self?.player?.seek(to: .zero)
                    self?.player?.play()
                }
            }
            
            self.player?.play()
            self.isPlaying = true
            setupTimeObserver()
        } catch {
            let playerItem = AVPlayerItem(asset: asset)
            self.player = AVPlayer(playerItem: playerItem)
            self.player?.play()
            self.isPlaying = true
            setupTimeObserver()
        }
    }
    
    private func updatePreviewComposition() {
        guard let clip = currentClip, let player = self.player else { return }
        let asset = AVURLAsset(url: clip.fileURL)
        let formattedCaption = clip.getFormattedCaption(settings: textSettings)
        let ratio = clip.foregroundRatio
        let currentSecs = player.currentTime().seconds
        let currentlyPlaying = isPlaying
        
        Task {
            if let (composition, videoComp) = try? await videoProcessor.createComposition(
                for: asset,
                captionText: formattedCaption,
                foregroundRatio: ratio,
                textSettings: textSettings
            ) {
                let playerItem = AVPlayerItem(asset: composition)
                playerItem.videoComposition = videoComp
                player.replaceCurrentItem(with: playerItem)
                if !currentSecs.isNaN && !currentSecs.isInfinite && currentSecs > 0 {
                    let targetTime = CMTime(seconds: currentSecs, preferredTimescale: 600)
                    await player.seek(to: targetTime, toleranceBefore: .zero, toleranceAfter: .zero)
                }
                if currentlyPlaying {
                    player.play()
                }
            }
        }
    }
    
    // MARK: - Export Process (Single & Batch)
    
    public func startExport() async {
        if clipQueue.count > 1 {
            await startBatchExport()
        } else if let clip = currentClip {
            await exportSingleClip(clip)
        }
    }
    
    private func exportSingleClip(_ clip: ClipModel) async {
        let savePanel = NSSavePanel()
        savePanel.allowedContentTypes = [.mpeg4Movie]
        savePanel.canCreateDirectories = true
        
        let defaultName = clip.fileURL.deletingPathExtension().lastPathComponent + "_reels.mp4"
        savePanel.nameFieldStringValue = defaultName
        savePanel.title = "Reels Videonuzu Kaydedin"
        
        guard savePanel.runModal() == .OK, let targetURL = savePanel.url else {
            return
        }
        
        self.isExporting = true
        self.exportProgress = 0.0
        
        let asset = AVURLAsset(url: clip.fileURL)
        let formattedCaption = clip.getFormattedCaption(settings: textSettings)
        let ratio = clip.foregroundRatio
        
        do {
            let (composition, videoComposition) = try await videoProcessor.createComposition(
                for: asset,
                captionText: formattedCaption,
                foregroundRatio: ratio,
                textSettings: textSettings
            )
            
            let finalURL = try await exportManager.exportVideo(
                composition: composition,
                videoComposition: videoComposition,
                outputURL: targetURL
            ) { [weak self] progress in
                Task { @MainActor in
                    self?.exportProgress = progress
                }
            }
            
            self.isExporting = false
            self.exportSuccessURL = finalURL
            self.showSuccessAlert = true
            
        } catch {
            self.isExporting = false
            showError("Export esnasında bir hata oluştu: \(error.localizedDescription)")
        }
    }
    
    private func startBatchExport() async {
        let openPanel = NSOpenPanel()
        openPanel.canChooseFiles = false
        openPanel.canChooseDirectories = true
        openPanel.canCreateDirectories = true
        openPanel.title = "Toplu Export İçin Kayıt Klasörü Seçin"
        
        guard openPanel.runModal() == .OK, let folderURL = openPanel.url else { return }
        
        self.isExporting = true
        self.totalExportCount = clipQueue.count
        
        for (index, clip) in clipQueue.enumerated() {
            self.currentExportIndex = index + 1
            let outputName = clip.fileURL.deletingPathExtension().lastPathComponent + "_reels.mp4"
            let targetURL = folderURL.appendingPathComponent(outputName)
            
            let asset = AVURLAsset(url: clip.fileURL)
            let formattedCaption = clip.getFormattedCaption(settings: textSettings)
            let ratio = clip.foregroundRatio
            
            if let clipIndex = clipQueue.firstIndex(where: { $0.id == clip.id }) {
                clipQueue[clipIndex].status = .processing(progress: 0.0)
            }
            
            do {
                let (composition, videoComposition) = try await videoProcessor.createComposition(
                    for: asset,
                    captionText: formattedCaption,
                    foregroundRatio: ratio,
                    textSettings: textSettings
                )
                
                _ = try await exportManager.exportVideo(
                    composition: composition,
                    videoComposition: videoComposition,
                    outputURL: targetURL
                ) { [weak self] progress in
                    Task { @MainActor in
                        let overallProgress = (Double(index) + progress) / Double(self?.totalExportCount ?? 1)
                        self?.exportProgress = overallProgress
                        if let clipIndex = self?.clipQueue.firstIndex(where: { $0.id == clip.id }) {
                            self?.clipQueue[clipIndex].status = .processing(progress: progress)
                        }
                    }
                }
                
                if let clipIndex = clipQueue.firstIndex(where: { $0.id == clip.id }) {
                    clipQueue[clipIndex].status = .completed(outputURL: targetURL)
                }
                
            } catch {
                if let clipIndex = clipQueue.firstIndex(where: { $0.id == clip.id }) {
                    clipQueue[clipIndex].status = .failed(error: error.localizedDescription)
                }
            }
        }
        
        self.isExporting = false
        self.exportSuccessURL = folderURL
        self.showSuccessAlert = true
    }
    
    private func generateThumbnail(for asset: AVAsset) async -> NSImage? {
        let imageGenerator = AVAssetImageGenerator(asset: asset)
        imageGenerator.appliesPreferredTrackTransform = true
        imageGenerator.maximumSize = CGSize(width: 600, height: 600)
        
        let time = CMTime(seconds: 1.0, preferredTimescale: 600)
        return await withCheckedContinuation { continuation in
            imageGenerator.generateCGImagesAsynchronously(forTimes: [NSValue(time: time)]) { _, cgImage, _, _, _ in
                if let cgImage = cgImage {
                    let nsImage = NSImage(cgImage: cgImage, size: NSSize(width: cgImage.width, height: cgImage.height))
                    continuation.resume(returning: nsImage)
                } else {
                    continuation.resume(returning: nil)
                }
            }
        }
    }
    
    public func clearCurrentClip() {
        removePlayerObserver()
        self.player?.pause()
        self.player = nil
        self.clipQueue.removeAll()
        self.selectedClipID = nil
        self.captionInput = ""
        self.exportProgress = 0.0
        self.isExporting = false
    }
    
    public func showError(_ message: String) {
        self.errorMessage = message
        self.showErrorAlert = true
    }
    
    public func showInFinder(url: URL) {
        NSWorkspace.shared.activateFileViewerSelecting([url])
    }
}
