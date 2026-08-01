import SwiftUI
import UniformTypeIdentifiers
import AppKit

public struct DropZoneView: View {
    @ObservedObject var viewModel: MainViewModel
    @State private var isTargeted: Bool = false
    @State private var isButtonHovered: Bool = false
    @State private var pulseAnimation: Bool = false
    
    public init(viewModel: MainViewModel) {
        self.viewModel = viewModel
    }
    
    public var body: some View {
        VStack(spacing: 24) {
            ZStack {
                // Flat Pro-Tool Card Container with Clean Stroke
                RoundedRectangle(cornerRadius: 16)
                    .fill(isTargeted ? AppConstants.Colors.slateIndigo.opacity(0.08) : AppConstants.Colors.cardBackground)
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .strokeBorder(
                                isTargeted ? AppConstants.Colors.slateIndigo : AppConstants.Colors.cardBorder,
                                style: StrokeStyle(
                                    lineWidth: isTargeted ? 2 : 1,
                                    dash: isTargeted ? [8, 5] : []
                                )
                            )
                    )
                
                VStack(spacing: 22) {
                    // Clean Solid Upload Icon Badge
                    ZStack {
                        Circle()
                            .fill(AppConstants.Colors.slateIndigo.opacity(0.12))
                            .frame(width: 80, height: 80)
                            .overlay(
                                Circle()
                                    .stroke(AppConstants.Colors.slateIndigo.opacity(0.3), lineWidth: 1)
                            )
                        
                        Image(systemName: isTargeted ? "arrow.down.doc.fill" : "video.badge.plus")
                            .font(.system(size: 34, weight: .semibold))
                            .foregroundColor(AppConstants.Colors.slateIndigo)
                            .scaleEffect(isTargeted ? 1.08 : 1.0)
                            .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isTargeted)
                    }
                    
                    VStack(spacing: 6) {
                        Text(isTargeted ? "Klipleri Buraya Bırakın!" : "Oyun Kliplerinizi Buraya Sürükleyin")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(AppConstants.Colors.textPrimary)
                        
                        Text("Tek bir klip veya aynı anda birden fazla oyun klibi sürükleyebilirsiniz")
                            .font(.system(size: 13, weight: .regular))
                            .foregroundColor(AppConstants.Colors.textSecondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 16)
                    }
                    
                    // Solid Slate Indigo Button
                    Button(action: selectFile) {
                        HStack(spacing: 8) {
                            Image(systemName: "folder.fill.badge.plus")
                                .font(.system(size: 14, weight: .semibold))
                            Text("Klip Seç (Tekli veya Toplu)")
                                .font(.system(size: 14, weight: .bold))
                        }
                        .padding(.horizontal, 20)
                        .padding(.vertical, 10)
                        .background(AppConstants.Colors.slateIndigo)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                        .scaleEffect(isButtonHovered ? 1.02 : 1.0)
                        .animation(.spring(response: 0.2, dampingFraction: 0.8), value: isButtonHovered)
                    }
                    .buttonStyle(.plain)
                    .onHover { inside in
                        isButtonHovered = inside
                    }
                    .cursorHand()
                    
                    // Desteklenen Format Badges
                    HStack(spacing: 8) {
                        formatChip(title: "MP4 / MOV", icon: "video.fill")
                        formatChip(title: "Toplu Yükleme", icon: "square.stack.3d.up.fill")
                        formatChip(title: "1080x1920 9:16", icon: "iphone")
                    }
                    .padding(.top, 4)
                }
                .padding(32)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .onDrop(of: [.fileURL], isTargeted: $isTargeted) { providers in
                handleDrop(providers: providers)
            }
            .onChange(of: isTargeted) { targeted in
                pulseAnimation = targeted
            }
        }
        .padding(24)
    }
    
    // MARK: - Format Chip View Builder
    @ViewBuilder
    private func formatChip(title: String, icon: String) -> some View {
        HStack(spacing: 5) {
            Image(systemName: icon)
                .font(.system(size: 10, weight: .semibold))
                .foregroundColor(AppConstants.Colors.slateIndigo)
            Text(title)
                .font(.system(size: 11, weight: .medium))
                .foregroundColor(AppConstants.Colors.textSecondary)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 5)
        .background(AppConstants.Colors.inputBackground)
        .cornerRadius(6)
        .overlay(
            RoundedRectangle(cornerRadius: 6)
                .stroke(AppConstants.Colors.cardBorder, lineWidth: 1)
        )
    }
    
    // MARK: - Handlers
    
    private func selectFile() {
        let panel = NSOpenPanel()
        panel.allowedContentTypes = [.mpeg4Movie, .quickTimeMovie]
        panel.allowsMultipleSelection = true
        panel.canChooseDirectories = false
        panel.canChooseFiles = true
        panel.message = "Bir veya birden fazla oyun video klibi seçin"
        
        if panel.runModal() == .OK {
            let urls = panel.urls
            Task {
                await viewModel.loadClips(from: urls)
            }
        }
    }
    
    private func handleDrop(providers: [NSItemProvider]) -> Bool {
        guard !providers.isEmpty else { return false }
        
        let group = DispatchGroup()
        var droppedURLs: [URL] = []
        let lock = NSLock()
        
        for provider in providers {
            group.enter()
            provider.loadItem(forTypeIdentifier: UTType.fileURL.identifier, options: nil) { item, _ in
                defer { group.leave() }
                if let data = item as? Data,
                   let url = URL(dataRepresentation: data, relativeTo: nil) {
                    lock.lock()
                    droppedURLs.append(url)
                    lock.unlock()
                }
            }
        }
        
        group.notify(queue: .main) {
            guard !droppedURLs.isEmpty else { return }
            Task { @MainActor in
                await viewModel.loadClips(from: droppedURLs)
            }
        }
        return true
    }
}
