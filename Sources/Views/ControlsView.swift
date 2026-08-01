import SwiftUI

public struct ControlsView: View {
    @ObservedObject var viewModel: MainViewModel
    var onExportRequested: () -> Void
    
    @FocusState private var isCaptionFocused: Bool
    
    public init(viewModel: MainViewModel, onExportRequested: @escaping () -> Void) {
        self.viewModel = viewModel
        self.onExportRequested = onExportRequested
    }
    
    public var body: some View {
        ScrollView(.vertical, showsIndicators: true) {
            VStack(alignment: .leading, spacing: 16) {
                // Toplu Klip Listesi (Eğer birden fazla klip yüklendiyse)
                if viewModel.clipQueue.count > 1 {
                    BatchQueueView(viewModel: viewModel)
                }
                
                // Caption Metin Girişi Paneli
                VStack(alignment: .leading, spacing: 10) {
                    HStack {
                        Label("Reels / TikTok Metni (Caption)", systemImage: "text.bubble.fill")
                            .font(.headline)
                            .foregroundColor(.white)
                        
                        Spacer()
                        
                        if !viewModel.captionInput.isEmpty {
                            Button(action: {
                                viewModel.captionInput = ""
                            }) {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundColor(.white.opacity(0.6))
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    
                    Text("Videonun üst dikey kısmına başlık kutusu olarak eklenecektir.")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.6))
                    
                    HStack(spacing: 6) {
                        // Prefix Toggle Button & Custom Prefix Input
                        Button(action: {
                            viewModel.textSettings.showPrefix.toggle()
                        }) {
                            HStack(spacing: 4) {
                                Image(systemName: viewModel.textSettings.showPrefix ? "checkmark.circle.fill" : "circle")
                                    .font(.system(size: 11))
                                Text("Ön Ek")
                                    .font(.system(.caption, design: .monospaced))
                                    .fontWeight(.bold)
                            }
                            .foregroundColor(viewModel.textSettings.showPrefix ? AppConstants.Colors.slateIndigo : AppConstants.Colors.textSecondary)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 8)
                            .background(viewModel.textSettings.showPrefix ? AppConstants.Colors.slateIndigo.opacity(0.15) : AppConstants.Colors.inputBackground)
                            .cornerRadius(8)
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(viewModel.textSettings.showPrefix ? AppConstants.Colors.slateIndigo.opacity(0.4) : AppConstants.Colors.cardBorder, lineWidth: 1)
                            )
                        }
                        .buttonStyle(.plain)
                        .cursorHand()
                        
                        if viewModel.textSettings.showPrefix {
                            TextField("POV: ", text: $viewModel.textSettings.prefixText)
                                .textFieldStyle(.plain)
                                .font(.system(size: 12, weight: .bold, design: .monospaced))
                                .foregroundColor(AppConstants.Colors.slateIndigo)
                                .frame(width: 68)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 7)
                                .background(AppConstants.Colors.inputBackground)
                                .cornerRadius(6)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 6)
                                        .stroke(AppConstants.Colors.slateIndigo.opacity(0.4), lineWidth: 1)
                                )
                        }
                        
                        TextField("örn. Tek başıma 1v4 attım...", text: $viewModel.captionInput)
                            .focused($isCaptionFocused)
                            .textFieldStyle(.plain)
                            .font(.system(size: 14, weight: .regular))
                            .foregroundColor(AppConstants.Colors.textPrimary)
                            .padding(10)
                            .background(AppConstants.Colors.inputBackground)
                            .cornerRadius(8)
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(isCaptionFocused ? AppConstants.Colors.slateIndigo : AppConstants.Colors.cardBorder, lineWidth: isCaptionFocused ? 1.5 : 1)
                            )
                            .contentShape(Rectangle())
                            .onTapGesture {
                                isCaptionFocused = true
                            }
                    }
                    .padding(4)
                    .background(AppConstants.Colors.inputBackground.opacity(0.5))
                    .cornerRadius(10)
                    
                    // Hazır Klip Caption Şablon Butonları (Quick Templates)
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Hazır Klip Şablonları:")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundColor(AppConstants.Colors.textSecondary)
                        
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 6) {
                                quickTemplateChip(text: "Tek başıma 1v4 attım 🔥")
                                quickTemplateChip(text: "Sondaki sniper atışı 🎯")
                                quickTemplateChip(text: "Son anda inanılmaz clutch 🏆")
                                quickTemplateChip(text: "Yeni sezonda ilk zafer 👑")
                            }
                        }
                    }
                    .padding(.top, 4)
                }
                .padding(16)
                .background(AppConstants.Colors.cardBackground)
                .cornerRadius(14)
                .overlay(RoundedRectangle(cornerRadius: 14).stroke(AppConstants.Colors.cardBorder, lineWidth: 1))
                .onTapGesture {
                    isCaptionFocused = true
                }
                
                // Gelişmiş Metin & Font Stili Paneli
                VStack(alignment: .leading, spacing: 12) {
                    Label("Metin Stili & Font Ayarları", systemImage: "paintpalette.fill")
                        .font(.headline)
                        .foregroundColor(AppConstants.Colors.textPrimary)
                    
                    // Font Ailesi Seçici
                    HStack {
                        Text("Font:")
                            .font(.subheadline)
                            .foregroundColor(AppConstants.Colors.textSecondary)
                        Spacer()
                        Picker("Font Ailesi", selection: $viewModel.textSettings.fontName) {
                            ForEach(AppConstants.AvailableFonts.list, id: \.name) { fontItem in
                                Text(fontItem.displayName).tag(fontItem.name)
                            }
                        }
                        .pickerStyle(.menu)
                        .accentColor(AppConstants.Colors.slateIndigo)
                    }
                    
                    Divider()
                        .background(AppConstants.Colors.cardBorder)
                    
                    // Font Boyutu Slider
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Text("Font Boyutu:")
                                .font(.caption)
                                .foregroundColor(AppConstants.Colors.textSecondary)
                            Spacer()
                            Text("\(Int(viewModel.textSettings.fontSize)) pt")
                                .font(.caption)
                                .fontWeight(.bold)
                                .monospacedDigit()
                                .foregroundColor(AppConstants.Colors.slateIndigo)
                        }
                        
                        Slider(
                            value: $viewModel.textSettings.fontSize,
                            in: 28...60,
                            step: 2
                        )
                        .accentColor(AppConstants.Colors.slateIndigo)
                    }
                    
                    Divider()
                        .background(AppConstants.Colors.cardBorder)
                    
                    // Siyah Kutu Saydamlık / Opaklık Slider
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Text("Kutu Opaklığı:")
                                .font(.caption)
                                .foregroundColor(AppConstants.Colors.textSecondary)
                            Spacer()
                            Text(String(format: "%%%0.0f", viewModel.textSettings.boxAlpha * 100))
                                .font(.caption)
                                .fontWeight(.bold)
                                .monospacedDigit()
                                .foregroundColor(AppConstants.Colors.slateIndigo)
                        }
                        
                        Slider(
                            value: $viewModel.textSettings.boxAlpha,
                            in: 0.0...1.0,
                            step: 0.05
                        )
                        .accentColor(AppConstants.Colors.slateIndigo)
                    }
                    
                    Divider()
                        .background(AppConstants.Colors.cardBorder)
                    
                    // Dikey Konum (Y-Offset) Slider
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Text("Dikey Metin Konumu (Üstten Y-Offset):")
                                .font(.caption)
                                .foregroundColor(AppConstants.Colors.textSecondary)
                            Spacer()
                            Text("\(Int(viewModel.textSettings.topOffset)) px")
                                .font(.caption)
                                .fontWeight(.bold)
                                .monospacedDigit()
                                .foregroundColor(AppConstants.Colors.slateIndigo)
                        }
                        
                        Slider(
                            value: $viewModel.textSettings.topOffset,
                            in: 30.0...450.0,
                            step: 5.0
                        )
                        .accentColor(AppConstants.Colors.slateIndigo)
                    }
                }
                .padding(16)
                .background(AppConstants.Colors.cardBackground)
                .cornerRadius(14)
                .overlay(RoundedRectangle(cornerRadius: 14).stroke(AppConstants.Colors.cardBorder, lineWidth: 1))
                
                // Ön Plan Oranı Seçimi Paneli
                VStack(alignment: .leading, spacing: 10) {
                    Label("Ön Plan Video Oranı", systemImage: "aspectratio")
                        .font(.headline)
                        .foregroundColor(AppConstants.Colors.textPrimary)
                    
                    Picker("Ön Plan Oranı", selection: $viewModel.selectedForegroundRatio) {
                        ForEach(AppConstants.ForegroundAspectRatio.allCases) { ratio in
                            Text(ratio.rawValue == "3:4" ? "3:4 Dikey Crop (1080x1440)" : "4:3 Yatay Crop (1080x810)").tag(ratio)
                        }
                    }
                    .pickerStyle(.segmented)
                }
                .padding(16)
                .background(AppConstants.Colors.cardBackground)
                .cornerRadius(14)
                .overlay(RoundedRectangle(cornerRadius: 14).stroke(AppConstants.Colors.cardBorder, lineWidth: 1))
                
                // Format & Ayar Özeti
                VStack(alignment: .leading, spacing: 10) {
                    Text("Dönüştürme Formatı")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(AppConstants.Colors.textSecondary)
                    
                    Grid(alignment: .leading, horizontalSpacing: 12, verticalSpacing: 6) {
                        GridRow {
                            Text("Çözünürlük:")
                                .foregroundColor(AppConstants.Colors.textSecondary)
                            Text("1080 x 1920 (9:16 Vertical)")
                                .fontWeight(.medium)
                                .foregroundColor(AppConstants.Colors.textPrimary)
                        }
                        GridRow {
                            Text("Ön Plan:")
                                .foregroundColor(AppConstants.Colors.textSecondary)
                            Text("\(viewModel.selectedForegroundRatio.rawValue) Crop (\(Int(viewModel.selectedForegroundRatio.width))x\(Int(viewModel.selectedForegroundRatio.height)) Ortalanmış)")
                                .fontWeight(.medium)
                                .foregroundColor(AppConstants.Colors.textPrimary)
                        }
                        GridRow {
                            Text("Arka Plan:")
                                .foregroundColor(AppConstants.Colors.textSecondary)
                            Text("Gaussian Blur (CIGaussianBlur)")
                                .fontWeight(.medium)
                                .foregroundColor(AppConstants.Colors.textPrimary)
                        }
                    }
                    .font(.caption)
                }
                .padding(16)
                .background(AppConstants.Colors.cardBackground)
                .cornerRadius(14)
                .overlay(RoundedRectangle(cornerRadius: 14).stroke(AppConstants.Colors.cardBorder, lineWidth: 1))
                
                Spacer(minLength: 12)
                
                // Export Durumu ve Butonu
                VStack(spacing: 12) {
                    if viewModel.isExporting {
                        VStack(spacing: 8) {
                            HStack {
                                Text(viewModel.clipQueue.count > 1 ? "Toplu Export (\(viewModel.currentExportIndex)/\(viewModel.totalExportCount))" : "Video İşleniyor...")
                                    .font(.subheadline)
                                    .fontWeight(.semibold)
                                    .foregroundColor(AppConstants.Colors.textPrimary)
                                Spacer()
                                Text(String(format: "%%%.0f", viewModel.exportProgress * 100))
                                    .font(.subheadline)
                                    .monospacedDigit()
                                    .foregroundColor(AppConstants.Colors.slateIndigo)
                            }
                            
                            ProgressView(value: viewModel.exportProgress, total: 1.0)
                                .progressViewStyle(.linear)
                                .tint(AppConstants.Colors.slateIndigo)
                        }
                        .padding(12)
                        .background(AppConstants.Colors.slateIndigo.opacity(0.12))
                        .cornerRadius(10)
                        .overlay(
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(AppConstants.Colors.slateIndigo.opacity(0.3), lineWidth: 1)
                        )
                    }
                    
                    Button(action: onExportRequested) {
                        HStack(spacing: 8) {
                            if viewModel.isExporting {
                                ProgressView()
                                    .controlSize(.small)
                            } else {
                                Image(systemName: "square.and.arrow.up.fill")
                            }
                            
                            Text(viewModel.isExporting ? "Dışa Aktarılıyor..." : (viewModel.clipQueue.count > 1 ? "Tüm Klipleri Toplu Export Et (\(viewModel.clipQueue.count))" : "Reels Videosunu Export Et (9:16)"))
                                .font(.system(size: 14, weight: .bold))
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(viewModel.isExporting ? Color.gray.opacity(0.3) : AppConstants.Colors.slateIndigo)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                    }
                    .buttonStyle(.plain)
                    .disabled(viewModel.isExporting || viewModel.currentClip == nil)
                    .cursorHand()
                }
            }
            .padding(20)
            .frame(maxWidth: .infinity, alignment: .topLeading)
        }
    }
    
    // MARK: - Quick Template Chip Builder
    @ViewBuilder
    private func quickTemplateChip(text: String) -> some View {
        Button(action: {
            viewModel.captionInput = text
        }) {
            Text(text)
                .font(.system(size: 11, weight: .medium))
                .foregroundColor(AppConstants.Colors.textPrimary)
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
                .background(AppConstants.Colors.inputBackground)
                .cornerRadius(6)
                .overlay(
                    RoundedRectangle(cornerRadius: 6)
                        .stroke(AppConstants.Colors.cardBorder, lineWidth: 1)
                )
        }
        .buttonStyle(.plain)
        .cursorHand()
    }
}
