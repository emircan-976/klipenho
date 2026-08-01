# Klipenho - Oyun Klipleri Reels Otomasyon Uygulaması - İlerleme ve Görev Takibi (PROGRESS.md)

## 📌 Proje Özeti
Bu proje, tüm tam ekran oyun kliplerini (Fortnite, Valorant, GTA vb.) otomatik olarak Instagram Reels / TikTok formatına (9:16, 1080x1920) dönüştüren native bir macOS uygulamasıdır (Klipenho). 
Uygulama, ham video kliplerini alıp arka planda blurlu tam ekran görüntü, ön planda 3:4 (1080x1440) crop edilmiş ortalı video ve üst kısımda yarı saydam siyah kutu içinde "POV: ..." metni ile hazır video çıktısı üretir.

## 🏗 Mimari ve Teknolojik Seçimler
- **Platform & UI:** macOS 13.0+, Swift, SwiftUI (MVVM Pattern).
- **Video İşleme:** AVFoundation (`AVMutableComposition`, `AVVideoComposition`), Core Image (`CIGaussianBlur`), Core Animation (`CALayer`, `CATextLayer`).
- **Performans:** Modern Swift Concurrency (`async/await`, `@MainActor`, `Task`), background queue video işleme ve export.

---

## 🚀 Fazlar ve Atomik Görev Checklist'i

### 🔹 Faz 0: Proje Kurulumu ve Temel Mimari Altyapı
- [x] macOS SwiftUI projesinin oluşturulması ve proje dizin yapısının düzenlenmesi.
- [x] Klasör mimarisinin kurulması (`Models`, `ViewModels`, `Services`, `Views`, `Utilities`).
- [x] `AppConstants.swift` dosyasının oluşturulması (Canvas: 1080x1920, Foreground Crop: 1080x1440, Blur Radius: 30, Metin Stilleri vb. sabitler).
- [x] Klip verilerini ve işleme durumunu temsil eden `ClipModel.swift` veri modelinin yazılması.
- [x] Uygulama genel durumunu ve seçilen klipleri yöneten `MainViewModel.swift` taslağının oluşturulması.

### 🔹 Faz 1: UI Tasarımı & Klip İçe Aktarma
- [x] Sürükle-Bırak (`.onDrop`) ve Dosya Seçici (`NSOpenPanel`) destekli `DropZoneView` bileşeninin oluşturulması.
- [x] Yüklenen video dosyasının format/validasyon kontrollerinin yapılması (MP4/MOV doğrulaması, süre ve çözünürlük alımı).
- [x] `AVPlayer` tabanlı canlı video önizleme bileşeninin (`VideoPreviewView`) yazılması.
- [x] Caption (metin) girişi için `TextEditor` / `TextField` bileşeninin UI'a yerleştirilmesi.
- [x] Klip temizleme, yeni klip seçme ve UI durum (Idle, Loaded, Processing, Completed) geçişlerinin bağlanması.

### 🔹 Faz 2: Core Video İşleme Pipeline'ı (AVFoundation + Core Image)
- [x] `VideoProcessorService.swift` servisinin oluşturulması.
- [x] `AVMutableComposition` ile ses ve video track'lerinin orijinal kaynaktan aktarılması.
- [x] Background Katmanı Transformu: Videoyu 1080x1920 boyutuna Aspect Fill ölçekleme ve merkezleme transform matrisinin hesaplanması.
- [x] Foreground Katmanı Transformu: Videoyu 3:4 oranında (1080x1440) merkezden crop edip canvas ortasına (y: 240) yerleştirme transform matrisinin hesaplanması.
- [x] Custom `AVVideoComposition` veya `CIFilter` tabanlı composition handler yazılması (`CIGaussianBlur` ile arka plana blur uygulanması).
- [x] Core Image compositing ile blurlu arka plan ve crop ön planın birleştirilerek tek 1080x1920 karesi üretilmesi.
- [x] `AVPlayer` canlı önizlemesine `AVVideoComposition` bağlayarak real-time blurlu & crop'lu önizlemenin doğrulanması.

### 🔹 Faz 3: Caption / Metin Overlay Katmanı
- [x] `TextOverlayRenderer.swift` servisinin oluşturulması.
- [x] "POV: {girilen_metin}" string biçimlendirmesinin ve dinamik satır katlama (word wrap) mantığının yazılması.
- [x] Metin arka planına yarı saydam yuvarlatılmış siyah box (pill/rounded rectangle layer) çizimi.
- [x] Core Animation (`CALayer`, `CATextLayer`) veya Core Image text rendering ile `AVVideoComposition.animationTool` entegrasyonu.
- [x] Metnin 1080x1920 canvas üzerinde dikey ve yatay olarak üst boşluğa (y: ~100-200px) hassas şekilde ortalanması.
- [x] Metin fontu, boyutu, rengi ve kutu padding parametrelerinin `AppConstants` üzerinden dinamik beslenmesi.

### 🔹 Faz 4: Export Manager ve Dosya Yönetimi
- [x] `ExportManager.swift` servisinin oluşturulması (`AVAssetExportSession` wrapper).
- [x] Non-blocking async background export iş akışının yazılması (`AVAssetExportPresetHighestQuality` veya `H.264 / AAC`).
- [x] Gerçek zamanlı export progress (0% - 100%) ve durum bilgilerinin `MainViewModel`'e aktarılması.
- [x] Dosya kaydetme diyaloğu (`NSSavePanel`) veya varsayılan indirme/kayıt klasörü seçimi.
- [x] Export tamamlandığında "Finder'da Göster" (`NSWorkspace.shared.activateFileViewerSelecting`) entegrasyonu.
- [x] Export iptal mekanizmasının (`exportSession.cancelExport()`) eklenmesi.

### 🔹 Faz 5: Cilalama, Hata Yönetimi & Testler
- [x] Kapsamlı hata yönetimi (Geçersiz format, yetersiz disk alanı, export hatası için macOS alert dialogs).
- [x] UI/UX Cilalama (Glassmorphism / Translucent macOS tasarımı, akıcı animasyonlar, buton efektleri).
- [x] Bellek ve performans optimizasyonu (`CIContext` tekrar kullanımı, bellek sızıntısı önleme).
- [x] Çeşitli çözünürlükteki videolarla (1080p, 4K, 60fps) uçtan uca testler ve doğrulama.

### 🔹 Faz 6: Toplu (Batch) İşleme
- [x] Birden fazla klip ekleme ve yönetme destekli Klip Listesi (Batch Queue) UI'ı (`BatchQueueView.swift`).
- [x] Her klip için bağımsız metin/caption girme ve düzenleme tablosu.
- [x] Sıralı Batch Export yöneticisi (`MainViewModel` batch export iş akışı).
- [x] Batch durum göstergeleri (Bekliyor, İşleniyor, Başarılı, Başarısız).
