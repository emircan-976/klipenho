import SwiftUI

public struct ContentView: View {
    @StateObject private var viewModel = MainViewModel()
    
    public init() {}
    
    public var body: some View {
        ZStack {
            AppConstants.Colors.appBackground
                .ignoresSafeArea()
            
            NavigationSplitView {
                // Sol Taraf / Üst Panel: Klip Seçim & Önizleme Alanı
                VStack {
                    if viewModel.currentClip != nil {
                        VideoPreviewView(viewModel: viewModel)
                            .transition(.opacity.combined(with: .scale(scale: 0.96)))
                    } else {
                        DropZoneView(viewModel: viewModel)
                            .transition(.opacity.combined(with: .scale(scale: 0.96)))
                    }
                }
                .animation(.spring(response: 0.35, dampingFraction: 0.8), value: viewModel.currentClip != nil)
                .navigationSplitViewColumnWidth(min: 380, ideal: 460, max: 640)
            } detail: {
                // Sağ Taraf / Detay Paneli: Caption Girişi ve Export Kontrolleri
                ControlsView(viewModel: viewModel) {
                    Task {
                        await viewModel.startExport()
                    }
                }
            }
        }
        .accentColor(AppConstants.Colors.secondaryAccent)
        .frame(minWidth: 920, minHeight: 660)
        .alert("Hata", isPresented: $viewModel.showErrorAlert) {
            Button("Tamam", role: .cancel) {}
        } message: {
            Text(viewModel.errorMessage ?? "Bilinmeyen bir hata oluştu.")
        }
        .alert("Export Başarılı! 🎉", isPresented: $viewModel.showSuccessAlert) {
            if let url = viewModel.exportSuccessURL {
                Button("Finder'da Göster") {
                    viewModel.showInFinder(url: url)
                }
            }
            Button("Kapat", role: .cancel) {}
        } message: {
            Text("Reels videonuz başarıyla dönüştürüldü ve kaydedildi.")
        }
    }
}
