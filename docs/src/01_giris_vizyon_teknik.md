# 0. Bu Doküman Nasıl Kullanılır (Yapay Zeka İçin Talimat)

Bu doküman, **IDLE PARTY: Desktop Legends** (çalışma adı) adlı masaüstü widget tarzı idle-RPG oyununun eksiksiz Oyun Tasarım Dokümanı (GDD) ve Teknik Yol Haritasıdır. Hedef okuyucu, oyunu kodlayacak / asset üretecek bir yapay zeka ajanıdır (Claude, GPT, Cursor, vb.) ve onu yöneten geliştiricidir.

> YAPAY ZEKA İÇİN ANA KURAL: Bu dokümanı bölüm 23'teki (Geliştirme Yol Haritası) milestone sırasına göre uygula. Bir milestone'un "Kabul Kriterleri" maddelerinin tamamı sağlanmadan bir sonrakine geçme. Her milestone sonunda oyunu çalıştırılabilir halde bırak.

## 0.1 Çalışma Kuralları

- **Tek doğru kaynak:** Sayısal değerler (formüller, tablolar, oranlar) bu dokümandan alınır. Bir değer eksikse, makul bir değer seç, `data/` klasöründeki JSON'a yaz ve `docs/DECISIONS.md` dosyasına "neden" notuyla ekle.
- **Veri odaklı tasarım:** Hiçbir item, skill, canavar, kahraman kodun içine sabit yazılmaz. Hepsi `data/*.json` dosyalarından yüklenir (Bölüm 24'te şemalar var).
- **Kod dili:** Godot 4.3+ ve statik tipli GDScript. Kod, değişken ve dosya isimleri **İngilizce**; oyun içi metinler lokalizasyon anahtarları üzerinden (`tr.csv`, `en.csv`).
- **Küçük adımlar:** Her görevi 1 sistem = 1 commit olacak şekilde böl. Her sistem için en az bir otomatik test (GUT veya gdUnit4) yaz: hasar formülü, XP eğrisi, loot tabloları, kayıt/yükleme.
- **Performans bütçesi her zaman geçerli:** Arka planda (pencere odakta değilken) CPU < %2, RAM < 300 MB, GPU neredeyse sıfır. Bkz. Bölüm 21.
- **Placeholder önce, sanat sonra:** Önce renkli kutularla/placeholder spritelarla oynanışı tamamla, sonra sanat varlıklarını aynı isimlerle değiştir (Bölüm 4.9 isimlendirme).
- **Belirsizlikte:** Oyuncu deneyimini (keyif, okunabilirlik, düşük dikkat gerektiren izlenebilirlik) öncelikle.

## 0.2 Doküman Haritası

| Bölüm | Konu | Kime |
|---|---|---|
| 1-2 | Vizyon, tür, referanslar, hedef kitle | Herkes |
| 3 | Teknik mimari, pencere sistemi, klasör yapısı | Kod AI |
| 4-6 | Sanat yönü, pixel art spesifikasyonu, animasyon, VFX | Sanat AI + Kod AI |
| 7-11 | Oynanış döngüsü, sınıflar, skiller, statlar, level/XP | Kod AI + Denge |
| 12-14 | Kahramanlar, fraksiyonlar, evcil hayvanlar | İçerik |
| 15-17 | Ekipman, silahlar, zırhlar, efsaneviler, setler, gemler, demirci, ekonomi | İçerik + Kod |
| 18-19 | Dünya, hikaye, bölgeler, canavarlar, bosslar, endgame | İçerik |
| 20 | UI/UX, açılış sekansı, özellik açılışları, oyun akışı, ses, lokalizasyon | Kod + Sanat |
| 21-22 | Performans, ayarlar, Steam entegrasyonu ve yayın | Kod |
| 23 | Geliştirme yol haritası (milestone'lar, riskler) | Herkes |
| 24-27 | Veri şemaları, denge tabloları, AI prompt kütüphanesi, QA | Kod + Sanat AI |

\pagebreak

# 1. Oyun Vizyonu

## 1.1 Tek Cümlelik Özet

**Beş kişilik sevimli pixel art bir parti, ekranının altındaki ince bir şeritte sen çalışırken otomatik savaşır, ganimet toplar ve güçlenir; sen ne zaman istersen menüleri açıp ekipmanlarını, skillerini ve stratejini yönetirsin.**

## 1.2 Tür ve Konum

- **Tür:** Idle / Auto-battler ARPG, masaüstü widget (desktop companion) oyunu.
- **Platform:** PC (Windows 10/11 öncelikli; macOS ve Linux/Steam Deck ikinci aşama).
- **Mağaza:** Steam (tek seferlik ücret, mikro-ödeme YOK; isteğe bağlı kozmetik DLC / Supporter Pack).
- **Hedef fiyat:** 6.99 USD (Türkiye bölgesel fiyat Steam önerisine göre), çıkışta %10-15 indirim.
- **Oturum yapısı:** Günde 6-10 saat arka planda açık kalabilir; aktif etkileşim günde 3-6 kez 2-10 dakikalık "kontrol" anları + isteyen için uzun aktif oturumlar.

## 1.3 Referans Oyunlar ve Bizden Ne Aldıkları

| Oyun | Neyi seviyoruz | Bizdeki karşılığı |
|---|---|---|
| My Party Is Grinding | 5 kişilik parti, Diablo tarzı stat ekranı, demirci birleştirme, fraksiyon koleksiyonu | Temel iskelet; biz daha derin sınıf ilerlemesi + kahraman kişilikleri ekliyoruz |
| TBH: Task Bar Hero | Görev çubuğunun üstünde yaşayan oyun, sıfır dikkat gerektiren izleme | Widget modu, taskbar'a yapışma |
| Rusty's Retirement | Ekranın kenarında yaşayan sakin oyun, düşük kaynak tüketimi | Pencere davranışı, "rahatsız etmeme" felsefesi |
| Diablo II / Path of Exile | Affix'li loot, nadirlik renkleri, set itemleri, zorluk seviyeleri | Loot ve item sistemi |
| Maplestory / Ragnarok | Sevimli chibi karakterler, iş değiştirme (job advancement) | Sınıf ilerlemesi (3 kademe) |
| Melvor Idle / Idle Champions | Offline ilerleme, uzun vadeli hedefler | Offline kazanç, koleksiyon bonusları |

## 1.4 Tasarım Sütunları (Pillars)

1. **Rahatsız etmeyen eşlikçi:** Oyun çalışırken kullanıcının işini asla bölmez. Ses varsayılan düşük, pencere küçük, CPU kullanımı neredeyse sıfır.
2. **Her bakışta bir ödül:** Oyuncu ne zaman göz atsa yeni bir şey görmeli: düşen efsanevi bir item, level atlama, yeni bölge, boss savaşı.
3. **Okunabilir, sevimli pixel art:** 30 cm uzaktan, ekranın köşesinden bakıldığında bile ne olduğu anlaşılmalı.
4. **Derinlik isteyene:** Stat dağıtımı, skill build, set itemleri, kahraman sinerjileri, demirci ekonomisi. Min-max yapmak isteyen için yüzlerce saat.
5. **Adil ve dürüst:** Pay-to-win yok, enerji sistemi yok, zorla reklam yok. Steam'de tek fiyat.

## 1.5 Hedef Kitle

- 18-35 yaş, masa başında çalışan / ders çalışan / yayın izleyen PC kullanıcıları.
- Diablo, Maplestory, mobil idle RPG geçmişi olan "loot sevenler".
- Steam'deki "Desktop Companion" / "Idler" etiketli oyunları satın alanlar.
- Yayıncılar: Ekranın altında oyun dönerken yayın yapmaya uygun (Streamer Mode, Bölüm 20.9).

## 1.6 Benzersiz Satış Noktaları (USP)

- **Gerçek saat entegrasyonu:** Savaş şeridinin arka planı bilgisayarın saatine göre gündüz / gün batımı / gece olur; gece canavarları farklıdır.
- **Kahraman kişilikleri:** Her kahramanın konuşma balonları (bark) var: level atlayınca, efsanevi item düşünce, uzun süre ölünce şakalaşırlar. (Kapatılabilir.)
- **Akıllı "geri döndüğünde" özeti:** Bilgisayara döndüğünde "Sen yokken" penceresi: kazanılan XP, altın, en iyi 5 item, ölümler, açılan bölgeler.
- **Taskbar Uyumu:** Windows görev çubuğunun konumunu otomatik algılar (alt/üst), şeridi tam üstüne yapıştırır.
- **3 kademeli sınıf ilerlemesi + 48 toplanabilir kahraman + 7 nadirlikte binlerce item kombinasyonu.**

\pagebreak

# 2. Platform ve Pencere Konsepti

## 2.1 İki Ana Görünüm Modu

Oyunun en önemli tasarım kararı pencere davranışıdır. Oyunda **iki mod** vardır ve oyuncu tek tıkla geçiş yapar.

### Mod A: Widget Modu (Şerit / Strip)

- Ekranın altında (taskbar'ın hemen üstünde) yatay bir **Savaş Şeridi** penceresi.
- Varsayılan boyut: **genişlik 640 px, yükseklik 140 px** (mantıksal çözünürlük 320x70, 2x tam sayı ölçek). Oyuncu 1x / 2x / 3x ölçek seçebilir.
- Şeridin içinde: parallax arka plan, 5 kahraman, düşmanlar, hasar sayıları, mini HUD (bölge adı "Sisli Orman Yolu 1-6", parti HP barı, boss zamanlayıcı).
- Şeridin sağında **Kontrol Paneli** (dikey küçük blok 96x140 px): Kahraman / Çanta / Gelişim / Dünya butonları + ayar, posta, ses ikonları (referans görsellerdeki gibi).
- Şeridin solunda 3 yuvarlak hızlı buton: **Kasaba'ya dön**, **İstatistik grafiği (DPS meter)**, **Otomatik İlerleme (AUTO)**.
- Şeridin üstünde ortada **Ganimet Sandığı** ikonu: yeni loot olduğunda zıplar ve parlar.
- Pencere: kenarlıksız, arka planı şeffaf (sadece şerit görünür), her zaman üstte (isteğe bağlı), sürüklenebilir.

### Mod B: Tam Mod (Panel Modu)

- Oyuncu bir butona bastığında şeridin **üstünde** ayrı pencereler/paneller açılır: Kahraman, Statlar, Envanter, Depo, Demirci, Dünya Haritası, Fraksiyon, Görevler vb.
- Paneller birbirinden bağımsız sürüklenebilir; açık kalırlar (masaüstünde widget gibi). Referans görsellerde olduğu gibi 3 panel yan yana açılabilir.
- Her panel standart boyutta: **Küçük 240x300, Orta 300x340, Geniş 420x340** (mantıksal px, 1x ölçekte). Ölçekle çarpılır.
- Paneller "mıknatıs" ile birbirine ve şeride yapışır (snap 12 px).
- Panellerin arkası masaüstüdür (şeffaf). Kullanıcı panellerin dışına tıklarsa tıklama alttaki uygulamaya geçer (mouse passthrough).

## 2.2 Pencere Davranış Kuralları

| Özellik | Varsayılan | Açıklama |
|---|---|---|
| Her zaman üstte | Açık | Ayarlardan kapatılabilir. Tam ekran uygulama algılanınca otomatik gizlenir (opsiyonel). |
| Tıklama geçirgenliği | Akıllı | Sadece görünür piksel alanları tıklanabilir, şeffaf alan arkaya geçer. |
| Görev çubuğu algılama | Açık | Windows `SHAppBarMessage` ile taskbar konumu ve yüksekliği alınır; şerit üstüne konur. |
| Çoklu monitör | Son konum | Pencere konumları monitör ID + göreli koordinatla kaydedilir. |
| DPI ölçek | Otomatik | Windows DPI (%100/125/150/200) okunur; tam sayı pixel ölçeğine yuvarlanır. |
| Tepsi (Tray) ikonu | Açık | Sağ tık: Göster/Gizle, Duraklat, Sessiz, Çıkış. |
| Patron Tuşu | Ctrl+Shift+H | Tüm pencereleri anında gizler, oyun arka planda devam eder. |
| Odak dışı FPS | 15 | Odakta 60 FPS, odak dışında 15, gizliyken 0 render (simülasyon devam). |
| Windows ile başlat | Kapalı | Ayarlardan açılabilir. |

## 2.3 Neden Bu Tasarım?

- Oyuncu iş yaparken şerit **70 px mantıksal yükseklik** ile ekranın sadece ~%6'sını kaplar.
- Panellerin ayrı pencereler olması, oyuncunun sadece envanteri açık tutup geri kalanını kapatmasına izin verir.
- Şeffaf arka plan + akıllı tıklama geçirgenliği, oyunu bir "masaüstü süsü" gibi hissettirir: bu türün Steam'de popüler olmasının ana sebebi budur.

\pagebreak

# 3. Teknik Mimari

## 3.1 Motor Seçimi

**Önerilen: Godot 4.3+ (GDScript, statik tipli).**

| Kriter | Godot 4.3+ | Unity 6 | Karar |
|---|---|---|---|
| Şeffaf, kenarlıksız, çoklu native pencere | Yerleşik (`Window` node, `embed_subwindows=false`, per-pixel transparency) | Native plugin gerekir | Godot |
| Mouse passthrough | `DisplayServer.window_set_mouse_passthrough(polygon)` | Win32 P/Invoke gerekir | Godot |
| Pixel art 2D | Mükemmel (nearest filter, integer scaling, pixel snap) | İyi | Eşit |
| Build boyutu / RAM | ~60-90 MB, düşük RAM | ~150+ MB | Godot |
| Steam | GodotSteam eklentisi (GDExtension) | Steamworks.NET | Eşit |
| Lisans | MIT, ücretsiz | Gelire bağlı | Godot |

Alternatif kabul edilir: Unity 6 + URP 2D. Ancak bu dokümandaki tüm teknik örnekler Godot içindir.

## 3.2 Proje Ayarları (Godot)

```
display/window/size/viewport_width = 320
display/window/size/viewport_height = 70
display/window/size/borderless = true
display/window/size/transparent = true
display/window/size/always_on_top = true
display/window/per_pixel_transparency/allowed = true
display/window/subwindows/embed_subwindows = false
display/window/stretch/mode = "viewport"
display/window/stretch/scale_mode = "integer"
rendering/textures/canvas_textures/default_texture_filter = "Nearest"
rendering/2d/snap/snap_2d_transforms_to_pixel = true
rendering/2d/snap/snap_2d_vertices_to_pixel = true
rendering/renderer/rendering_method = "gl_compatibility"
application/run/low_processor_mode = true
application/run/max_fps = 60
physics/common/physics_ticks_per_second = 30
```

- `gl_compatibility` renderer: düşük GPU kullanımı ve eski laptoplarda uyumluluk için.
- Fizik motoru kullanılmaz; çarpışma yok, savaş tamamen mantıksal (lane tabanlı) simülasyondur.

## 3.3 Mimari Katmanlar

```
[Simulation Layer]  (deterministik, render'dan bağımsız, 10 tick/sn)
   BattleSim, LootSim, OfflineSim, EconomySim
        |  sinyaller (EventBus)
[Game State Layer]  (tek kaynak: GameState autoload)
   PartyState, InventoryState, ProgressState, CollectionState
        |
[Presentation Layer] (sadece görüntü ve ses)
   StripView, PanelWindows, VFXManager, DamageNumberPool, AudioManager
```

- **Simülasyon render'dan ayrıdır:** Savaş mantığı sabit 10 tick/saniye çalışır. Pencere gizliyken render tamamen durur, simülasyon devam eder. Oyun kapalıyken geçen süre için Offline Simülasyon (Bölüm 7.7) istatistiksel olarak hesaplar.
- **EventBus:** `enemy_killed`, `item_dropped`, `hero_leveled`, `boss_spawned`, `zone_cleared` gibi sinyaller. UI sadece sinyal dinler; simülasyona doğrudan dokunmaz.

## 3.4 Autoload (Singleton) Listesi

| Autoload | Görev |
|---|---|
| `GameState` | Tüm kalıcı oyun verisinin sahibi; kayıt/yükleme. |
| `DataDB` | `data/*.json` dosyalarını açılışta yükler, ID ile sorgu verir. |
| `EventBus` | Global sinyaller. |
| `BattleSim` | Savaş şeridinin mantığı; dalga, hedefleme, hasar. |
| `LootSystem` | Drop tabloları, item üretimi, affix roll. |
| `WindowManager` | Native pencereleri açar/kapar, konum kaydeder, snap, passthrough poligonlarını günceller. |
| `TimeService` | Gerçek saat, offline süre, gündüz/gece döngüsü. |
| `AudioManager` | Müzik/SFX havuzu, odak dışı ses azaltma. |
| `SteamService` | Başarımlar, bulut kayıt, rich presence (Steam yoksa no-op). |
| `Settings` | Kullanıcı ayarları (`user://settings.cfg`). |
| `Loc` | Lokalizasyon yardımcıları. |

## 3.5 Klasör Yapısı

```
res://
  addons/            (godotsteam, gut)
  assets/
    sprites/heroes/<hero_id>/    (idle.png, run.png, attack.png ...)
    sprites/enemies/<enemy_id>/
    sprites/items/<category>/    (16x16 ikonlar)
    portraits/                   (128x160 kahraman portreleri)
    backgrounds/<act>/<zone>/    (parallax katmanları)
    ui/                          (9-slice çerçeveler, butonlar, ikonlar)
    vfx/                         (sprite sheet efektler)
    fonts/
    audio/music/  audio/sfx/
  data/
    heroes.json  classes.json  skills.json  items_base.json
    affixes.json  legendaries.json  sets.json  enemies.json
    zones.json  loot_tables.json  achievements.json  pets.json
    balance.json (tüm formül katsayıları)
  scenes/
    main/Main.tscn            (giriş, şerit penceresi)
    strip/BattleStrip.tscn
    panels/HeroPanel.tscn  StatsPanel.tscn  InventoryPanel.tscn ...
    common/Tooltip.tscn  ItemSlot.tscn  NineSliceFrame.tscn
  scripts/
    core/ sim/ systems/ ui/ util/
  localization/ tr.csv en.csv ...
  tests/
```

## 3.6 Kayıt Sistemi

- Format: JSON, `user://saves/slot_<n>.json` + `.bak` (son 3 yedek döngüsel).
- Otomatik kayıt: her 60 saniyede, her boss sonunda, pencere kapanırken, Windows oturum kapanma sinyalinde.
- Bütünlük: SHA-256 checksum alanı; bozuksa `.bak` yüklenir.
- Versiyonlama: `save_version` alanı + migration fonksiyonları (`migrate_v1_to_v2`).
- Steam Cloud: `user://saves/` klasörü Auto-Cloud ile senkronize.
- Hile koruması: Tek oyunculu oyun; ciddi koruma yok. Sadece liderlik tablosu için kule katı sunucuya değil Steam Leaderboard'a gönderilir ve aşırı uç değerler istemci tarafında reddedilir.

## 3.7 Rastgelelik

- Tüm rastgelelik `RandomNumberGenerator` örnekleri üzerinden; loot için ayrı seed (`loot_rng`), savaş için ayrı (`combat_rng`). Bu, testlerde deterministik tekrar sağlar.
