import SwiftUI

public struct BatchQueueView: View {
    @ObservedObject var viewModel: MainViewModel
    
    public init(viewModel: MainViewModel) {
        self.viewModel = viewModel
    }
    
    public var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header Bar
            HStack {
                Label("Klip Kuyruğu (\(viewModel.clipQueue.count))", systemImage: "rectangle.stack.fill")
                    .font(.headline)
                    .foregroundColor(AppConstants.Colors.textPrimary)
                
                Spacer()
                
                // Toplu Editleme & Yönetim Butonları
                HStack(spacing: 8) {
                    Button(action: {
                        viewModel.applyCaptionToAll()
                        viewModel.applyRatioToAll()
                    }) {
                        Label("Tümüne Uygula", systemImage: "wand.and.rays")
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundColor(AppConstants.Colors.slateIndigo)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(AppConstants.Colors.slateIndigo.opacity(0.12))
                            .cornerRadius(6)
                            .overlay(
                                RoundedRectangle(cornerRadius: 6)
                                    .stroke(AppConstants.Colors.slateIndigo.opacity(0.3), lineWidth: 1)
                            )
                    }
                    .buttonStyle(.plain)
                    .cursorHand()
                    
                    Button(action: {
                        viewModel.addMoreClips()
                    }) {
                        Label("Klip Ekle", systemImage: "plus.circle.fill")
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundColor(AppConstants.Colors.textPrimary)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(AppConstants.Colors.inputBackground)
                            .cornerRadius(6)
                            .overlay(
                                RoundedRectangle(cornerRadius: 6)
                                    .stroke(AppConstants.Colors.cardBorder, lineWidth: 1)
                            )
                    }
                    .buttonStyle(.plain)
                    .cursorHand()
                    
                    Button(action: {
                        viewModel.clearCurrentClip()
                    }) {
                        Label("Temizle", systemImage: "trash.fill")
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundColor(Color.red.opacity(0.9))
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.red.opacity(0.12))
                            .cornerRadius(6)
                            .overlay(
                                RoundedRectangle(cornerRadius: 6)
                                    .stroke(Color.red.opacity(0.2), lineWidth: 1)
                            )
                    }
                    .buttonStyle(.plain)
                    .cursorHand()
                }
            }
            
            ScrollView {
                LazyVStack(spacing: 8) {
                    ForEach(viewModel.clipQueue) { clip in
                        BatchClipRowView(
                            clip: clip,
                            isSelected: viewModel.selectedClipID == clip.id,
                            onSelect: {
                                viewModel.selectClip(clip.id)
                            },
                            onRemove: {
                                viewModel.removeClip(clip.id)
                            },
                            onRatioToggle: {
                                viewModel.toggleClipRatio(id: clip.id)
                            },
                            onCaptionChange: { newCaption in
                                viewModel.updateClipCaption(id: clip.id, newCaption: newCaption)
                            },
                            onShowInFinder: { url in
                                viewModel.showInFinder(url: url)
                            }
                        )
                    }
                }
            }
            .frame(maxHeight: min(300, max(120, CGFloat(viewModel.clipQueue.count * 68))))
        }
        .padding(12)
        .background(AppConstants.Colors.cardBackground)
        .cornerRadius(12)
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(AppConstants.Colors.cardBorder, lineWidth: 1))
    }
}

struct BatchClipRowView: View {
    let clip: ClipModel
    let isSelected: Bool
    let onSelect: () -> Void
    let onRemove: () -> Void
    let onRatioToggle: () -> Void
    let onCaptionChange: (String) -> Void
    let onShowInFinder: (URL) -> Void
    
    @State private var localCaption: String = ""
    @FocusState private var isFieldFocused: Bool
    
    var body: some View {
        HStack(spacing: 12) {
            thumbnailView
            
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 6) {
                    Text(clip.fileName)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(AppConstants.Colors.textPrimary)
                        .lineLimit(1)
                    
                    // Tıklanabilir Ratio Badge (3:4 <-> 4:3)
                    Button(action: onRatioToggle) {
                        HStack(spacing: 2) {
                            Text(clip.foregroundRatio.rawValue)
                                .font(.system(size: 10, weight: .bold))
                            Image(systemName: "arrow.triangle.2.circlepath")
                                .font(.system(size: 8))
                        }
                        .foregroundColor(.white)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(AppConstants.Colors.slateIndigo)
                        .cornerRadius(4)
                    }
                    .buttonStyle(.plain)
                    .cursorHand()
                }
                
                // Satır İçi (Inline) Caption Metin Editörü
                HStack(spacing: 4) {
                    Text("POV:")
                        .font(.system(size: 10, weight: .bold, design: .monospaced))
                        .foregroundColor(AppConstants.Colors.slateIndigo)
                    
                    TextField("Caption yazın...", text: $localCaption)
                        .focused($isFieldFocused)
                        .textFieldStyle(.plain)
                        .font(.system(size: 11))
                        .foregroundColor(AppConstants.Colors.textPrimary)
                        .onChange(of: localCaption) { newValue in
                            onCaptionChange(newValue)
                        }
                }
                .padding(.horizontal, 6)
                .padding(.vertical, 3)
                .background(AppConstants.Colors.inputBackground)
                .cornerRadius(4)
                .overlay(
                    RoundedRectangle(cornerRadius: 4)
                        .stroke(isFieldFocused ? AppConstants.Colors.slateIndigo : AppConstants.Colors.cardBorder, lineWidth: 1)
                )
            }
            
            Spacer()
            
            statusView
            
            // Klibi Kuyruktan Kaldırma Butonu
            Button(action: onRemove) {
                Image(systemName: "trash")
                    .font(.caption)
                    .foregroundColor(AppConstants.Colors.textSecondary)
                    .padding(4)
            }
            .buttonStyle(.plain)
            .cursorHand()
        }
        .padding(8)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(isSelected ? AppConstants.Colors.slateIndigo.opacity(0.18) : AppConstants.Colors.inputBackground.opacity(0.4))
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(isSelected ? AppConstants.Colors.slateIndigo : Color.clear, lineWidth: 1.5)
                )
        )
        .contentShape(Rectangle())
        .onTapGesture(perform: onSelect)
        .onAppear {
            localCaption = clip.captionText
        }
        .onChange(of: clip.captionText) { newText in
            if localCaption != newText {
                localCaption = newText
            }
        }
    }
    
    @ViewBuilder
    private var thumbnailView: some View {
        if let thumb = clip.thumbnail {
            Image(nsImage: thumb)
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(width: 44, height: 44)
                .cornerRadius(6)
                .clipped()
        } else {
            RoundedRectangle(cornerRadius: 6)
                .fill(Color.gray.opacity(0.3))
                .frame(width: 44, height: 44)
        }
    }
    
    @ViewBuilder
    private var statusView: some View {
        switch clip.status {
        case .idle, .ready:
            Image(systemName: "clock")
                .foregroundColor(.white.opacity(0.5))
        case .processing(let progress):
            ProgressView(value: progress)
                .frame(width: 36)
                .tint(AppConstants.Colors.secondaryAccent)
        case .completed(let outputURL):
            Button(action: {
                onShowInFinder(outputURL)
            }) {
                HStack(spacing: 4) {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                    Image(systemName: "folder.fill")
                        .font(.caption2)
                        .foregroundColor(AppConstants.Colors.secondaryAccent)
                }
            }
            .buttonStyle(.plain)
            .cursorHand()
        case .failed:
            Image(systemName: "exclamationmark.circle.fill")
                .foregroundColor(.red)
        case .loading:
            ProgressView()
                .controlSize(.small)
        }
    }
}
