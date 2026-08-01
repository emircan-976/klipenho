import SwiftUI
import AVKit

public struct VideoPreviewView: View {
    @ObservedObject var viewModel: MainViewModel
    @State private var isHovering: Bool = false
    @State private var isDraggingSlider: Bool = false
    @State private var sliderValue: Double = 0.0
    
    public init(viewModel: MainViewModel) {
        self.viewModel = viewModel
    }
    
    public var body: some View {
        VStack(spacing: 14) {
            ZStack {
                // 9:16 Canvas Oranında Siyah Arka Plan Kutusu
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.black)
                    .aspectRatio(9/16, contentMode: .fit)
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(AppConstants.Colors.cardBorder, lineWidth: 1)
                    )
                
                if let player = viewModel.player {
                    VideoPlayerWrapper(player: player)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                        .aspectRatio(9/16, contentMode: .fit)
                        .onTapGesture {
                            viewModel.togglePlayPause()
                        }
                    
                    // Center Hover Play / Pause Overlay Indicator
                    if isHovering || !viewModel.isPlaying {
                        Button(action: {
                            viewModel.togglePlayPause()
                        }) {
                            ZStack {
                                Circle()
                                    .fill(Color.black.opacity(0.65))
                                    .frame(width: 60, height: 60)
                                    .overlay(
                                        Circle()
                                            .stroke(AppConstants.Colors.slateIndigo, lineWidth: 2)
                                    )
                                
                                Image(systemName: viewModel.isPlaying ? "pause.fill" : "play.fill")
                                    .font(.system(size: 24, weight: .bold))
                                    .foregroundColor(AppConstants.Colors.slateIndigo)
                                    .offset(x: viewModel.isPlaying ? 0 : 2)
                            }
                        }
                        .buttonStyle(.plain)
                        .transition(.opacity)
                    }
                } else {
                    VStack(spacing: 12) {
                        ProgressView()
                            .controlSize(.large)
                            .tint(AppConstants.Colors.slateIndigo)
                        Text("Önizleme Yükleniyor...")
                            .font(.subheadline)
                            .foregroundColor(AppConstants.Colors.textSecondary)
                    }
                }
            }
            .frame(maxHeight: 480)
            .onHover { inside in
                withAnimation(.easeInOut(duration: 0.2)) {
                    isHovering = inside
                }
            }
            
            // Oynatıcı Kontrolleri (Zaman Çubuğu, Play/Pause, Mute, Klip Bilgisi)
            if let clip = viewModel.currentClip {
                VStack(spacing: 10) {
                    // Zaman İlerleme Çubuğu (Scrubber Bar)
                    HStack(spacing: 10) {
                        Text(formatTime(isDraggingSlider ? sliderValue : viewModel.currentTime))
                            .font(.system(size: 11, weight: .bold, design: .monospaced))
                            .foregroundColor(AppConstants.Colors.slateIndigo)
                            .frame(width: 44, alignment: .leading)
                        
                        Slider(
                            value: Binding(
                                get: {
                                    isDraggingSlider ? sliderValue : viewModel.currentTime
                                },
                                set: { newValue in
                                    sliderValue = newValue
                                    viewModel.seek(to: newValue, isScrubbing: true)
                                }
                            ),
                            in: 0...max(0.1, clip.duration),
                            onEditingChanged: { editing in
                                isDraggingSlider = editing
                                if !editing {
                                    viewModel.seek(to: sliderValue, isScrubbing: false)
                                }
                            }
                        )
                        .accentColor(AppConstants.Colors.slateIndigo)
                        
                        Text(formatTime(clip.duration))
                            .font(.system(size: 11, weight: .bold, design: .monospaced))
                            .foregroundColor(AppConstants.Colors.textSecondary)
                            .frame(width: 44, alignment: .trailing)
                    }
                    
                    // Alt Kontrol Çubuğu
                    HStack(spacing: 12) {
                        // Play / Pause Button
                        Button(action: {
                            viewModel.togglePlayPause()
                        }) {
                            Image(systemName: viewModel.isPlaying ? "pause.circle.fill" : "play.circle.fill")
                                .font(.system(size: 26, weight: .semibold))
                                .foregroundColor(AppConstants.Colors.slateIndigo)
                        }
                        .buttonStyle(.plain)
                        .cursorHand()
                        
                        // Mute / Unmute Button
                        Button(action: {
                            viewModel.toggleMute()
                        }) {
                            Image(systemName: viewModel.isMuted ? "speaker.slash.fill" : "speaker.wave.2.fill")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(viewModel.isMuted ? Color.red.opacity(0.9) : AppConstants.Colors.textPrimary)
                        }
                        .buttonStyle(.plain)
                        .cursorHand()
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text(clip.fileName)
                                .font(.caption)
                                .fontWeight(.semibold)
                                .foregroundColor(AppConstants.Colors.textPrimary)
                                .lineLimit(1)
                            
                            Text(String(format: "%.0f x %.0f • %.1f sn", clip.naturalSize.width, clip.naturalSize.height, clip.duration))
                                .font(.caption2)
                                .foregroundColor(AppConstants.Colors.textSecondary)
                        }
                        
                        Spacer()
                        
                        // Klibi Kaldır Butonu
                        Button(action: {
                            viewModel.clearCurrentClip()
                        }) {
                            HStack(spacing: 4) {
                                Image(systemName: "trash")
                                Text("Kaldır")
                            }
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundColor(Color.red.opacity(0.9))
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.red.opacity(0.12))
                            .cornerRadius(6)
                        }
                        .buttonStyle(.plain)
                        .cursorHand()
                    }
                }
                .padding(12)
                .background(AppConstants.Colors.cardBackground)
                .cornerRadius(14)
                .overlay(RoundedRectangle(cornerRadius: 14).stroke(AppConstants.Colors.cardBorder, lineWidth: 1))
            }
        }
        .padding(16)
    }
    
    private func formatTime(_ seconds: Double) -> String {
        guard !seconds.isNaN && !seconds.isInfinite else { return "00:00" }
        let totalSecs = Int(seconds)
        let mins = totalSecs / 60
        let secs = totalSecs % 60
        return String(format: "%02d:%02d", mins, secs)
    }
}

// NSViewRepresentable Wrapper for AVPlayerView
struct VideoPlayerWrapper: NSViewRepresentable {
    let player: AVPlayer
    
    func makeNSView(context: Context) -> AVPlayerView {
        let playerView = AVPlayerView()
        playerView.player = player
        playerView.controlsStyle = .none
        playerView.videoGravity = .resizeAspect
        return playerView
    }
    
    func updateNSView(_ nsView: AVPlayerView, context: Context) {
        nsView.player = player
    }
}
