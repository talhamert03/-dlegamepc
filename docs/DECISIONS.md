# Teknik Kararlar (Decision Log)

GDD'deki yol haritası uygulanırken alınan kararlar ve nedenleri. Yeni bir geliştirici (insan ya da
yapay zeka) projeye katılmadan önce bu dosyayı okumalı.

## Motor ve pencereler
- **Godot 4.4.1, GL Compatibility.** Eski/entegre GPU'larda da çalışsın, şerit sürekli açık kalacağı için düşük güç tüketimi.
- **Native çoklu pencere** (`embed_subwindows=false`). Her panel ayrı, kenarlıksız, her zaman üstte bir OS penceresi.
- **Ölçek otomatik:** şerit ekran genişliğinin ~%80'ine ve en uzun panel + şerit ekran yüksekliğine sığacak en büyük tam sayı
  (1920x1080/1200 → 3x, 2560x1440 → 4x, 1366x768 → 2x). Pixel art keskin kalsın diye kesirli ölçek yok.
- **Yerleşim:** şerit görev çubuğunun hemen üstünde, ortada. Kahraman grubu (statlar + kahraman + portre) şeridin üstünde ortalı;
  diğer paneller sağda kendi "ev" konumlarında. Açılan panel doluysa en yakın boş yere kayar (portrenin üstü son çare).
  Paneller boş herhangi bir yerinden sürüklenebilir, kenarlara mıknatısla yapışır, ekrandan taşmaz. Kapatılıp açılan panel
  ev konumuna döner ("Panel yerini hatırla" ayarı açılırsa son konumunda açılır).
- **Paneller opak pencere.** Windows + OpenGL'de piksel-şeffaf ikincil pencereler görünmez ve tıklama-geçirgen olabiliyor
  (butonlar "çalışmıyor" gibi görünür); bu yüzden yalnızca ana şerit/başlık penceresi şeffaf.
- **Yerleşik tooltip'ler kapalı** (`gui/timers/tooltip_delay_sec`). Godot'nun tooltip'i native popup penceredir ve açıkken
  yapılan bir sonraki tıklamayı yutar. `WindowManager._route_tooltips` aynı `tooltip_text`'i odak almayan, tıklamayı geçiren kendi
  tooltip penceremizde gösterir.
- Pencere yöneticisi ilk açılışta konumu değiştirebildiği için şerit ve paneller gösterildikten sonra konumlarına yeniden yerleştirilir.
- Odak dışındayken FPS 15'e düşer; tam ekran uygulama algılanınca şerit gizlenir.

## Simülasyon
- Savaş, UI'dan tamamen bağımsız **sabit 0.1 sn tick**'li bir simülasyondur (`BattleSim`). UI sadece `EventBus` sinyallerini dinler.
  Bu sayede testler ve denge botu aynı kodu headless ve hızlandırılmış çalıştırır (`simulate(seconds)`).
- Tüm sayılar `data/*.json` içinde; kod sadece formülleri taşır. Denge ayarı = JSON düzenlemek + botu çalıştırmak.
- Düşman HP/ATK, "referans kahraman" eğrisinden türetilir (`balance.json → ref`). Erken bosslar için yumuşatma faktörü var.
- Denge hedefi: Normal zorluk ≈ 8 saat aktif oyun (bot ölçümü), Kabus ≈ +4 saat, Cehennem uzun kuyruk + Sonsuz Kule.

## Evcil dostlar
- Aktif evcil, partinin arkasında bir `Combatant` (`etype="pet"`) olarak savaşır; hedef alınamaz ve hasar almaz,
  bu yüzden wipe/hedefleme mantığını değiştirmez. Gücü parti ortalamasının %25'i + seviye başına %3.
- Bonusları `GameState.account_mods()` üzerinden tüm statlara akar (lonca ve fraksiyon bonuslarıyla aynı yol).

## Kaydetme
- JSON kayıt + SHA-256 bütünlük kontrolü + `.bak` rotasyonu. Bozuk kayıtta otomatik yedekten dönülür.
- `_migrate()` sürüm yükseltmeleri için tek giriş noktası.

## Sanat
- Telifsiz olması ve tutarlı kalite için **tüm sprite'lar prosedürel**: `tools/art/pixelrig.py` 2.5D iskelet parçaları,
  SDF kubbe gölgelendirme, 7 tonlu renk rampaları, seçici dış hat ve iç kontur çizgileri ile çizer. Tüm kahramanlar
  aynı boru hattından geçtiği için aynı kalitededir. Bir karakteri değiştirmek için `chars.py` içindeki tarifini düzenleyip
  `build_heroes.py <id>` çalıştırmak yeterli.
- Elle çizilmiş pixel art ile değiştirmek istenirse dosya adları ve `anims.json` formatı korunmalı.

## Bilinen sınırlamalar / sonraki adımlar
- **Steam:** `SteamService` şimdilik stub (başarım ve skor çağrıları loglanır). GodotSteam eklentisi eklenince doldurulacak.
- **Kostümler:** 6 hesap çapında kostüm, kahramanın ana renk rampasını shader ile yeniden renklendirir (yeni sprite gerekmez). Kalıp/aksesuar değiştiren kostümler henüz yok.
- macOS export preset'i yok (imzalama/notarization gerektirir).
- Yalnızca TR/EN dil desteği.
