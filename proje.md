# PROJE: Klipenho - Oyun Klipleri Reels / TikTok Otomasyonu (macOS)

## Genel Amaç
Tüm tam ekran oyun kliplerini (Fortnite, Valorant, GTA, CoD, CS2 vb.) Instagram Reels / TikTok formatına otomatik dönüştüren native bir macOS uygulaması (Klipenho). Kullanıcı ham bir klip sürükler, bir caption metni girer, "Export" der ve dikey (9:16) formatta, ortalanmış, blurlu arka planlı, üstte "POV: ..." yazılı, paylaşıma hazır bir video elde eder.

Şu anda bu işi manuel olarak CapCut'ta yapıyorum. Bu uygulama o manuel süreci tamamen otomatikleştirmeli.

## Fonksiyonel Gereksinimler (Uygulamanın Yapması Gerekenler)

1. **Klip içe aktarma**
   - Kullanıcı bir video dosyasını (mp4/mov) sürükle-bırak ile veya dosya seçici ile içeri aktarabilmeli.
   - İçeri aktarılan klibin canlı önizlemesi (thumbnail veya oynatılabilir preview) gösterilmeli.

2. **Otomatik dikey format dönüşümü (canvas)**
   - Çıkış her zaman 1080x1920 (9:16) olacak.
   - Bu, kullanıcı ayarlamasına gerek olmadan otomatik uygulanmalı.

3. **Ön plan (foreground) — 3:4 crop + ortalama**
   - Orijinal klip merkezden 3:4 en-boy oranına crop edilecek (kenarlardan kırpılarak).
   - Bu crop edilmiş görüntü 1080 genişlik x 1440 yükseklik olacak şekilde scale edilip, 1920 yüksekliğindeki canvasın tam ortasına (dikeyde ortalanmış) yerleştirilecek.
   - Üstte ve altta yaklaşık 240px'lik boşluk kalacak.

4. **Arka plan (background) — blur**
   - Üstte/altta kalan boşluklar boş/siyah olmayacak.
   - Arka plan, orijinal klibin kendisinden üretilecek: klip 1080x1920'yi tam kaplayacak şekilde scale + crop edilip üzerine gaussian blur uygulanacak.
   - Ön plan bu blurlu arka planın üzerine ortalanmış şekilde overlay edilecek.

5. **Caption / metin overlay**
   - Kullanıcı her klip için serbest metin girebileceği bir text field görecek.
   - Girilen metin otomatik olarak "POV: {kullanıcının yazdığı metin}" formatında videonun üst kısmına (üstteki blur alanın içine) bindirilecek.
   - Font, font boyutu, renk ve arka plan kutusu (yarı saydam siyah box) sabit/varsayılan olacak ama kod içinde kolayca değiştirilebilir sabitler olarak tanımlanmalı.

6. **Export**
   - "Export" butonuna basınca video işlenip kullanıcının seçtiği bir klasöre kaydedilmeli.
   - İşlem sırasında bir progress indicator gösterilmeli.
   - Export tamamlandığında dosyanın bulunduğu klasörü Finder'da açma opsiyonu olmalı.

7. **(İleri faz — opsiyonel) Toplu (batch) işleme**
   - Kullanıcı birden fazla klip ekleyip her biri için ayrı caption yazıp hepsini tek seferde export edebilmeli.
   - Bu bir liste/tablo UI'ı ile yönetilmeli (klip adı + caption + status sütunları).

## Teknik Gereksinimler

- **Platform:** macOS (13.0+ hedeflensin, en son Swift/SwiftUI sürümü kullanılsın).
- **UI Framework:** SwiftUI.
- **Video işleme:** Öncelikli olarak native **AVFoundation + Core Image (CIFilter, özellikle CIGaussianBlur)** kullanarak `AVMutableComposition` + `AVVideoComposition` (custom compositor) üzerinden işlensin — böylece harici bağımlılık (ffmpeg binary bundle etme, notarization sorunları vs.) olmaz.
  - Eğer bu yaklaşım karmaşıklaşırsa, alternatif olarak sistemde kurulu FFmpeg'i (`/opt/homebrew/bin/ffmpeg` veya kullanıcının belirttiği path) subprocess olarak çağırma seçeneğini de değerlendirilebilir ama bu ikinci öncelik olsun.
- **Metin overlay:** Core Image / Core Animation üzerinden (CATextLayer + AVVideoComposition ile) yapılmalı, native ve performanslı olsun.
- **Proje yapısı:** Temiz, modüler bir mimari (örn. `VideoProcessor`, `ExportManager`, `ClipModel`, `ContentView` gibi ayrılmış dosyalar). MVVM tercih edilsin.
- **Hata yönetimi:** Yanlış formatlı dosya, işlenemeyen video, disk alanı hatası gibi durumlarda kullanıcıya anlaşılır hata mesajı gösterilmeli, uygulama çökmemeli.
- **Performans:** Önizleme deneyimi akıcı olmalı, export işlemi UI thread'ini bloklamamalı (async/await veya background queue kullanılmalı).

## Senden İstediğim İlk Adım

Kod yazmaya başlamadan önce, bu projeyi yönetebilmem için bana **PROGRESS.md** adında bir dosya oluştur. Bu dosya:

- Projeyi mantıklı, küçük ve tek tek tamamlanabilir **fazlara (aşamalara)** bölmeli (örneğin: Faz 0 - Proje Kurulumu, Faz 1 - Temel UI ve Klip İçe Aktarma, Faz 2 - Video İşleme Pipeline'ı, Faz 3 - Caption Overlay, Faz 4 - Export ve Dosya Yönetimi, Faz 5 - Cilalama/Test/Hata Yönetimi, Faz 6 - (opsiyonel) Toplu İşleme — sen bunu ihtiyaca göre daha fazla/az fazlara bölebilirsin).
- Her fazın altında, o fazda tamamlanması gereken **somut, atomik görevleri** Markdown checklist formatında (`- [ ] görev`) listelemeli. Görevler yeterince küçük olmalı ki her biri tek oturumda tamamlanabilsin.
- Hiçbir teknik detayı atlamadan yaz — örneğin "video işleme pipeline'ı kur" gibi genel bir görev yerine, "AVMutableComposition oluştur", "custom AVVideoCompositor sınıfı yaz", "CIGaussianBlur filtresini background track'e uygula", "foreground'u 3:4 crop'la" gibi alt görevlere böl.
- Dosyanın en üstünde projenin kısa özeti ve genel mimari notları da olsun.
- Bu dosyayı, ilerledikçe kutucukları işaretleyerek (`- [x]`) takip edebileceğim şekilde düzenli tut.

PROGRESS.md'yi oluşturduktan sonra bana göster, onayımı al, sonra Faz 0'dan başlayarak kod yazmaya geç. Her fazı tamamladığında PROGRESS.md'deki ilgili kutucukları işaretle ve bana hangi fazı tamamladığını özetle.
