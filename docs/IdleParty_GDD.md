# IDLE PARTY: Desktop Legends

**Oyun Tasarım Dokümanı (GDD) ve Yapay Zeka Geliştirme Yol Haritası**

Sürüm 1.0 - Ekim 2026

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



# 4. Sanat Yönü ve Pixel Art Spesifikasyonu

## 4.1 Genel Stil Tanımı

Hedef görünüm, referans görsellerdeki gibi **"sevimli, temiz, orta yoğunlukta pixel art"**dır. Aşırı detaylı (HD-2D) değil, aşırı kaba (8-bit) değil. 16-bit dönem JRPG'leri (Final Fantasy VI, Secret of Mana) ile modern indie pixel art (Eastward, Sea of Stars) arasında bir yerde.

- **Savaş şeridi karakterleri:** Chibi oranlar (baş : vücut = 1 : 1.5), büyük gözler, belirgin silüet.
- **Portreler (Kahraman paneli):** Daha gerçekçi oranlı (1:6), daha detaylı, vitray (stained glass) çerçevesi önünde ayakta duran tam boy pixel art. Referans görseldeki Şövalye ve Okçu portreleri gibi.
- **UI:** Koyu kahverengi/antrasit ahşap-metal çerçeveler, altın sarısı başlık plakaları, turuncu aktif sekmeler, köşelerde perçin detayları.

> SANAT AI İÇİN ÖZET CÜMLE (her prompta ekle): "Cute 16-bit style pixel art, clean 1px dark outlines (not pure black), limited palette, 3-tone cel shading, chibi proportions, readable silhouette at small size, no anti-aliasing, no gradients, no blur, transparent background."

## 4.2 Çözünürlük ve Ölçek Kuralları

| Varlık | Boyut (px, 1x) | Ekranda | Not |
|---|---|---|---|
| Savaş karakteri (kahraman) | 32x32 tuval, karakter ~20-24 px yükseklik | 2x = 64x64 | Ayaklar tuvalin alt 2. pikselinde, merkez x=16 |
| Normal düşman | 32x32 | 2x | |
| Elit düşman | 40x40 | 2x | Normalden %25 büyük + renk varyantı |
| Boss | 64x64 veya 96x64 | 2x | Şeridin yüksekliğini doldurabilir |
| Item ikonu | 16x16 (envanter slotu 20x20) | 2x/3x | 1px kenar boşluğu |
| Skill ikonu | 20x20 | 2x | Çerçeve UI tarafından eklenir |
| Kahraman portresi | 96x144 | 2x | Vitray arka plan 112x150 ayrı katman |
| Mini kafa (fraksiyon listesi) | 16x16 | 2x | |
| Parallax arka plan | 480x70 (döşenebilir yatay) | 2x | 3-4 katman |
| UI çerçeve | 9-slice, 8 px köşe | | |

**Altın kurallar:**
- Asla tam sayı olmayan ölçek kullanılmaz (1.5x yasak). Pencere boyutu tam sayı ölçekle hesaplanır.
- Tüm spriteler aynı **piksel yoğunluğunda** olmalı (karışık ölçek - "mixel" - yasak).
- Döndürme (rotation) sadece VFX ve mermilerde; karakterlerde yok.
- Sprite'lar her zaman tam piksele hizalanır (pixel snap).

## 4.3 Renk Paleti

Ana palet 48 renk ile sınırlıdır (ör. "Resurrect 64" paletinden seçilmiş alt küme önerilir). Temel kurallar:

- **Kontur rengi:** Saf siyah (#000000) değil, koyu mor-kahve **#2B1B2E**. Arka plan nesneleri için daha açık kontur **#4A3B4F**.
- **Gölgeleme:** Her malzeme 3 ton (gölge, ana, ışık) + opsiyonel 1 parlama pikseli. Gölgeler soğuğa (mor/mavi), ışıklar sıcağa (sarı) kayar (hue shifting).
- **Işık yönü:** Sol üstten.
- **Karakterler arka plandan ayrışmalı:** Arka planlar daha düşük doygunlukta ve kontrastta; karakterler ve düşmanlar daha doygun.

| Kullanım | Renk (HEX) |
|---|---|
| UI ana çerçeve | #3A2A22, #5C4033, perçin #C8A165 |
| UI panel iç zemin | #1E1A1F (yarı opak %92) |
| Başlık plakası yazısı | #F2E6C9 |
| Aktif sekme / ana buton | #E8742A (turuncu), hover #FF8E3C |
| İkincil buton (mavi) | #3D6FD6 |
| Altın / para | #F7C948 |
| HP barı | #D63A3A, kalkan #6FB3E8 |
| XP barı | #F2B33D |

## 4.4 Nadirlik Renkleri (Tüm oyunda tutarlı)

| Nadirlik | TR | Renk | Görsel efekt |
|---|---|---|---|
| Common | Sıradan | #B8B8B8 gri | Yok |
| Magic | Büyülü | #4F8CFF mavi | Yok |
| Rare | Nadir | #F5D547 sarı | İkon arkası hafif sarı |
| Epic | Destansı | #B05CFF mor | Slot çerçevesi yanıp sönen mor parıltı |
| Legendary | Efsanevi | #FF8A1F turuncu | Düşerken ışık sütunu + özel ses |
| Mythic | Mitik | #FF3B5C kırmızı-pembe | Işık sütunu + ekran kenarında kısa parıltı |
| Set | Set | #3DDC84 yeşil | Yeşil ışık sütunu |

## 4.5 Karakter Tasarım Kuralları (Savaş Şeridi)

- Her sınıfın **tek bakışta tanınan silüeti** olmalı: Şövalye = kalkan + miğfer tüyü; Okçu = yay + uzun at kuyruğu; Büyücü = sivri şapka + asa ucunda parlayan küre; Rahibe = hale + beyaz pelerin; Suikastçı = başlık + iki hançer; Barbar = iri gövde + iki elli balta; Ozan = lavta + tüylü şapka; Nekromant = kukuleta + yeşil alevli tırpan.
- Ekipman görsel değişimi: Savaş şeridinde **silah** ve **kostüm** görünür (silah sprite'ı ayrı katman, 6 görsel kademe). Zırh parçaları performans ve iş yükü için şeritte görünmez; bunun yerine **Kostüm** sistemi (Bölüm 14.3) görünümü değiştirir.
- Kahramanlar varsayılan olarak **sağa** bakar; düşmanlar **sola**.

## 4.6 Arka Planlar (Parallax)

Her bölgenin 4 katmanı vardır:

1. **Gökyüzü** (sabit, gerçek saate göre 4 varyant: gündüz, gün batımı, gece, şafak) — renk geçişi shader ile yumuşak.
2. **Uzak katman** (dağlar, kale silüetleri) — hız 0.1
3. **Orta katman** (ağaçlar, binalar) — hız 0.4
4. **Zemin** (yol, çimen, taş) — hız 1.0; karakterlerin yürüdüğü çizgi y=58 (mantıksal).
5. Opsiyonel **ön plan** (yarı saydam çalılar, sis) — hız 1.3, %60 opaklık.

Ek: Her bölgenin hava durumu efekti (yağmur, kar, ateş külleri, yaprak) — parçacık sayısı max 40.

## 4.7 UI Sanatı

- Tüm paneller 9-slice çerçeve: dış metal kenar 2 px, köşelerde perçin, iç gölge 1 px.
- Panel başlığı: ortada çıkıntılı koyu plaka (referans: "Stats", "Hero", "Knight" plakaları).
- Kapatma butonu: sağ üst kırmızı kare, beyaz X.
- Sekmeler: Pasif sekme koyu kahve, aktif sekme turuncu.
- Fontlar: **Ana UI fontu**: Türkçe karakter (ç, ğ, ı, İ, ö, ş, ü) ve ileride CJK destekleyen pixel font (ör. "Galmuri" veya "Fusion Pixel 12px" — OFL lisanslı). **Sayılar**: ayrı bir kalın pixel sayı fontu (hasar rakamları için 5x7 ve 7x9 boyutları).
- Tooltip: koyu zemin, item adı nadirlik renginde, ayırıcı çizgiler, karşılaştırma (yeşil yukarı ok / kırmızı aşağı ok).

## 4.8 Grafik Kalitesini "Mükemmel" Gösteren Detaylar

Bu küçük dokunuşlar oyunun Steam sayfasında premium görünmesini sağlar:

- **Hit flash shader:** Vurulan düşman 1 kare beyaz olur.
- **Squash & stretch:** Kahraman zıplarken / vurulurken 1-2 piksel ezilme.
- **Rarity outline shader:** Yerdeki itemler nadirlik renginde 1 px parlayan kontur.
- **Dissolve ölüm efekti:** Düşmanlar ölürken piksel piksel dağılır (noise texture ile).
- **Işık sütunları:** Efsanevi item düşünce şeritte dikey ışık sütunu ve parçacıklar.
- **Gece aydınlatması:** Gece bölgelerde `CanvasModulate` ile karartma + kahramanların etrafında `PointLight2D` (yumuşak değil, pixel-step'li ışık halkası).
- **Hasar rakamları:** Yukarı zıplayıp hafif yayılan, kritiklerde büyüyüp sallanan, element renginde rakamlar.
- **Ekran sarsıntısı:** Sadece boss vuruşlarında, max 2 piksel; ayarlardan kapatılabilir.
- **Yumuşak geçişler:** Bölge değişirken "kapı" (portal) geçiş animasyonu, 0.6 sn pixel-wipe.

## 4.9 Dosya İsimlendirme Standardı

```
hero_<class>_<variant>_<anim>.png       hero_knight_base_attack.png
enemy_<act>_<name>_<anim>.png            enemy_a1_slime_green_run.png
boss_<act>_<name>_<anim>.png             boss_a1_goblin_king_skill1.png
item_<slot>_<base_id>.png                item_weapon_sword_t3.png
skill_<class>_<skill_id>.png             skill_knight_recovery.png
portrait_<hero_id>.png                   portrait_aria_archer.png
bg_<act>_<zone>_<layer>.png              bg_a1_z01_far.png
vfx_<name>_<frames>f.png                 vfx_slash_white_6f.png
ui_<element>_<state>.png                 ui_button_orange_hover.png
```

Sprite sheet'ler yatay şerit olarak dizilir (tüm kareler aynı boyutta, aralıksız). Godot'ta `SpriteFrames` resource'una otomatik import eden bir editör scripti yazılır (`tools/import_sheets.gd`).


# 5. Animasyon Spesifikasyonu

## 5.1 Kahraman Animasyonları

| Animasyon | Kare | FPS | Döngü | Not |
|---|---|---|---|---|
| idle | 4 | 6 | Evet | Nefes alma, 1 px yukarı-aşağı |
| run | 6 | 10 | Evet | Bölge arası yürüyüş ve dalga arası ilerleme |
| attack | 6 | 12 | Hayır | Vuruş karesi (impact frame) = 4. kare; hasar bu karede uygulanır |
| skill | 8 | 12 | Hayır | Büyü / özel hareket; efekt 5. karede doğar |
| hit | 2 | 10 | Hayır | Geri sekme 1 px + beyaz flash |
| death | 6 | 8 | Hayır | Yere düşüş; sonra 0.5 sn yanıp sönerek kaybolur, mezar taşı ikonu kalır |
| victory | 4 | 6 | Evet | Boss sonrası silah kaldırma |
| revive | 4 | 8 | Hayır | Işık sütunuyla geri gelme |

- Her sınıf için 8 animasyon = toplam ~38 kare. 8 sınıf x 3 kademe görünüm = 24 temel set. Kahramanlar (48) bu temel setlerin **palet ve aksesuar varyantları**dır (saç rengi, saç modeli, şapka/kafa aksesuarı katmanı). Bu, sanat yükünü yönetilebilir tutar.
- **Katmanlı sprite:** Gövde + Saç + Kafa aksesuarı + Silah ayrı katmanlar; aynı kare yapısı. Kahraman varyantı = katman kombinasyonu + palet swap shader'ı.

## 5.2 Düşman Animasyonları

| Tür | Animasyonlar |
|---|---|
| Normal | idle 4, run 4, attack 4, hit 2, death 4 |
| Elit | Normal + skill 6 |
| Boss | idle 6, run 6, attack 6, skill1 8, skill2 8, enrage geçiş 6, hit 2, death 10 |

## 5.3 Animasyon Prensipleri

- **Anticipation:** Saldırıdan önce 1-2 kare geri çekilme.
- **Impact frame:** Vuruş karesi 2 tick (diğerlerinin 2 katı) gösterilir: "hit stop" hissi.
- **Follow-through:** Silah hareketi bittikten sonra pelerin/saç 1 kare gecikmeyle durur.
- Animasyon hızları saldırı hızı statüyle ölçeklenir (min 0.5x, max 2.25x).


# 6. Görsel Efektler (VFX) ve Geri Bildirim

## 6.1 Efekt Kütüphanesi

| Efekt ID | Kare | Boyut | Kullanım |
|---|---|---|---|
| vfx_slash_white | 5 | 32x32 | Kılıç/balta temel vuruş |
| vfx_slash_crit | 6 | 48x32 | Kritik vuruş (sarı-turuncu) |
| vfx_pierce | 4 | 32x16 | Mızrak/hançer |
| vfx_arrow_trail | 3 | 16x4 | Ok izi |
| vfx_fireball | 4 loop + 6 patlama | 16x16 / 32x32 | Ateş büyüleri |
| vfx_ice_shard | 4 + 5 | 16x16 | Buz |
| vfx_lightning | 4 | 16x64 | Yıldırım (dikey) |
| vfx_poison_cloud | 8 loop | 48x24 | Zehir alanı |
| vfx_holy_heal | 8 | 32x48 | İyileştirme sütunu (yeşil-altın) |
| vfx_shield_bubble | 6 loop | 32x32 | Kalkan |
| vfx_dark_orb | 6 | 24x24 | Kaos/Karanlık |
| vfx_earth_spike | 7 | 32x48 | Toprak dikeni (Okçu "Earth Strike") |
| vfx_buff_aura | 6 loop | 32x8 | Ayak altı aura halkası |
| vfx_levelup | 10 | 32x64 | Altın ışık sütunu + "LEVEL UP!" yazısı |
| vfx_loot_beam | 8 loop | 8x64 | Nadirlik rengine boyanan ışık sütunu |
| vfx_coin_burst | 6 | 24x24 | Altın düşüşü |
| vfx_death_dissolve | shader | - | Ölüm dağılması |
| vfx_portal | 8 loop | 32x48 | Bölge geçişi |

## 6.2 Element Renkleri

| Element | Ana Renk | Hasar rakamı rengi |
|---|---|---|
| Fiziksel | Beyaz/gri | #FFFFFF |
| Ateş | Turuncu-kırmızı | #FF7A33 |
| Soğuk | Açık mavi | #7FD8FF |
| Yıldırım | Sarı | #FFE45C |
| Kaos (zehir/karanlık) | Mor-yeşil | #B266FF |
| Kutsal | Altın | #FFD98A |
| İyileşme | Yeşil | #6CFF8A (+ önünde "+") |

## 6.3 Hasar Rakamları

- Nesne havuzu (object pool) ile max 40 aktif rakam. Fazlası birleştirilir ("x3").
- Normal: 7 px font, yukarı 12 px, 0.7 sn.
- Kritik: 9 px font, %130 ölçek pop, hafif sallanma, "!" eki, 0.9 sn.
- Kaçınma: "MISS" gri. Bloke: "BLOCK" mavi.
- Ayar: Rakamlar Açık / Sadece Kritik / Kapalı. Büyük sayılar kısaltılır (12.4K, 3.1M).

## 6.4 Geri Bildirim Öncelik Sırası (Oyuncu göz attığında ne görmeli)

1. Efsanevi/Mitik/Set drop (ışık sütunu + sandık ikonu zıplaması + ses).
2. Level atlama (altın sütun).
3. Boss geldi (şerit kenarında kırmızı uyarı, boss HP barı).
4. Parti öldü (gri filtre + "Kasaba'ya dönülüyor 5..4..").
5. Yeni bölge açıldı (sağ alt köşede bildirim baloncuğu).



# 7. Oynanış Döngüsü

## 7.1 Döngü Katmanları

| Döngü | Süre | İçerik |
|---|---|---|
| Mikro | 5-30 sn | Dalga temizle, düşen altın/itemi topla (otomatik), skill animasyonları |
| Kısa | 3-10 dk | Bölgenin 10 aşamasını bitir, boss'u yen, yeni bölge aç |
| Orta | 30-90 dk | Level atla, stat/skill puanı dağıt, ekipman değiştir, demircide birleştir |
| Uzun | 1-7 gün | Yeni Perde (Act), zorluk seviyesi, sınıf ilerlemesi, set tamamlama, fraksiyon koleksiyonu |
| Endgame | Haftalar | Sonsuz Kule, Yarıklar, Paragon seviyeleri, Mitik item avı, liderlik tablosu |

## 7.2 Savaş Şeridi Akışı (Bir Aşama)

1. Parti soldan sağa doğru koşar (run animasyonu, arka plan kayar).
2. Sağdan bir **dalga** gelir: 3-5 normal düşman (her 3. dalgada 1 elit şansı %20).
3. Kahramanlar menzile girince durur ve savaşır. Düşmanlar ölünce altın/item yere düşer ve otomatik olarak sandığa uçar (mıknatıs animasyonu 0.4 sn).
4. Bir aşama = **5 dalga**. Aşama numarası şeritte görünür: "Sisli Orman Yolu 1-6".
5. Her bölgede **10 aşama** vardır; 10. aşama **Boss aşaması**dır (boss + 2 yardımcı, 60 sn zaman sınırı).
6. Boss yenilirse sonraki bölge açılır. AUTO açıksa otomatik geçilir; kapalıysa parti mevcut bölgede "farm" yapar (aynı aşamayı tekrarlar).
7. Boss zaman sınırında yenilemezse parti 9. aşamaya döner ve farm moduna geçer; oyuncuya "Güçlen ve tekrar dene" bildirimi.

## 7.3 Parti Düzeni

- 5 slot, soldan sağa: **Arka 1 - Arka 2 - Orta - Ön 2 - Ön 1** (Ön 1 en sağda, düşmana en yakın).
- Yakın dövüş sınıfları ön slotlarda olmazsa %30 hasar cezası alır ("Pozisyon dışı").
- Düşmanlar varsayılan olarak **en öndeki (en sağdaki) canlı kahramanı** hedefler. Bazı düşmanlar (suikastçı tipi) en düşük HP'li veya en arkadaki kahramanı hedefler; bu, oyuncuya dizilim kararı verdirir.
- Tank sınıfı "Provoke" (tehdit) değeri taşır: Hedefleme ağırlığı = 1 + Tehdit.

## 7.4 Hedefleme ve Menzil

| Sınıf tipi | Menzil (mantıksal px) | Hedef seçimi |
|---|---|---|
| Yakın dövüş | 18 | En yakın düşman |
| Mızrak | 30 | En yakın, 2 hedef delme şansı |
| Menzilli (yay) | 140 | En yakın; skill ile en düşük HP |
| Büyücü | 120 | En yoğun düşman grubu (alan hasarı) |
| Destek | 120 | Müttefik: en düşük HP %; düşman: en yakın |

## 7.5 Ölüm ve Diriliş

- Ölen kahraman 15 sn sonra savaş içinde otomatik dirilir (Rahibe skilli ile daha hızlı).
- Tüm parti ölürse: 5 sn geri sayım, bölgenin 1. aşamasına geri dönülür, %0 ceza (idle oyunlarda ağır ceza sevilmez). Zorluk "Cehennem"de ölüm başına 30 sn "Yorgunluk" debuff'ı (-%20 hasar).

## 7.6 Otomatik Sistemler

- **Otomatik toplama:** Altın ve itemler otomatik toplanır.
- **Otomatik satış filtresi:** Oyuncu "Sıradan ve Büyülü itemleri otomatik sat" veya "Nadir altını sökerek malzemeye çevir" seçebilir (Bölüm 17.6).
- **Otomatik skill:** Skiller hazır olunca otomatik kullanılır. Gelişmiş ayar: "Bu skilli sadece boss'ta kullan", "HP %40 altında kullan".
- **Otomatik ekipman önerisi:** Daha iyi item düşünce ikon üzerinde yeşil ok; tek tıkla "En iyisini giy" butonu (puanlama: item gücü skoru, Bölüm 15.9).

## 7.7 Offline İlerleme

- Oyun kapalıyken geçen süre (max **12 saat**, Gelişim ile 24 saate çıkar) için simülasyon:
  - Son 5 dakikanın ortalama **öldürme/dakika**, **XP/dk**, **altın/dk** değerleri kaydedilir.
  - Offline kazanç = ortalama x süre x **%60 verim** (Gelişim ağacıyla %100'e kadar).
  - Item dropları: Toplam öldürme sayısına göre loot tablosundan **toplu roll** (en fazla 200 item; fazlası otomatik satılır, Efsanevi+ asla satılmaz).
  - Boss ilerlemesi offline'da olmaz (parti farm modunda kalır).
- Dönüşte **"Sen Yokken"** penceresi: süre, XP, altın, level atlamaları, en iyi 5 item (nadirlik sırasıyla), malzemeler. "Topla" butonu ile coin-burst animasyonu.

## 7.8 Kasaba (Hub)

Kasaba ayrı bir şerit sahnesidir (savaş yok). Butonla veya parti ölünce gidilir. Kasabadaki NPC'ler panel açar:

| NPC | Panel | Açılış |
|---|---|---|
| Demirci Borin | Birleştir / Sat / Üret / Güçlendir | Lv 5 |
| Tüccar Mira | Malzeme ve iksir satın alma, günlük teklif | Lv 3 |
| Meyhaneci Tobi | Kahraman toplama (Taverna), kahraman yükseltme | Lv 8 |
| Kâhin Selene | Stat/skill sıfırlama, sınıf ilerlemesi | Lv 30 |
| Kuyumcu Nyx | Gem kesme ve soket | Lv 25 |
| Depo Bekçisi | Depo (7 sekme) | Lv 1 |
| Lonca Panosu | Görevler, günlük/haftalık | Lv 10 |


# 8. Savaş Sistemi ve Formüller

Tüm katsayılar `data/balance.json` içinde tutulur. Aşağıdaki değerler başlangıç değerleridir.

## 8.1 Tick Sistemi

- Simülasyon **10 tick/sn**. Her tick: buff süreleri azalır, saldırı zamanlayıcıları ilerler, skill cooldown'ları ilerler, DoT hasarı uygulanır (DoT 1 sn'de bir).
- Saldırı aralığı (sn) = `1 / (WeaponBaseAPS x (1 + AttackSpeed%))`

## 8.2 Hasar Hesabı

```
RawDamage   = Attack x SkillMultiplier x (1 + AddedDamage% + ElementBonus% + SkillDamage%)
            x Product(MoreMultipliers)            # set/efsanevi "x%30 daha fazla" etkileri
IsCrit      = rng < CritChance (cap %75)
CritDamage  = RawDamage x CritDMG (taban %150)
EffDEF      = TargetDEF x (1 - Penetrate%)
DR          = EffDEF / (EffDEF + 50 + 6 x AttackerLevel)     # cap %75
Elemental   = (1 - TargetResist% + ResistShred%)            # resist cap %75, min -%50
Final       = RawDamage x (1 - DR) x Elemental x rng(0.95, 1.05)
```

**Örnek (referans ekranla tutarlı):** Lv 50 saldırgana karşı DEF 276 → DR = 276 / (276 + 350) = **%44.1**. Referans görseldeki "276 (44%)" ile birebir.

## 8.3 Kaçınma, Blok, İsabet

- `HitChance = clamp(Accuracy / (Accuracy + Evasion x 0.5), %60, %98)` — normal düşmanlarda isabet varsayılan %95.
- Blok (kalkan): `BlockChance` (cap %50) — bloklanan hasar %60 azalır.
- Kritik Hasar Direnci: Saldırganın CritDMG'sini azaltır (Defense sekmesinde gösterilir).

## 8.4 İyileştirme ve Kalkan

- Heal = `SpellPower x HealMultiplier x (1 + HealingBonus%)`; aşırı iyileşme "Taşma Kalkanı"na dönüşmez (sadece belirli itemlerle).
- Kalkan (Shield) önce hasarı emer, 6 sn sürer, üst üste binmez (en büyüğü kalır).

## 8.5 Durum Etkileri

| Etki | Kaynak | Süre | Etki |
|---|---|---|---|
| Yanma (Burn) | Ateş | 3 sn | Saniyede vuruşun %20'si ateş hasarı, üst üste 3 yığın |
| Donma (Chill) | Soğuk | 2 sn | -%30 saldırı ve hareket hızı; 5 yığında 1 sn Dondurma (Freeze) |
| Şok (Shock) | Yıldırım | 4 sn | Hedef %15 fazla hasar alır |
| Zehir (Poison) | Kaos | 5 sn | Saniyede %12, sınırsız yığın (max 20) |
| Kanama (Bleed) | Fiziksel | 4 sn | Saniyede %15, hareket ederken x2 |
| Sersemleme (Stun) | Skill | 1 sn | Eylem yok; bosslarda %50 süre |
| Zayıflatma (Weaken) | Skill | 5 sn | Hedef -%20 hasar verir |
| Kırılgan (Vulnerable) | Skill | 5 sn | Hedef +%20 hasar alır |

## 8.6 Düşman Ölçekleme

```
EnemyHP(L)    = 40 x 1.075^L x TypeMult x DifficultyMult
EnemyATK(L)   = 8  x 1.065^L x TypeMult_ATK x DifficultyMult
EnemyDEF(L)   = 10 + 4.5 x L
TypeMult      : Normal 1.0 | Elit 3.5 | Mini-Boss 10 | Boss 25 | Perde Boss 40
TypeMult_ATK  : Normal 1.0 | Elit 1.6 | Mini-Boss 2.0 | Boss 2.5 | Perde Boss 3.0
DifficultyMult: Normal 1.0 | Kabus 1.6 | Cehennem 2.6 (+ Resist -%30 / -%60)
```

Detaylı tablo: Bölüm 25.


# 9. Stat Sistemi

## 9.1 Ana Statlar (Primary)

Her levelde **5 Stat Puanı** gelir (+ her 10 levelde bonus 5). Oyuncu dağıtır veya "Otomatik Dağıt" (sınıf şablonuna göre) kullanır.

| Stat | TR | Etkisi (puan başına) |
|---|---|---|
| STR | Güç | +1.5 Saldırı (Güç sınıfları), +4 HP, +%0.2 Fiziksel Hasar |
| DEX | Çeviklik | +1.5 Saldırı (Çeviklik sınıfları), +%0.08 Kritik Şansı, +%0.25 Saldırı Hızı, +0.5 Kaçınma |
| INT | Zekâ | +1.5 Büyü Gücü, +%0.25 Büyü Hızı, +%0.3 Skill Hasarı, +%0.1 Bekleme Süresi Azaltma (cap %40) |
| VIT | Dayanıklılık | +12 HP, +0.4 Savunma, +%0.02 HP Yenilenme/sn |
| LUK | Şans | +%0.15 Item Bulma, +%0.12 Altın Bulma, +%0.03 Kritik Şansı |

- Her sınıfın **ana stat**ı vardır (Şövalye/Barbar: STR, Okçu/Suikastçı: DEX, Büyücü/Nekromant: INT, Rahibe/Ozan: INT+VIT hibrit). Saldırıya katkı sadece ana stattan gelir; diğer statlar ikincil faydaları verir.
- Sıfırlama: Kâhin'de, maliyet = `100 x Level^1.5` altın. İlk 2 sıfırlama ücretsiz.

## 9.2 Türetilmiş Statlar (Stat Paneli)

Referans görseldeki gibi Stat paneli 4 sekmelidir: **Tümü / Saldırı / Savunma / Diğer**. Her satır üzerine gelince tooltip ile açıklama ve kaynak dökümü (Taban + Stat + Ekipman + Pasif + Buff) gösterir.

| Sekme | Stat | Taban | Cap |
|---|---|---|---|
| Saldırı | Saldırı (Attack) | Sınıf tabanı + silah | - |
| Saldırı | Eklenen Hasar % | 0 | - |
| Saldırı | Elemental Hasar % | 0 | - |
| Saldırı | Kritik Şansı | %5 | %75 |
| Saldırı | Kritik Hasarı | %150 | %500 |
| Saldırı | Delme (Penetrate) | %0 | %60 |
| Saldırı | Saldırı Hızı | %100 | %225 |
| Saldırı | Büyü Hızı | %0 | %150 |
| Saldırı | Kahraman Aktif Skill Hasarı | %0 | - |
| Saldırı | Skill Menzili / Skill Alanı | %0 | %100 |
| Saldırı | Ateş / Soğuk / Yıldırım / Kaos Hasarı | %0 | - |
| Savunma | HP | Sınıf tabanı | - |
| Savunma | Savunma (DR %) | Sınıf tabanı | DR %75 |
| Savunma | Kritik Vuruş Direnci | %0 | %50 |
| Savunma | Ateş/Soğuk/Yıldırım/Kaos Direnci | %0 | %75 |
| Savunma | Kaçınma / Blok | %0 | %50 |
| Savunma | HP Yenilenme /sn | 0 | - |
| Savunma | Can Çalma % | 0 | %10 |
| Diğer | Item Bulma % | 0 | %400 |
| Diğer | Altın Bulma % | 0 | %400 |
| Diğer | XP Bonusu % | 0 | - |
| Diğer | Bekleme Süresi Azaltma | 0 | %40 |
| Diğer | Hareket Hızı | %100 | %150 |

## 9.3 Sınıf Taban Değerleri

| Sınıf | Taban HP | HP/Level | Taban Saldırı | Saldırı/Level | Taban DEF | DEF/Level | Silah APS |
|---|---|---|---|---|---|---|---|
| Şövalye | 220 | 38 | 14 | 3.0 | 20 | 4.0 | 1.10 |
| Barbar | 200 | 34 | 18 | 3.8 | 12 | 2.6 | 0.90 |
| Okçu | 150 | 24 | 16 | 3.6 | 8 | 1.8 | 1.00 |
| Suikastçı | 140 | 22 | 15 | 3.4 | 8 | 1.8 | 1.45 |
| Büyücü | 120 | 20 | 18 | 4.0 | 6 | 1.4 | 0.85 |
| Nekromant | 135 | 22 | 16 | 3.6 | 7 | 1.6 | 0.90 |
| Rahibe | 150 | 25 | 10 | 2.4 | 10 | 2.2 | 0.95 |
| Ozan | 160 | 26 | 11 | 2.6 | 10 | 2.2 | 1.00 |


# 10. Level, XP ve İlerleme Hızı

## 10.1 Formüller

```
XP_per_kill(L)   = round(8 + 1.5 x L^1.5) x TypeXPMult     (Elit x4, Boss x30, Perde Boss x80)
Kills_to_level(L)= 40 + 9 x L
XP_required(L)   = XP_per_kill(L) x Kills_to_level(L)
LevelDiffPenalty : canavar seviyesi oyuncudan 5+ düşükse her level için -%10 XP (min %10)
                   canavar 3+ yüksekse her level için +%5 XP (max +%25)
Gold_per_kill(L) = round(3 + 0.8 x L^1.3) x (1 + GoldFind%)
```

- **Maksimum level: 100.** 100'den sonra **Paragon** sistemi (Bölüm 19.5).
- XP partideki her kahramana **tam** verilir (bölünmez). Yedek (partide olmayan) kahramanlar %25 "Antrenman XP"si alır (Gelişim ile %75'e kadar).

## 10.2 XP Tablosu (Seçili Levellar)

| Level | XP/Öldürme | Gerekli Öldürme | Gerekli XP | Level süresi (dk, aktif) | Toplam süre (saat) |
|---|---|---|---|---|---|
| 1 | 10 | 49 | 490 | 1.3 | 0.0 |
| 5 | 25 | 85 | 2,125 | 2.3 | 0.1 |
| 10 | 55 | 130 | 7,150 | 3.5 | 0.4 |
| 15 | 95 | 175 | 16,625 | 4.7 | 0.7 |
| 20 | 142 | 220 | 31,240 | 5.9 | 1.2 |
| 25 | 196 | 265 | 51,940 | 7.1 | 1.7 |
| 30 | 254 | 310 | 78,740 | 8.3 | 2.4 |
| 40 | 387 | 400 | 154,800 | 10.7 | 4.0 |
| 50 | 538 | 490 | 263,620 | 13.1 | 6.0 |
| 60 | 705 | 580 | 408,900 | 15.5 | 8.4 |
| 70 | 886 | 670 | 593,620 | 17.9 | 11.2 |
| 80 | 1,081 | 760 | 821,560 | 20.3 | 14.4 |
| 90 | 1,289 | 850 | 1,095,650 | 22.7 | 18.0 |
| 99 | 1,486 | 931 | 1,383,466 | 24.8 | 21.6 |

Not: "Saf öldürme süresi" 1.6 sn/öldürme varsayımıyla ~22 saattir. Boss denemeleri, kasaba ziyaretleri, ölümler ve bölge geçişleri ile **gerçek süre Lv 100'e 45-60 saat** (offline ilerleme dahil 2-3 hafta günlük kullanım) hedeflenir.

## 10.3 İlerleme Kilometre Taşları (Hedef Zamanlama)

| Gerçek oyun süresi | Beklenen durum |
|---|---|
| 0-10 dk | Lv 1-5, 3 kahraman, ilk boss (Goblin Şefi) |
| 1 saat | Lv 15, 5 kişilik tam parti, Demirci açık, ilk Nadir itemler |
| 3 saat | Lv 25-30, Perde 1 bitti, ilk Efsanevi (garantili hikaye ödülü) |
| 8 saat | Lv 40-45, Perde 3, 1. Sınıf İlerlemesi tamam (Lv 30) |
| 12 saat | Lv 50, Normal zorluk bitti, Kabus açıldı |
| 25 saat | Lv 70-75, 2. Sınıf İlerlemesi, Kabus bitti, Cehennem açıldı |
| 50 saat | Lv 95-100, Cehennem bitti, Endgame (Kule, Yarıklar) |
| 100+ saat | Paragon, Mitik itemler, set tamamlama, tüm fraksiyonlar |

## 10.4 Puan Kazanımları

| Kaynak | Stat Puanı | Skill Puanı |
|---|---|---|
| Her level | 5 | 1 |
| Her 10. level | +5 bonus | +1 bonus |
| Perde Boss ilk yenilgisi | 0 | +2 |
| Sınıf İlerlemesi | +10 | +3 |
| Paragon level | 0 (Paragon puanı ayrı) | 0 |



# 11. Sınıflar ve Skiller

## 11.1 Sınıf Genel Bakış

Oyunda **8 temel sınıf** vardır. Her sınıfın **3 kademesi** vardır: Temel (Lv 1), 1. İlerleme (Lv 30, Kâhin görevi), 2. İlerleme (Lv 70, Kabus Perde 2 boss'u sonrası). 2. ilerlemede oyuncu iki uzmanlıktan birini seçer (sonradan Kâhin'de altınla değiştirilebilir).

| Sınıf | Rol | Ana Stat | Silahlar | Zırh | 1. İlerleme (Lv30) | 2. İlerleme A / B (Lv70) |
|---|---|---|---|---|---|---|
| Şövalye (Knight) | Tank / Ön hat | STR | Kılıç, Topuz + Kalkan | Ağır | Paladin Adayı | Kutsal Paladin / Kale Muhafızı |
| Barbar (Berserker) | Yakın DPS | STR | İki el Balta, İki el Kılıç | Ağır | Savaş Lordu | Kan Çılgını / Fırtına Reisi |
| Okçu (Archer) | Menzilli DPS | DEX | Yay, Arbalet + Ok Kılıfı | Orta | Avcı | Rüzgâr Nişancısı / Doğa Muhafızı |
| Suikastçı (Assassin) | Tekil hedef DPS | DEX | Çift Hançer, Kısa Kılıç | Orta | Gölge | Gece Bıçağı / Zehir Ustası |
| Büyücü (Mage) | Alan DPS | INT | Asa, Değnek + Küre | Hafif | Elementalist | Ateş Arşmagı / Buz Cadısı |
| Nekromant (Necromancer) | Çağırıcı / DoT | INT | Tırpan, Asa | Hafif | Ruh Bağlayıcı | Kemik Lordu / Veba Getiren |
| Rahibe (Cleric) | İyileştirici | INT/VIT | Topuz, Değnek + Kutsal Kitap | Orta | Başrahibe | Işık Azizi / Savaş Rahibesi |
| Ozan (Bard) | Buff / Destek | INT/VIT | Lavta, Flüt | Hafif | Âşık Usta | Savaş Marşçısı / Huzur Şairi |

## 11.2 Skill Sistemi Kuralları

- Her sınıfın kademe başına skill ağacı vardır: **Temel 6 skill** (2 aktif + 4 pasif), **1. İlerleme +4 skill**, **2. İlerleme +4 skill** (uzmanlığa özel) + **1 Nihai (Ultimate)**.
- Kahraman aynı anda en fazla **3 aktif skill** + **1 nihai** donatabilir (Equip). Pasifler öğrenildiğinde otomatik aktiftir.
- Skill levelleri Skill Puanı ile yükselir (referans: "Lv.3/3", "Lv.0/5", "Lv.10/11"). Bazı skillerin ön koşulu vardır (ör. "Kalkan Darbesi Lv 3").
- Aktif skill cooldown ile çalışır (mana yok). Nihai skill **Öfke barı** ile çalışır: verilen + alınan hasarla dolar, dolunca otomatik patlar.
- Skill paneli: üstte seçili skill büyük ikon + açıklama + bekleme süresi + "Sıfırla" ve "Level Atla" butonları; altında skill ikon ızgarası (referans görseldeki gibi).
- Skill açıklamaları dinamik: "%130 Fiziksel hasar" değeri levele göre güncellenir ve bir sonraki level değeri yeşil gösterilir.

## 11.3 Şövalye (Knight)

**Fantezi:** İmparatorluk ordusunun genç şövalyesi. Kalkanı partinin duvarıdır. **Silüet:** Gümüş zırh, mavi pelerin, kalkan, miğferde kırmızı tüy (1. ilerlemede), altın detaylar (2. ilerlemede).

| Skill | Tür | Max Lv | CD | Etki (Lv1 → Max) |
|---|---|---|---|---|
| Kalkan Darbesi | Aktif | 10 | 8 sn | %140→%320 hasar + 1 sn sersemletme |
| Toparlanma (Recovery) | Aktif | 3 | 15 sn | Tüm müttefiklere max HP'nin %20→%30'u kadar iyileşme |
| Demir Deri | Pasif | 10 | - | +%3→%30 Savunma |
| Meydan Okuma | Pasif | 6 | - | Tehdit +1→+3; ön slotta +%2→%12 HP |
| Kılıç Ustalığı | Pasif | 5 | - | Kılıç/topuz ile +%4→%20 saldırı |
| Son Kale | Pasif | 6 | - | HP %30 altına düşünce 4 sn %20→%50 hasar azaltma (60 sn CD) |
| Kutsal Yemin (İlerleme 1) | Aktif | 10 | 20 sn | 6 sn boyunca partiye Saldırının %50→%150'si kadar kalkan |
| Adalet Kılıcı (İlerleme 1) | Aktif | 10 | 10 sn | Önündeki 3 düşmana %180→%400 Kutsal hasar |
| Kalkan Duvarı (İlerleme 1) | Pasif | 5 | - | Blok şansı +%3→%15 |
| Sarsılmaz (İlerleme 1) | Pasif | 5 | - | Sersemleme/donma süresi -%10→%50 |
| Paladin: Işık Hükmü | Aktif | 10 | 25 sn | Ekrandaki tüm düşmanlara %300→%700 Kutsal, ölümsüzlere x2 |
| Paladin: Aura of Valor | Pasif | 10 | - | Partiye +%2→%20 Saldırı |
| Muhafız: Kale Formu | Aktif | 10 | 30 sn | 8 sn tüm hasarı üstüne çeker, -%40→%70 alınan hasar |
| Muhafız: Diken Zırh | Pasif | 10 | - | Aldığı yakın dövüş hasarının %10→%60'ını yansıtır |
| NİHAİ: İmparatorluk Sancağı | Nihai | 5 | Öfke | 10 sn: parti +%30→%60 hasar, +%20 DR, sancak sprite'ı dikilir |

## 11.4 Barbar (Berserker)

**Fantezi:** Kuzey dağlarından, savaşı şarkı gibi seven iri yarı savaşçı. **Silüet:** Çıplak gövde + kürk omuzluk, iki elli balta, örgülü kızıl sakal/saç, savaş boyası.

| Skill | Tür | Max Lv | CD | Etki |
|---|---|---|---|---|
| Kasırga | Aktif | 10 | 9 sn | 2 sn dönerek çevreye 4 kez %70→%160 hasar |
| Savaş Çığlığı | Aktif | 5 | 18 sn | 8 sn kendine +%15→%40 saldırı hızı |
| Öfke Yükselişi | Pasif | 10 | - | Eksik HP'nin her %10'u için +%1→%4 hasar |
| İki El Ustalığı | Pasif | 5 | - | İki elli silahlarla +%5→%25 saldırı |
| Kana Susamış | Pasif | 6 | - | Can çalma +%0.5→%3 |
| Yaralayıcı | Pasif | 5 | - | Vuruşların %10→%30 şansla Kanama uygular |
| Yer Sarsıntısı (İ1) | Aktif | 10 | 12 sn | Önündeki alana %200→%450 + 0.8 sn sersemleme |
| Atılım (İ1) | Aktif | 10 | 10 sn | En arkadaki düşmana atılır, %160→%360 |
| Delirme (İ1) | Pasif | 5 | - | Kritik vuruşlar %6→%30 öfke barı doldurur |
| Kalın Kafa (İ1) | Pasif | 5 | - | +%4→%20 HP |
| Kan Çılgını: Kızıl Trans | Aktif | 10 | 30 sn | 10 sn +%30→%80 hasar, her saniye %2 HP kaybeder |
| Kan Çılgını: Ölümsüz Öfke | Pasif | 5 | - | Ölümcül hasarda 2→4 sn ölümsüz (120 sn CD) |
| Fırtına Reisi: Gök Gürültüsü | Aktif | 10 | 14 sn | Baltayı vurur, 5 hedefe yayılan %220→%500 Yıldırım |
| Fırtına Reisi: Şimşek Silah | Pasif | 10 | - | Fiziksel hasarın %5→%40'ı ek Yıldırım olarak |
| NİHAİ: Ragnarök | Nihai | 5 | Öfke | Gökten dev balta iner, %800→%2000 alan hasarı |

## 11.5 Okçu (Archer)

**Fantezi:** Orman elfi ırkından sarışın avcı (referans görseldeki Okçu). **Silüet:** Pembe-beyaz hafif zırh, uzun yay, at kuyruğu, ok kılıfı.

| Skill | Tür | Max Lv | CD | Etki |
|---|---|---|---|---|
| Çoklu Atış | Aktif | 10 | 7 sn | 5 ok, her biri %60→%140 |
| Toprak Darbesi (Earth Strike) | Aktif | 5 | 8.2 sn | Yerden dev dikenler, %130→%260 Fiziksel, max 3 hedef, menzil 3.5 |
| Keskin Göz | Pasif | 11 | - | +%1→%11 Kritik Şansı |
| Rüzgâr Adımı | Pasif | 3 | - | +%5→%15 Saldırı Hızı, +%5 kaçınma |
| Delici Oklar | Pasif | 6 | - | %10→%35 şansla ok hedefi deler (ikinci hedefe %50) |
| Avcı İşareti | Pasif | 5 | - | Elit/Boss'a +%4→%20 hasar |
| Ok Yağmuru (İ1) | Aktif | 10 | 15 sn | 3 sn alan, saniyede %80→%180 |
| Bağlayan Sarmaşık (İ1) | Aktif | 10 | 16 sn | 3 düşmanı 2 sn köklendirir + Kırılgan |
| Nişancı (İ1) | Pasif | 5 | - | +%8→%40 Kritik Hasar |
| Hızlı Çekiş (İ1) | Pasif | 5 | - | Skill bekleme -%2→%10 |
| Rüzgâr Nişancısı: Fırtına Oku | Aktif | 10 | 12 sn | Tüm hattı delen dev ok %350→%800 |
| Rüzgâr Nişancısı: Tetik | Pasif | 10 | - | Her 5. normal atış ikili atış |
| Doğa Muhafızı: Kurt Çağır | Aktif | 10 | 30 sn | 20 sn süren kurt yoldaş (saldırının %40→%100'ü) |
| Doğa Muhafızı: Ormanın Lütfu | Pasif | 10 | - | Partiye +%1→%10 HP yenilenme / Toprak skilleri x1.3 |
| NİHAİ: Yıldızkıran Ok | Nihai | 5 | Öfke | Gökyüzünden yıldız yağmuru, %1000→%2400 |

## 11.6 Suikastçı (Assassin)

**Fantezi:** Gölge Loncası'ndan maskeli kadın suikastçı (referans afişteki kırmızı-siyah karakter). **Silüet:** Başlık, yüz maskesi, iki hançer, kırmızı atkı.

| Skill | Tür | Max Lv | CD | Etki |
|---|---|---|---|---|
| Gölge Adımı | Aktif | 10 | 8 sn | En düşük HP'li düşmanın arkasına ışınlanır, %200→%450 |
| Zehirli Bıçak | Aktif | 5 | 10 sn | %120→%240 + 5 yığın Zehir |
| Çift Bıçak Ustalığı | Pasif | 10 | - | +%3→%30 Saldırı Hızı |
| Ölümcül Hassasiyet | Pasif | 10 | - | +%10→%60 Kritik Hasar |
| Sinsi | Pasif | 5 | - | Savaş başında ilk vuruş %100 kritik |
| Zayıf Nokta | Pasif | 5 | - | +%3→%15 Delme |
| Dans Eden Bıçaklar (İ1) | Aktif | 10 | 12 sn | 8 hızlı vuruş, %45→%100 |
| Duman Bombası (İ1) | Aktif | 10 | 20 sn | 4 sn parti kaçınma +%30 |
| İnfaz (İ1) | Pasif | 5 | - | HP'si %20 altındaki düşmana +%10→%50 hasar |
| Gölge Pelerini (İ1) | Pasif | 5 | - | Tehdit -1, kaçınma +%2→%10 |
| Gece Bıçağı: Ay Tutulması | Aktif | 10 | 18 sn | 3 sn gizlenir, sonra %600→%1400 tekil vuruş |
| Gece Bıçağı: Gece Avcısı | Pasif | 10 | - | Gerçek saat gece ise +%5→%25 hasar |
| Zehir Ustası: Veba Bulutu | Aktif | 10 | 15 sn | Zehir alanı, her saniye 2 yığın |
| Zehir Ustası: Zehir Patlaması | Pasif | 10 | - | Zehirli ölen düşman çevresine yığınlarını yayar |
| NİHAİ: Bin Bıçak | Nihai | 5 | Öfke | Ekranda gölge klonlar, %1200→%2800 dağıtılmış |

## 11.7 Büyücü (Mage)

**Fantezi:** Öz Kulesi'nin beyaz saçlı genç büyücüsü (referans afişteki beyaz saçlı karakter). **Silüet:** Sivri şapka, uzun cübbe, ucu parlayan kristal asa.

| Skill | Tür | Max Lv | CD | Etki |
|---|---|---|---|---|
| Ateş Topu | Aktif | 10 | 6 sn | %150→%340 Ateş, küçük patlama, Yanma |
| Buz Mızrağı | Aktif | 10 | 7 sn | %130→%300 Soğuk, delici, 2 yığın Donma |
| Arkana Odak | Pasif | 10 | - | +%4→%40 Büyü Gücü |
| Element Uyumu | Pasif | 6 | - | Tüm element hasarı +%3→%18 |
| Mana Kalkanı | Pasif | 5 | - | Hasarın %5→%25'ini emen kalıcı kalkan (her 10 sn yenilenir) |
| Hızlı Büyü | Pasif | 5 | - | +%4→%20 Büyü Hızı |
| Meteor (İ1) | Aktif | 10 | 18 sn | 1.5 sn gecikmeli, %400→%900 alan Ateş |
| Zincir Şimşek (İ1) | Aktif | 10 | 11 sn | 5 hedefe sekiyor, %140→%320 Yıldırım |
| Element Döngüsü (İ1) | Pasif | 5 | - | Farklı element kullanınca +%4→%20 hasar (5 sn) |
| Öz Pınarı (İ1) | Pasif | 5 | - | Bekleme süresi -%2→%10 |
| Ateş Arşmagı: Cehennem Halkası | Aktif | 10 | 20 sn | Ekranda 5 sn yanan halka, sn başı %150→%350 |
| Ateş Arşmagı: Kor Yüreği | Pasif | 10 | - | Yanma yığın sınırı 3→6 |
| Buz Cadısı: Mutlak Sıfır | Aktif | 10 | 22 sn | Tüm düşmanları 2 sn dondurur + %250→%600 |
| Buz Cadısı: Kristal Zırh | Pasif | 10 | - | Partiye +%2→%20 DR; donmuş düşmanlara +%30 kritik |
| NİHAİ: Arkana Fırtınası | Nihai | 5 | Öfke | Her elementten 12 büyü yağmuru, %1500→%3500 toplam |

## 11.8 Nekromant (Necromancer)

**Fantezi:** Uçurum Tapınağı'ndan sürgün edilmiş, iyi kalpli ama ürkütücü görünen genç. **Silüet:** Mor kukuleta, yeşil alevli tırpan, omzunda küçük kafatası maskotu.

| Skill | Tür | Max Lv | CD | Etki |
|---|---|---|---|---|
| İskelet Çağır | Aktif | 10 | 14 sn | 2→4 iskelet savaşçı (saldırının %30→%60'ı), 15 sn |
| Ruh Çekimi | Aktif | 10 | 9 sn | %140→%300 Kaos + verilen hasarın %10'u kadar parti iyileşmesi |
| Kemik Zırh | Pasif | 6 | - | Her çağrılan yaratık +%2→%6 DR |
| Karanlık Bilgi | Pasif | 10 | - | +%3→%30 Kaos Hasarı |
| Ceset Patlatma | Pasif | 5 | - | Ölen düşmanlar %10→%30 şansla patlar (max HP %15 alan hasarı) |
| Lanet | Pasif | 5 | - | Saldırılar 4 sn Zayıflatma uygular |
| Kemik Mızrağı (İ1) | Aktif | 10 | 8 sn | Delici, %180→%400 Fiziksel |
| Ölüm Laneti (İ1) | Aktif | 10 | 16 sn | Hedef 6 sn Kırılgan + Kaos direnci -%20 |
| Lejyon (İ1) | Pasif | 5 | - | Max çağrı +1→+3 |
| Ruh Hasadı (İ1) | Pasif | 5 | - | Her öldürme öfke barını +%1→%3 doldurur |
| Kemik Lordu: Kemik Golem | Aktif | 10 | 40 sn | Kalıcı golem (tank, tehdit +3) |
| Kemik Lordu: Kemik Hükümdarı | Pasif | 10 | - | Çağrılar +%5→%50 hasar ve HP |
| Veba Getiren: Kara Ölüm | Aktif | 10 | 14 sn | Tüm düşmanlara 5 yığın Zehir + yayılma |
| Veba Getiren: Çürüme | Pasif | 10 | - | Zehir hasarı +%5→%60 |
| NİHAİ: Ölüler Ordusu | Nihai | 5 | Öfke | 12 sn boyunca 10 hayalet asker hücum eder |

## 11.9 Rahibe (Cleric)

**Fantezi:** Kutsal Krallık'tan neşeli, sarı saçlı rahibe (referans afişteki sarışın küçük karakter). **Silüet:** Beyaz-altın cübbe, başında hale, büyük kutsal kitap, kısa topuz.

| Skill | Tür | Max Lv | CD | Etki |
|---|---|---|---|---|
| Şifa Işığı | Aktif | 10 | 5 sn | En düşük HP'li müttefik %120→%300 Büyü Gücü iyileşme |
| Kutsal Şimşek | Aktif | 10 | 8 sn | %130→%280 Kutsal hasar, ölümsüzlere x2 |
| Kutsal Bilgelik | Pasif | 10 | - | İyileştirme +%3→%30 |
| Koruyucu Melek | Pasif | 5 | - | Ölen müttefik 15→7 sn'de dirilir |
| Kutsama | Pasif | 6 | - | Partiye +%1→%6 Savunma ve tüm direnç |
| Arınma | Pasif | 3 | - | İyileştirme durum etkilerini temizler (Lv3: 2 etki) |
| Toplu Şifa (İ1) | Aktif | 10 | 15 sn | Tüm parti %80→%180 iyileşme |
| Işık Kalkanı (İ1) | Aktif | 10 | 12 sn | Ön slottakine %200→%500 kalkan |
| Diriliş (İ1) | Pasif | 1 | - | 90 sn'de bir ölen müttefiği anında diriltir |
| Lütuf (İ1) | Pasif | 5 | - | İyileştirilen müttefik 3 sn +%2→%10 hasar |
| Işık Azizi: Cennet Kapısı | Aktif | 10 | 30 sn | 6 sn parti her sn %10→%25 iyileşir |
| Işık Azizi: Mucize | Pasif | 10 | - | İyileştirmeler %5→%25 kritik yapabilir (x2) |
| Savaş Rahibesi: Kutsal Topuz | Aktif | 10 | 9 sn | %220→%500 Kutsal + parti iyileşmesi hasarın %20'si |
| Savaş Rahibesi: İnanç Gücü | Pasif | 10 | - | Büyü Gücünün %10→%60'ı Saldırı olarak eklenir |
| NİHAİ: Tanrıça'nın Gözyaşı | Nihai | 5 | Öfke | Tüm parti tam iyileşir + 5→10 sn ölümsüzlük |

## 11.10 Ozan (Bard)

**Fantezi:** Gezgin, şakacı, tüylü şapkalı genç. Kahramanlara moral verir. **Silüet:** Yeşil-turuncu kıyafet, tüylü şapka, sırtta lavta, nota parçacıkları.

| Skill | Tür | Max Lv | CD | Etki |
|---|---|---|---|---|
| Cesaret Şarkısı | Aktif | 10 | 20 sn | 10 sn partiye +%10→%30 hasar |
| Uyumsuz Akor | Aktif | 10 | 9 sn | %120→%260 Yıldırım alan + Şok |
| Ritim | Pasif | 10 | - | Partiye +%1→%10 Saldırı Hızı |
| Neşe | Pasif | 5 | - | Partiye +%2→%10 XP bonusu |
| Hızlı Parmaklar | Pasif | 5 | - | Buff süresi +%5→%25 |
| Şans Melodisi | Pasif | 6 | - | Partiye +%3→%18 Item Bulma |
| Ninni (İ1) | Aktif | 10 | 18 sn | 3 düşmanı 1.5→3 sn uyutur |
| Kahramanlık Destanı (İ1) | Aktif | 10 | 25 sn | 8 sn tüm parti skill bekleme -%30 |
| Koro (İ1) | Pasif | 5 | - | Aynı anda 2 şarkı aktif olabilir |
| Altın Ses (İ1) | Pasif | 5 | - | +%4→%20 Altın Bulma |
| Savaş Marşçısı: Davul Gürültüsü | Aktif | 10 | 20 sn | 10 sn parti +%15→%40 kritik hasar ve hız |
| Savaş Marşçısı: Marş | Pasif | 10 | - | Cesaret Şarkısı etkisi x1.5 |
| Huzur Şairi: Huzur Melodisi | Aktif | 10 | 18 sn | 6 sn sn başı %3→%8 parti iyileşmesi + durum temizleme |
| Huzur Şairi: Sükunet | Pasif | 10 | - | Parti +%2→%15 tüm direnç |
| NİHAİ: Efsanelerin Şarkısı | Nihai | 5 | Öfke | 12 sn: tüm parti nihai barı x2 hızla dolar, +%40 tüm hasar |

## 11.11 Sınıf Sinerjileri (Parti Bonusları)

Belirli sınıf kombinasyonları ek bonus verir (Parti panelinde ikonla gösterilir):

| Sinerji | Gereken | Bonus |
|---|---|---|
| Kutsal Üçlü | Şövalye + Rahibe + Ozan | +%10 tüm parti HP |
| Element Fırtınası | Büyücü + Okçu (Doğa) veya Barbar (Fırtına) | +%10 element hasarı |
| Gölgeler | Suikastçı + Nekromant | +%8 kritik şansı |
| Demir Duvar | 2 Ağır zırh sınıfı ön slotta | +%10 Savunma |
| Tam Orkestra | 5 farklı sınıf | +%5 tüm statlar, +%10 XP |
| Aynı Sınıf x2 | 2 aynı sınıf | -%5 (çeşitliliği teşvik) |



# 12. Kahramanlar ve Fraksiyonlar

## 12.1 Kahraman Sistemi Nedir?

- Sınıf = savaş tarzı (skill ağacı). **Kahraman** = o sınıfı kullanan **benzersiz bir karakter** (isim, görünüm, kişilik, imza pasifi, hikaye).
- Oyuncu başlangıçta 3 kahraman alır (Kael - Şövalye, Lyra - Okçu, Pip - Rahibe), hikaye boyunca 2 kahraman daha katılır, geri kalanı **Taverna** (meyhane) üzerinden toplanır.
- Aktif parti 5 kahramandır; diğerleri yedekte "Antrenman XP" alır.
- **Taverna:** Boss'lardan düşen **Taverna Mührü** ve altın ile kahraman çağrılır. Gacha **yoktur**: Taverna her 4 saatte 3 kahraman teklif eder (mevcut ilerlemeye uygun), oyuncu birini satın alır. Kopya kahraman çıkmaz.
- **Yıldız (Star) sistemi:** Kahramanlar 1-6 yıldız. Yıldız, **Ruh Parçası** ile yükselir (kahramanı partide kullandıkça ve boss'lardan düşer). Her yıldız: +%8 taban stat, 3 ve 6 yıldızda imza pasifi güçlenir.
- Nadirlik: **R** (Nadir), **SR** (Süper Nadir), **SSR** (Efsanevi Kahraman). Nadirlik sadece imza pasifinin gücünü ve başlangıç yıldızını belirler (R:1, SR:2, SSR:3). Tüm kahramanlar max seviyeye ulaşabilir; zayıf kahraman yoktur.

## 12.2 Fraksiyonlar ve Koleksiyon Bonusu

Referans "Faction" penceresindeki gibi, kahramanlar fraksiyonlara ayrılır. Bir fraksiyondan sahip olunan kahraman sayısı **kalıcı hesap bonusu** verir (partide olmasalar bile).

| Fraksiyon | Tema | Renk | Koleksiyon Bonusu (her 2 kahramanda) | Tam Set Bonusu (8/8) |
|---|---|---|---|---|
| İmparatorluk | Şövalyeler, askerler, soylular | Kızıl-altın | +%2.5 Saldırı | +%5 tüm hasar, Sancak kostümü |
| Kutsal Krallık | Rahipler, paladinler, melek soylu | Beyaz-altın | +%2.5 HP | Diriliş süresi -%30 |
| Öz Kulesi | Büyücüler, simyacılar, âlimler | Mavi-mor | +1.5 Savunma / +%2 Büyü Gücü | Bekleme süresi -%5 |
| Uçurum Tapınağı | Nekromantlar, kültistler, iblis kanlı | Mor-yeşil | +%2 Kaos hasarı | Kaos direnci +%15 |
| Vahşi Diyarlar | Barbarlar, elfler, hayvan dostları | Yeşil-kahve | +%2 Saldırı Hızı | Evcil hayvan hasarı +%25 |
| Gölge Loncası | Suikastçılar, hırsızlar, ozanlar | Siyah-kırmızı | +%2 Altın ve Item Bulma | Mitik drop şansı +%10 |

## 12.3 Kahraman Listesi (48 Kahraman)

Görünüm sütunu, sanat AI için **sınıf temel sprite'ına uygulanacak varyant**ı tanımlar (saç, renk paleti, aksesuar).

### İmparatorluk (8)

| Ad | Sınıf | Nad. | Görünüm (pixel brief) | İmza Pasif |
|---|---|---|---|---|
| Kael | Şövalye | R | Siyah dağınık saç, gümüş zırh, mavi pelerin (başlangıç kahramanı) | "Genç Kaptan": Parti +%5 HP |
| Aurelia | Şövalye | SSR | Uzun altın saç, beyaz-altın zırh, kırmızı pelerin, taç | "İmparatoriçenin Emri": Nihai %25 daha hızlı dolar |
| Gareth | Barbar | SR | Kel, kalın bıyık, imparatorluk lejyoner zırhı, iki el kılıç | "Veteran": Elitlere +%20 hasar |
| Cassia | Okçu | SR | Kızıl kısa saç, deri ceket, arbalet, monokl | "Keskin Nişancı": İlk atış her dalgada kritik |
| Leon | Ozan | R | Sarı kıvırcık saç, soylu kıyafet, mor tüylü şapka | "Saray Ozanı": Altın Bulma +%15 |
| Marcus | Rahibe (Savaş Rahibi) | R | Kahverengi tonsür, zincir zırh üstü beyaz tabard | "Ordu Rahibi": İyileştirme +%10 ön slota |
| Vesper | Büyücü | SR | Mor topuz saç, imparatorluk akademi üniforması, gözlük | "Akademisyen": Skill hasarı +%12 |
| General Draven | Şövalye | SSR | Gri sakal, siyah-kızıl ağır zırh, yara izi | "Ordu Komutanı": Tüm parti +%8 Saldırı |

### Kutsal Krallık (8)

| Ad | Sınıf | Nad. | Görünüm | İmza Pasif |
|---|---|---|---|---|
| Pip | Rahibe | R | Sarı iki topuz saç, büyük beyaz başlık, kocaman kitap (başlangıç) | "Neşeli Dua": İyileştirme +%10 |
| Seraphina | Rahibe | SSR | Uzun beyaz saç, altın hale, küçük melek kanatları | "Melek Lütfu": Koruyucu Melek bekleme -%40 |
| Tristan | Şövalye | SR | Kısa kumral saç, beyaz paladin zırhı, mavi detay | "Kutsal Kalkan": Blok başına partiye küçük iyileşme |
| Elowen | Okçu | R | Açık kahve örgü, beyaz-mavi rahip-avcı kıyafeti, gümüş yay | "Işık Oku": Oklar %20 Kutsal hasar ekler |
| Brother Oswin | Ozan | R | Tombul, kel, keşiş cübbesi, el çanı (lavta yerine) | "İlahi": Parti HP yenilenme +%15 |
| Lucia | Büyücü | SR | Altın kısa saç, beyaz-altın büyücü cübbesi, güneş asası | "Güneş Ateşi": Ateş büyüleri Kutsal da sayılır |
| Inquisitor Hale | Suikastçı | SR | Siyah şapka, beyaz maske, gümüş hançer | "Engizisyon": Ölümsüz/şeytanlara +%30 hasar |
| King Aldric | Şövalye | SSR | Taç, beyaz sakal, kraliyet mavi pelerin, efsanevi kılıç | "Krallığın Kalkanı": Parti +%10 DR |

### Öz Kulesi (8)

| Ad | Sınıf | Nad. | Görünüm | İmza Pasif |
|---|---|---|---|---|
| Nova | Büyücü | R | Beyaz uzun saç, mavi sivri şapka, kristal asa (hikaye kahramanı, Lv 6'da katılır) | "Öz Akışı": Büyü Hızı +%10 |
| Archmage Thalos | Büyücü | SSR | Uzun beyaz sakal, yıldızlı mor cübbe, yüzen kitaplar | "Bilgelik": Tüm parti +%10 skill hasarı |
| Fizz | Ozan | SR | Kısa boylu gnom, mühendis gözlüğü, mekanik lavta | "Mekanik Ritim": Saldırı Hızı buff'ları +%20 |
| Iris | Okçu | SR | Mavi bob saç, kristal yay, yüzen ok küreleri | "Kristal Oklar": Oklar Soğuk hasar + Donma |
| Mordecai | Nekromant | R | Solgun, siyah uzun saç, kule âlimi cübbesi | "Yasak Bilgi": Çağrılar +%15 HP |
| Selene Ashveil | Rahibe | SR | Gümüş saç, ay temalı lacivert cübbe | "Ay Işığı": Gece iyileştirme +%25 |
| Rook | Şövalye | R | Golem-zırhlı çocuk, rün parlayan iri eldiven | "Rün Zırh": Element direnci +%10 |
| Zephyr | Suikastçı | SSR | Rüzgâr büyücüsü, uçuşan atkı, rüzgâr hançerleri | "Rüzgâr Kesik": %15 şansla ikinci vuruş Yıldırım |

### Uçurum Tapınağı (8)

| Ad | Sınıf | Nad. | Görünüm | İmza Pasif |
|---|---|---|---|---|
| Vex | Nekromant | R | Mor kukuleta, yeşil alevli tırpan, omzunda kafatası "Bonbon" | "Küçük Kafatası": Ölen düşmanlar %5 şansla iskelet olur |
| Lilith | Büyücü | SSR | Uzun siyah saç, küçük boynuzlar, kırmızı gözler, kara alev | "İblis Kanı": Kaos hasarı +%25, can çalma +%2 |
| Morrigan | Suikastçı | SR | Karga tüylü pelerin, siyah maske, mor hançerler | "Karga Sürüsü": Kritikte hedefe karga sürüsü (%40 ek) |
| Grimm | Barbar | SR | İri, mor deri, tek boynuz, zincirli balta | "Lanetli Güç": Düşük HP'de +%30 saldırı hızı |
| Sister Nyx | Rahibe | R | Siyah rahibe kıyafeti, mor hale (ters) | "Karanlık Şifa": İyileştirme hedefe Kaos direnci verir |
| Malakar | Nekromant | SSR | İskelet yüz maskesi, kemik taç, kemik asa | "Kemik Kral": Max çağrı +2 |
| Ezra | Ozan | R | Solgun yüz, hayalet lavta, mor duman | "Ağıt": Düşmanlar -%10 hasar verir |
| Kharon | Şövalye | SR | Kara zırh, mor alevli kalkan, kukuleta | "Ölüm Kapısı": Ölümcül hasarı 1 kez önler (savaş başına) |

### Vahşi Diyarlar (8)

| Ad | Sınıf | Nad. | Görünüm | İmza Pasif |
|---|---|---|---|---|
| Lyra | Okçu | R | Sarı at kuyruğu, sivri elf kulakları, pembe-beyaz zırh (başlangıç) | "Elf Gözü": Kritik şansı +%5 |
| Bjorn | Barbar | R | Kızıl örgülü sakal, kurt kürkü, iki el balta (hikaye, Lv 12) | "Kuzey Öfkesi": Kasırga +1 dönüş |
| Thorne | Okçu | SSR | Yeşil saçlı druid-avcı, boynuz taç, yaşayan yay | "Ormanın Kalbi": Doğa skilleri +%30, evcil +%20 |
| Kira | Suikastçı | SR | Kedi kulaklı, turuncu saç, pençe hançer | "Kedi Çevikliği": Kaçınma +%12 |
| Ursa | Şövalye | SR | Ayı kürkü zırh, ahşap dev kalkan, iri kadın savaşçı | "Ayı Gücü": Max HP +%15 |
| Oakheart | Rahibe | R | Ağaç ruhu (dryad), yapraklı saç, kök asa | "Fotosentez": Gündüz iyileştirme +%20 |
| Raka | Barbar | SSR | Kaplan dövmeli, beyaz saç, çift kısa balta | "Avcı Kral": Her öldürme 3 sn +%5 hasar (5 yığın) |
| Fern | Ozan | SR | Küçük peri, yaprak kanatlar, flüt | "Orman Şarkısı": Evcil hayvan +%30 hasar |

### Gölge Loncası (8)

| Ad | Sınıf | Nad. | Görünüm | İmza Pasif |
|---|---|---|---|---|
| Raven | Suikastçı | R | Siyah kısa saç, kırmızı atkı, yüz maskesi | "Lonca Bıçağı": Kritik hasarı +%20 |
| Nyxara | Suikastçı | SSR | Uzun mor saç, gölge pelerin, ay hançerleri | "Gölge Kraliçesi": Gece +%30 tüm hasar |
| Finn | Ozan | R | Kıvırcık kahve saç, tüylü şapka, lavta (hikaye, Lv 20) | "Hırsız Şarkısı": Item Bulma +%15 |
| Silas | Okçu | SR | Göz bandı, korsan şapkası, arbalet | "Altın Avcısı": Elitler 2x altın düşürür |
| Dahlia | Nekromant | SR | Kırmızı gül süslü kukuleta, kemik yelpaze | "Kanlı Gül": Kanama hasarı +%30 |
| Old Mags | Rahibe | R | Yaşlı şifacı kadın, bastonlu, iksir kemerli | "Şifalı Otlar": Tüm iyileştirme +%8, iksir etkisi x2 |
| Viktor | Barbar | R | Dazlak, altın dişli, zincir eldiven | "Sokak Dövüşçüsü": Kalabalık dalgalarda +%15 |
| The Masked One | Büyücü | SSR | Porselen maske, smokin, kart destesi (büyü kartları) | "Şans Kartı": Her büyü %10 şansla x3 hasar |

## 12.4 Kahraman Kişilikleri (Bark Sistemi)

- Her kahramanın 30-50 kısa replik (max 40 karakter) vardır: konuşma balonu 3 sn, oyuncu ayarlardan sıklığı seçer (Kapalı / Az / Normal).
- Tetikleyiciler: `on_level_up`, `on_legendary_drop`, `on_boss_spawn`, `on_ally_death`, `on_idle_long` (oyuncu 1 saat dokunmadı), `on_night_start`, `on_return` (offline dönüş), `on_pair` (iki belirli kahraman partideyse özel diyalog).
- Örnek: Pip: "Dua ettim, item düştü! Tesadüf mü?" / Vex: "Bonbon bu iskeleti beğendi." / Bjorn: "DAHA FAZLA GOBLİN!" / Lyra (gece): "Yıldızlar nişan almama yardım ediyor."


# 13. Evcil Hayvanlar (Pets)

- 1 aktif evcil hayvan partinin arkasında uçar/yürür (referans görseldeki anka kuşu gibi). Saldırır ve pasif bonus verir.
- Evcil hayvanlar boss'lardan "Yumurta" olarak düşer, 30 dk gerçek zamanda çatlar (offline da işler).
- Seviye 1-30, kendi XP'si; **Evcil Hayvan Mamısı** ile beslenir.

| Pet | Nasıl alınır | Saldırı | Pasif (max lv) |
|---|---|---|---|
| Alev Yavrusu (Anka) | Perde 1 Boss | Ateş topu | Parti Ateş hasarı +%15 |
| Kar Tilkisi | Perde 2 Boss | Buz ısırığı | Soğuk direnci +%20, Donma şansı |
| Mekanik Baykuş | Öz Kulesi koleksiyon 4/8 | Lazer | Item Bulma +%20 |
| Yarasa Çetesi | Gece bölgeleri (nadir) | Can emme | Can çalma +%2 |
| Altın Slime | %0.1 her öldürme | Zıplama | Altın Bulma +%40 |
| Mini Golem | Demirci Lv 20 | Taş fırlatma | Savunma +%10 |
| Peri Fener | Vahşi Diyarlar 4/8 | Işık oku | HP yenilenme +%20 |
| Gölge Kedi | Gölge Loncası 4/8 | Pençe | Kritik şansı +%5 |
| Bebek Ejder | Perde 4 Boss (Cehennem) | Alev nefesi | Tüm hasar +%10 |
| Kristal Kaplumbağa | Kule 50. kat | Kalkan | Parti DR +%5 |
| Kafatası Bonbon | Vex 6 yıldız | Kemik | Çağrı +1 |
| Yıldız Balinası | Paragon 100 | Kuyruklu yıldız | XP +%25 |


# 14. Gelişim (Growth) Sistemleri

"Gelişim" butonu kalıcı hesap güçlendirmelerini toplar.

## 14.1 Lonca Salonu (Kalıcı Yetenek Ağacı)

- Altın + **Lonca Nişanı** (boss'lardan) ile yükseltilir. 5 dal, her dalda 8 düğüm, her düğüm 1-10 level.

| Dal | Örnek Düğümler |
|---|---|
| Savaş | Tüm hasar +%2/lv, Kritik +%0.5/lv, Boss hasarı +%3/lv |
| Savunma | HP +%2/lv, DR +%0.5/lv, Diriliş -1 sn/lv |
| Servet | Altın +%3/lv, Satış fiyatı +%2/lv, Demirci maliyeti -%2/lv |
| Zaman | Offline verim +%4/lv (max %100), Offline limit +1 saat/lv (max 24), Bölge geçiş hızı |
| Keşif | Item Bulma +%3/lv, Efsanevi şansı +%1/lv (çarpımsal), Yedek kahraman XP +%5/lv |

## 14.2 Fraksiyon Koleksiyonu

Bölüm 12.2. Panelde her fraksiyon listesi, toplanmamış kahramanlar gri silüet (referans görseldeki gibi). Tıklayınca nereden alınacağı yazar.

## 14.3 Kostümler

- Kahraman paneli altında **Skill / Kostüm** sekmesi (referans). Kostümler şeritteki sprite görünümünü ve portreyi değiştirir.
- Kaynak: Başarımlar, etkinlikler, set tamamlama, Steam DLC (Supporter Pack: 6 kostüm), Paragon.
- Kostüm etkisi: Sadece görsel + küçük koleksiyon bonusu (her 5 kostüm +%1 XP). Pay-to-win yok.

## 14.4 Kodeks (Ansiklopedi)

- Öldürülen her canavar türü, bulunan her efsanevi/set item kodekse kaydedilir. Her kayıt için: ilk bulma +küçük bonus (canavar türüne +%1 hasar, max %10 per tür; her 10 efsanevi kayıt +%1 item bulma).

## 14.5 Başarımlar

Oyun içi başarımlar Steam başarımlarıyla eşleşir (Bölüm 22.2), ek olarak oyun içi küçük ödüller (altın, kostüm, unvan).



# 15. Ekipman Sistemi

## 15.1 Ekipman Slotları (Kahraman başına 12)

Referans "Inventory" panelinin üstündeki ekipman ızgarası gibi:

| Slot | Örnek | Ana stat (implicit) |
|---|---|---|
| Ana El (Silah) | Kılıç, yay, asa | Silah Hasarı (Saldırı), APS |
| Yan El | Kalkan, ok kılıfı, küre, kutsal kitap | Blok / Kritik / Büyü Gücü |
| Kask | Miğfer, başlık, şapka | Savunma, HP |
| Gövde | Zırh, ceket, cübbe | Savunma, HP |
| Eldiven | | Savunma + Saldırı Hızı şansı |
| Bot | | Savunma + Hareket Hızı |
| Kemer | | HP, Yan iksir kapasitesi |
| Pelerin | | Kaçınma / Direnç |
| Kolye | | Rastgele güçlü stat |
| Yüzük x2 | | Rastgele stat |
| Tılsım | Rün, kutsal emanet | Benzersiz pasif (sadece Destansı+) |

İki özel "Hızlı Kullanım" slotu: otomatik iksirler (HP %35 altına düşünce içilir; bekleme süreleri envanterde "4.4s" gibi görünür).

## 15.2 Item Nadirliği ve Affix Sayısı

| Nadirlik | Affix | Drop oranı (taban) | Satış (altın çarpanı) | Not |
|---|---|---|---|---|
| Sıradan | 0 | %70 | x1 | Sadece taban stat |
| Büyülü | 1-2 | %22 | x3 | |
| Nadir | 3-4 | %6.5 | x8 | |
| Destansı | 4-5 | %1.2 | x20 | 1 soket şansı |
| Efsanevi | 4 + benzersiz etki | %0.25 | x50 | Sabit isimli, özel etki |
| Set | 3 + set bonusu | %0.05 | x50 | Set parçası |
| Mitik | 6 + benzersiz + 1 "Mitik affix" | %0.005 (sadece Cehennem+) | x200 | Endgame avı |

- Drop oranları Item Bulma (IF) ile ölçeklenir: `p_rarity_final = p_rarity x (1 + IF% x RarityWeight)` (Nadir 1.0, Destansı 0.7, Efsanevi 0.5, Set/Mitik 0.35).
- Her canavar öldürmede item düşme şansı: Normal %8, Elit %60 (+1 garanti Büyülü+), Boss %100 x3 item (1 Nadir+ garanti), Perde Boss x5 (1 Destansı+ garanti).
- **Akıllı loot:** Düşen itemlerin %60'ı partideki sınıfların kullanabildiği türlerden seçilir.

## 15.3 Item Level ve Kademeler

- Item Level (iLvl) = canavar seviyesi. Affix aralıkları iLvl'ye bağlı **7 kademe (T1-T7)** ile belirlenir.
- Taban item türleri 7 kademe görünüme sahiptir (gereken level: 1, 12, 25, 40, 55, 70, 85). Daha yüksek kademe = daha güçlü taban stat + farklı ikon.

| Kademe | Gereken Lv | Taban stat çarpanı | Görsel |
|---|---|---|---|
| T1 | 1 | 1.0 | Demir/ahşap, sade |
| T2 | 12 | 1.8 | Çelik, küçük detay |
| T3 | 25 | 3.2 | Süslü, renkli kumaş |
| T4 | 40 | 5.5 | Gümüş/mitril, parlak taş |
| T5 | 55 | 9.0 | Altın kakmalı, rün |
| T6 | 70 | 14.0 | Elementel parıltı, efekt pikseli |
| T7 | 85 | 21.0 | Efsanevi malzemeler, animasyonlu ikon (2 kare parıltı) |

## 15.4 Silahlar (Tüm Taban Türleri)

Silah hasarı formülü: `WeaponATK = BaseATK x TierMult x (1 + 0.02 x (iLvl - TierReqLvl))`

| Tür | Sınıflar | El | APS | BaseATK | Implicit |
|---|---|---|---|---|---|
| Kılıç | Şövalye, Suikastçı | Tek | 1.15 | 10 | +%5 Kritik Hasarı |
| Topuz | Şövalye, Rahibe | Tek | 1.05 | 11 | %5 Sersemletme şansı |
| İki El Kılıç | Barbar, Şövalye | Çift | 0.90 | 18 | +%10 Kritik Hasarı |
| İki El Balta | Barbar | Çift | 0.85 | 20 | %8 Kanama şansı |
| Hançer | Suikastçı | Tek (çift taşınır) | 1.50 | 7 | +%3 Kritik Şansı |
| Yay | Okçu | Çift | 1.00 | 14 | +%5 Saldırı Hızı |
| Arbalet | Okçu | Çift | 0.80 | 19 | +%8 Delme |
| Asa | Büyücü, Nekromant | Çift | 0.85 | 16 | +%15 Büyü Gücü |
| Değnek | Büyücü, Rahibe | Tek | 1.00 | 10 | +%8 Büyü Hızı |
| Tırpan | Nekromant | Çift | 0.90 | 17 | +%10 Kaos Hasarı |
| Lavta | Ozan | Çift | 1.00 | 12 | +%8 Buff Süresi |
| Flüt | Ozan | Tek | 1.10 | 9 | +%5 Bekleme Azaltma |

**Silah isimleri (kademe sırasıyla T1→T7):**

| Tür | T1 | T2 | T3 | T4 | T5 | T6 | T7 |
|---|---|---|---|---|---|---|---|
| Kılıç | Paslı Kılıç | Lejyoner Kılıcı | Şövalye Kılıcı | Mitril Uzun Kılıç | Rün Kılıcı | Ejder Dişi Kılıcı | Yıldız Çeliği |
| Topuz | Sopa | Demir Topuz | Yıldız Topuz | Kutsal Topuz | Rünlü Gürz | Gök Gürzü | Tanrı Çekici |
| İki El Kılıç | Ağır Kılıç | Claymore | Cellat Kılıcı | Dev Kılıç | Titan Kılıcı | Ejder Avcısı | Dünya Yaran |
| İki El Balta | Oduncu Baltası | Savaş Baltası | Kuzey Baltası | Çift Ağızlı Balta | Kan Baltası | Fırtına Baltası | Ragnarök Baltası |
| Hançer | Mutfak Bıçağı | Hançer | Kıvrık Hançer | Gölge Bıçağı | Ay Hançeri | Hiçlik Dişi | Kader Kesici |
| Yay | Kısa Yay | Av Yayı | Uzun Yay | Elf Yayı | Rüzgâr Yayı | Anka Yayı | Göksel Yay |
| Arbalet | Hafif Arbalet | Askerî Arbalet | Ağır Arbalet | Tekrarlı Arbalet | Rünlü Arbalet | Ejder Arbaleti | Yıldız Atar |
| Asa | Çırak Asası | Meşe Asa | Kristal Asa | Âlim Asası | Arşmag Asası | Element Asası | Sonsuzluk Asası |
| Değnek | Dal Değnek | Kemik Değnek | Ametist Değnek | Mühürlü Değnek | Ay Değneği | Güneş Değneği | Yaratılış Değneği |
| Tırpan | Orak | Mezarcı Tırpanı | Kemik Tırpan | Ruh Hasatçısı | Kara Tırpan | Uçurum Tırpanı | Ölümün Kendisi |
| Lavta | Eski Lavta | Gezgin Lavtası | Saray Lavtası | Gümüş Lavta | Ezgi Lavtası | Fırtına Lavtası | Efsane Lavtası |
| Flüt | Kamış Flüt | Ahşap Flüt | Gümüş Flüt | Peri Flütü | Rüya Flütü | Ruh Flütü | Göksel Flüt |

**Yan el itemleri (T1→T7):**

| Tür | Sınıflar | T1 | T3 | T5 | T7 | Implicit |
|---|---|---|---|---|---|---|
| Kalkan | Şövalye | Ahşap Kalkan | Kule Kalkanı | Rün Kalkanı | Aegis | +Blok %5-15 |
| Ok Kılıfı | Okçu | Deri Kılıf | Avcı Kılıfı | Rüzgâr Kılıfı | Sonsuz Sadak | +Kritik %2-6 |
| Küre | Büyücü, Nekromant | Cam Küre | Kristal Küre | Öz Küresi | Kozmos Küresi | +Büyü Gücü %5-20 |
| Kutsal Kitap | Rahibe | Dua Kitabı | İlahi Kitap | Aziz Kodeksi | Yaratılış Kitabı | +İyileştirme %5-20 |
| Yan Hançer | Suikastçı | Bıçak | Gölge Bıçak | Ay Bıçağı | Kader Bıçağı | +Saldırı Hızı %4-12 |

## 15.5 Zırhlar

Üç ağırlık sınıfı: **Ağır** (Şövalye, Barbar) +Savunma, **Orta** (Okçu, Suikastçı, Rahibe) +Kaçınma/denge, **Hafif** (Büyücü, Nekromant, Ozan) +Büyü Gücü/direnç.

| Ağırlık | Savunma çarpanı | Ek implicit |
|---|---|---|
| Ağır | x1.5 | +%HP |
| Orta | x1.0 | +Kaçınma |
| Hafif | x0.6 | +Büyü Gücü veya +Tüm direnç |

**Gövde zırhı isimleri:**

| Kademe | Ağır | Orta | Hafif |
|---|---|---|---|
| T1 | Zincir Gömlek | Yastıklı Ceket | Keten Cübbe |
| T2 | Pullu Zırh | Deri Zırh | Çırak Cübbesi |
| T3 | Plaka Zırh | Avcı Yeleği | Büyücü Cübbesi |
| T4 | Mitril Plaka | Gölge Deri | Yıldızlı Cübbe |
| T5 | Rün Plakası | Ejder Derisi Zırh | Arşmag Cübbesi |
| T6 | Titan Zırhı | Fırtına Postu | Element Örtüsü |
| T7 | Göksel Plaka | Gece Postu | Sonsuzluk Cübbesi |

**Kask / Eldiven / Bot / Kemer / Pelerin (örnek isimler):**

| Kademe | Kask (Ağır/Orta/Hafif) | Eldiven | Bot | Kemer | Pelerin |
|---|---|---|---|---|---|
| T1 | Demir Miğfer / Deri Başlık / Keten Şapka | Deri Eldiven | Deri Çizme | İp Kuşak | Yırtık Pelerin |
| T2 | Lejyoner Miğferi / Avcı Başlığı / Çırak Şapkası | Zincir Eldiven | Asker Çizmesi | Deri Kemer | Gezgin Pelerini |
| T3 | Şövalye Miğferi / Gölge Başlık / Büyücü Şapkası | Plaka Eldiven | Plaka Çizme | Ağır Kemer | Şövalye Pelerini |
| T4 | Mitril Miğfer / Kuzgun Maskesi / Yıldız Şapkası | Mitril Eldiven | Rüzgâr Çizmesi | Mitril Kuşak | Gece Pelerini |
| T5 | Rün Miğferi / Ejder Başlığı / Arşmag Tacı | Rün Eldiven | Rün Çizme | Şampiyon Kemeri | Kraliyet Pelerini |
| T6 | Titan Miğferi / Fırtına Maskesi / Element Tacı | Titan Pençesi | Fırtına Adımı | Titan Kuşağı | Anka Pelerini |
| T7 | Göksel Miğfer / Gece Kralı Maskesi / Kozmos Tacı | Tanrı Eldiveni | Göksel Adım | Sonsuzluk Kuşağı | Yıldız Pelerini |

**Takılar:** Kolye (Bakır Kolye → Gümüş → Altın → Yakut Muska → Ejder Gözü → Anka Tüyü Kolye → Yıldız Kalbi), Yüzük (Bakır Halka → Gümüş → Altın → Safir → Rün → Element → Kader Yüzüğü), Tılsım (sadece Destansı+: Rün Taşı, Kutsal Emanet, Kafatası Fetişi, Ay Taşı).

## 15.6 Affix Havuzu

Ön ek (Prefix) = saldırı/savunma sayıları; Son ek (Suffix) = yüzde ve yardımcılar. Bir item en fazla 3 prefix + 3 suffix taşır. Değer aralıkları T7 için verilmiştir; düşük kademeler oransal (T1 = T7 x 0.12, T2 0.2, T3 0.32, T4 0.46, T5 0.62, T6 0.8).

| Affix | Tip | Slotlar | T7 Aralığı |
|---|---|---|---|
| +Saldırı (düz) | Prefix | Silah, Yüzük, Kolye, Eldiven | 180-260 |
| +% Fiziksel Hasar | Prefix | Silah | %60-90 |
| +% Ateş / Soğuk / Yıldırım / Kaos Hasarı | Prefix | Silah, Kolye, Yan el | %40-65 |
| +Büyü Gücü | Prefix | Silah, Yan el, Kolye | 160-240 |
| +HP (düz) | Prefix | Zırh, Kemer, Kask | 900-1400 |
| +% HP | Prefix | Gövde, Kemer | %10-15 |
| +Savunma | Prefix | Zırh parçaları | 120-180 |
| +% Savunma | Prefix | Zırh parçaları | %30-50 |
| +Kalkan (Shield) başlangıçta | Prefix | Yan el | Max HP %8-12 |
| +Güç / Çeviklik / Zekâ / Dayanıklılık / Şans | Suffix | Tümü | 40-65 |
| +Tüm Statlar | Suffix | Kolye, Yüzük | 18-28 |
| +% Kritik Şansı | Suffix | Silah, Kolye, Yüzük, Eldiven | %4-7 |
| +% Kritik Hasarı | Suffix | Silah, Kolye, Eldiven | %25-45 |
| +% Saldırı Hızı | Suffix | Silah, Eldiven, Yüzük | %8-14 |
| +% Büyü Hızı | Suffix | Silah, Kolye | %8-14 |
| +% Delme | Suffix | Silah | %6-10 |
| +% Ateş/Soğuk/Yıldırım/Kaos Direnci | Suffix | Zırh, Takı | %25-40 |
| +% Tüm Direnç | Suffix | Takı, Pelerin | %12-18 |
| +% Kaçınma | Suffix | Bot, Pelerin | %4-7 |
| +% Blok | Suffix | Kalkan | %5-8 |
| +% Can Çalma | Suffix | Silah, Yüzük | %1-2 |
| +HP Yenilenme/sn | Suffix | Zırh, Kemer | 40-70 |
| +% Bekleme Azaltma | Suffix | Kask, Kolye, Tılsım | %4-8 |
| +% Item Bulma | Suffix | Kask, Yüzük, Kolye | %12-20 |
| +% Altın Bulma | Suffix | Eldiven, Yüzük, Kemer | %15-25 |
| +% XP Bonusu | Suffix | Kask, Kolye | %5-10 |
| +X Belirli Skill Seviyesi | Suffix | Kask, Kolye, Silah (Destansı+) | +1/+2 |
| +% Elit/Boss Hasarı | Suffix | Silah, Tılsım | %10-20 |
| +% Skill Alanı | Suffix | Kask, Asa | %10-20 |
| +% Hareket Hızı | Suffix | Bot | %10-20 |

## 15.7 Efsanevi Itemler (Seçki: 32 adet)

Efsanevi itemler sabit isimli ve benzersiz etkilidir. Her biri belirli bir taban türde ve minimum bölgede düşer.

| Ad | Taban | Benzersiz Etki |
|---|---|---|
| Kral Aldric'in Yemini | Kılıç | Kalkan Darbesi 2 hedefe sıçrar, sersemletme +1 sn |
| Ejderkalp | Gövde (Ağır) | HP %50 altına düşünce 1 kez/60 sn tam iyileşme |
| Goblin Şefinin Tacı | Kask | Altın Bulma +%60, her öldürmede %1 şansla altın patlaması |
| Bin Yıllık Meşe | Yay | Ok Yağmuru alanı +%50, süre +2 sn |
| Ay Fısıltısı | Hançer | Gece kritik şansı +%15; gündüz -%5 |
| Anka Tüyü | Pelerin | Ölünce 3 sn sonra %50 HP ile dirilir (180 sn CD) |
| Kozmik Göz | Kolye | Bekleme süreleri -%15, Nihai bar +%20 hızlı |
| Ragnarök'ün Kıvılcımı | İki El Balta | Kasırga her dönüşte Yıldırım çarpar |
| Buzul Kalbi | Küre | Donma 3 yığında olur (5 yerine) |
| Kara Alev Grimoire | Asa | Ateş büyüleri ayrıca %50 Kaos hasarı verir |
| Vex'in Oyuncağı | Tırpan | İskeletler patlayarak ölür (%200 alan) |
| Tanrıçanın Gözyaşı | Kutsal Kitap | Aşırı iyileşme kalkan olur (max %30 HP) |
| Gezgin Ozanın Lavtası | Lavta | Tüm şarkılar 2 kat süre, Neşe XP +%10 |
| Sonsuz Sadak | Ok Kılıfı | Her 4. ok 3'e bölünür |
| Titanın Kemeri | Kemer | +%20 HP, ağır zırh cezası yok, iksirler 2 kez |
| Gölge Adım Çizmeleri | Bot | Gölge Adımı bekleme -%40 |
| Hazine Avcısının Yüzüğü | Yüzük | Item Bulma +%40, Altın +%40, -%10 hasar |
| Kanlı Gül | Yüzük | Kanama hasarı x2 |
| Fırtına Çağıran | Değnek | Zincir Şimşek +3 sekme |
| Yıldızkıran | Arbalet | Kritik vuruşlarda küçük meteor düşer |
| Ölümsüz Muhafız | Kalkan | Blok başarılıysa 2 sn hasar bağışıklığı (10 sn CD) |
| Kum Saati | Tılsım | Offline verim +%20 (hesap genelinde, sadece kuşanıldığında) |
| Kurt Kralının Pençesi | Eldiven | Kurt Çağır 2 kurt çağırır |
| Ruh Kafesi | Tılsım | Her 100 öldürmede +%1 hasar (bölge değişince sıfırlanır, max %30) |
| Abyssal Taç | Kask | Kaos hasarı +%40, Kaos direnci -%20 |
| Paladin Mührü | Yüzük | Kutsal hasar ölümsüz olmayanlara da x1.5 |
| Soğuk Çelik | Kılıç | Vuruşlar %100 Donma uygular |
| Cellat | İki El Kılıç | %10 HP altındaki normal düşmanları anında öldürür |
| Sihirbazın Şapkası | Kask (Hafif) | Her büyü %15 şansla rastgele ikinci büyüyü bedava yapar |
| Zaman Bükücü | Kolye | Tüm parti saldırı hızı +%15, düşmanlar -%10 |
| Pip'in Şans Kurabiyesi | Tılsım | Her boss sonrası %25 şansla ekstra efsanevi roll |
| Uçurum Gözü | Küre | Lanet artık yayılır (2 düşman) |

> İçerik AI notu: Efsanevi listesi lansmanda **80 adet** olmalı (her taban türünden en az 3). Yukarıdaki 32 adet tasarım kalıbıdır; kalanları aynı formatta (her sınıfın en az 2 skillini değiştiren item) üret.

## 15.8 Set Itemleri (8 Set)

| Set | Parçalar | 2 Parça | 4 Parça | 6 Parça |
|---|---|---|---|---|
| İmparatorluk Muhafızı (Şövalye) | Kask, Gövde, Eldiven, Bot, Kalkan, Kılıç | +%20 DR | Kalkan Darbesi tüm düşmanlara | Tehdit altındayken parti +%40 hasar |
| Kuzeyli Öfkesi (Barbar) | Kask, Gövde, Kemer, Bot, Balta, Pelerin | +%25 Saldırı Hızı | Kasırga sürekli | Öfke barı x2 |
| Elf Gözcüsü (Okçu) | Kask, Gövde, Eldiven, Bot, Yay, Kılıf | +%8 Kritik | Çoklu Atış +5 ok | Her ok %30 şansla patlar |
| Gece Kraliçesi (Suikastçı) | Maske, Gövde, Eldiven, Bot, 2 Hançer | +%15 Kaçınma | Gölge Adımı 3 kez zincir | Kritikler %300 ek hasar |
| Element Sonsuzluğu (Büyücü) | Taç, Cübbe, Eldiven, Bot, Asa, Küre | +%20 Element | Element Döngüsü max yığın x3 | Her büyü tüm elementlerden hasar verir |
| Kemik Hükümdarı (Nekromant) | Taç, Cübbe, Kemer, Pelerin, Tırpan, Küre | +2 Çağrı | Çağrılar ölümsüz 10 sn | Çağrılar sahibin statlarını %100 kopyalar |
| Aziz'in Işığı (Rahibe) | Hale, Cübbe, Eldiven, Bot, Kitap, Topuz | +%25 İyileştirme | İyileştirmeler zincirlenir (3 müttefik) | Parti ölümsüz 2 sn her 30 sn |
| Efsanevi Turne (Ozan) | Şapka, Kıyafet, Bot, Pelerin, Lavta, Yüzük | +%20 Buff süresi | 3 şarkı aynı anda | Şarkılar nihai barı sürekli doldurur |

## 15.9 Item Gücü Skoru (Otomatik Kuşanma)

`ItemPower = Σ (affix_value / affix_T7_max) x affix_weight[class] x 100 + BaseStat x TierMult`

- Her sınıf için affix ağırlıkları `classes.json` içinde (ör. Okçu: Çeviklik 1.0, Kritik 1.0, Saldırı Hızı 0.9, Zekâ 0.1).
- Tooltip'te karşılaştırma: DPS ve EHP (Etkin HP) değişimi yüzde olarak.


# 16. Gemler ve Soketler

- Destansı+ itemlerde 0-2 soket (Kuyumcu ile açılabilir).
- Gem türleri (5 kademe: Yontulmamış → Kusurlu → Normal → Kusursuz → Kraliyet; 3 aynı gem = 1 üst kademe):

| Gem | Silaha | Zırha | Takıya |
|---|---|---|---|
| Yakut | +Ateş hasarı | +HP | +Ateş direnci |
| Safir | +Soğuk hasarı | +Savunma | +Soğuk direnci |
| Topaz | +Yıldırım hasarı | +Item Bulma | +Altın Bulma |
| Zümrüt | +Kritik Hasar | +Kaçınma | +Kritik Şansı |
| Ametist | +Kaos hasarı | +Can Çalma | +Kaos direnci |
| Elmas | +Tüm hasar | +Tüm direnç | +Tüm statlar |
| Kafatası | +Can Çalma | +HP Yenilenme | +Bekleme Azaltma |


# 17. Demirci ve Ekonomi

## 17.1 Demirci Paneli (Sekmeler)

Referans görseldeki gibi: **Birleştir / Sat / Üret** + bizim eklediğimiz **Güçlendir** ve **Sök**. Demircinin kendi seviyesi vardır (Lv 1-50); her işlem Demirci XP'si verir. Demirci seviyesi yeni özellikleri açar (ör. "Demirci Lv.30 → Lv.45-65 itemleri birleştirmeyi açar").

## 17.2 Birleştir (Combine)

- **9 item → 1 item** (referans: 3x3 ızgara, "9/9 - Başarı %90").
- Aynı nadirlikte 9 item birleşince bir üst nadirlikte, ortalama iLvl + 2 seviyesinde, kuşananın sınıfına uygun rastgele item üretilir.
- Başarı oranı: Sıradan→Büyülü %100, Büyülü→Nadir %90, Nadir→Destansı %75, Destansı→Efsanevi %35 (Demirci Lv 25+), Efsanevi→Mitik %10 (Lv 45+, 9 Efsanevi + Mitik Öz).
- **Merhamet sayacı (pity):** "0/10 (10 başarısızlıktan sonra sonraki birleştirme garantili)". Başarısızlıkta itemlerin 6'sı yok olur, 3'ü geri döner.
- Butonlar: **Otomatik Doldur** (seçili nadirlik ve level aralığından, kilitli itemleri atlayarak), level aralığı seçici (Lv.1~20), "Depoyu dahil et" kutucuğu, **Birleştir**, **İstatistik**.

## 17.3 Güçlendirme (Enhance +1 → +15)

| Seviye | Başarı | Maliyet (altın x iLvl) | Başarısızlıkta | Bonus |
|---|---|---|---|---|
| +1 ~ +5 | %100 | 50 | - | Her seviye taban stat +%5 |
| +6 ~ +9 | %80 → %50 | 150 | Seviye korunur | +%6 / seviye |
| +10 ~ +12 | %40 → %25 | 400 + Parlak Öz | -1 seviye | +%8 / seviye, +10'da parlama efekti |
| +13 ~ +15 | %15 → %5 | 1000 + Yıldız Tozu | -1 seviye (Koruma Parşömeni ile korunur) | +%10, +15'te rarity renginde aura |

Item ASLA yok olmaz (oyuncu dostu).

## 17.4 Üret (Craft)

- Malzemeler + altın ile belirli taban türde, seçilen kademede item üretimi. Nadirlik rastgele (Nadir garantili tarifler var).
- Efsanevi hedefli üretim: Kodekste bulunan efsanevi itemler için "Efsanevi Şablon" + 50 Efsanevi Öz ile yeniden üretim (endgame sink).

## 17.5 Sök (Salvage) ve Malzemeler

| Malzeme | Kaynak | Kullanım |
|---|---|---|
| Demir Parçası | Sıradan/Büyülü sökme | Güçlendirme +1~+9, üretim |
| Parlak Öz | Nadir sökme | Güçlendirme +10~+12, üretim |
| Destansı Öz | Destansı sökme | Reroll, soket açma |
| Efsanevi Öz | Efsanevi sökme | Efsanevi üretim, Mitik birleştirme |
| Yıldız Tozu | Kule, Yarık | +13~+15 |
| Mitik Öz | Cehennem Perde Boss, Yarık 50+ | Mitik birleştirme |
| Ruh Parçası | Boss'lar | Kahraman yıldızı |
| Taverna Mührü | Boss'lar, görevler | Kahraman toplama |
| Lonca Nişanı | Perde boss, haftalık görev | Lonca Salonu |

## 17.6 Ganimet Filtresi ve Otomatik İşlem

Ayarlar > Ganimet: her nadirlik için **Tut / Sat / Sök** seçimi; "Daha iyi olmayanları sat" seçeneği; Efsanevi+ her zaman tutulur. Envanter dolduğunda (ilk 60 slot, genişletme altınla max 120) otomatik filtre uygulanır.

## 17.7 Depo (Stash)

- 7 sekme (1. sekme ücretsiz, diğerleri altınla açılır: 10K, 50K, 200K, 1M, 5M, 20M). Her sekme 6x6 = 36 slot.
- Tüm kahramanlar arasında paylaşılır. "Çantaya / Depoya" toplu taşıma butonları ve sıralama (nadirlik, tür, level).

## 17.8 Ekonomi Dengesi (Kaynaklar ve Musluklar)

| Para | Kaynak (faucet) | Harcama (sink) |
|---|---|---|
| Altın | Öldürme, satış, görevler, offline | Güçlendirme, depo, sıfırlama, Lonca Salonu, Taverna, iksir, envanter genişletme |
| Malzemeler | Sökme, boss, Kule | Güçlendirme, üretim, reroll |
| Mühür/Nişan | Boss, görev | Kahraman, Lonca Salonu |

Hedef: Oyuncu her oturum açtığında harcayacak anlamlı bir şeyi olsun; altın asla "anlamsız yığın"a dönüşmesin (Lonca Salonu üst seviyeleri üstel maliyetli sink).



# 18. Dünya, Hikaye ve Bölgeler

## 18.1 Hikaye Özeti

**Dünya: Aethoria.** Bin yıl önce "Öz" (Essence) adı verilen büyülü enerji dünyanın kalbindeki **Dünya Kristali**'nden akıyordu. Uçurum'un efendisi **Kral Morvath** kristali kırdı; parçaları dört diyara dağıldı ve parçaların yakınındaki canavarlar güçlenip çoğaldı.

Oyuncu, sürgün edilmiş bir lonca kurucusudur. Kasabası **Taşköprü**'de bir "Gezgin Lonca" kurar. Genç şövalye **Kael**, elf okçu **Lyra** ve neşeli rahibe **Pip** ilk üyelerdir. Amaç: Kristal parçalarını toplamak, her Perde'nin sonunda bir parçayı korumakla görevli büyük boss'u yenmek ve sonunda Morvath'ı durdurmaktır.

- **Perde 1 - Sisli Orman:** Goblinler kristal parçasını "parlak taş" sanıp çalmış. Komik ve sıcak başlangıç.
- **Perde 2 - Donmuş Zirveler:** Buz cadısı parçayı kullanarak sonsuz kış yaratmış. Bjorn katılır.
- **Perde 3 - Yanık Çöller ve Antik Harabeler:** Öz Kulesi'nin kayıp âlimleri, parçanın sırrı. Finn katılır, ihanet twisti (Vesper'in hocası).
- **Perde 4 - Uçurum Kapısı:** Morvath'ın kalesi. Final ve kristalin yeniden birleşmesi.
- **Kabus ve Cehennem:** Kristal birleşince "Yansıma Dünyası" açılır; aynı diyarların karanlık ve güçlü versiyonları (yeni boss mekanikleri + yeni canavar varyantları + yeni diyaloglar).
- **Perde 5 (Lansman sonrası güncelleme):** Gökyüzü Adaları.

Hikaye anlatımı: Bölge girişlerinde ve Perde sonlarında, şeritte oynanan **kısa pixel diyaloglar** (portre + 2-4 satır balon) ve Perde sonlarında 4-6 karelik **pixel art ara sahne panelleri** (Tam modda ayrı pencerede). Hepsi atlanabilir.

## 18.2 Dünya Haritası

- Referans "World" penceresi gibi: parşömen kâğıdı üzerinde pixel harita, bölgeler kare düğümler (turuncu: tamamlanmış, kırmızı: boss/mevcut, gri: kilitli), mavi noktalı patika.
- Üstte: Zorluk seçici (Normal / Kabus / Cehennem) ve Perde sekmeleri (Perde 1-4).
- Düğüme tıklama: bölge kartı (önerilen level, canavarlar, olası efsanevi dropları, ilerleme 7/10), "Git" butonu.
- Kahraman partisinin mini sprite'ı mevcut düğümde durur.

## 18.3 Bölge Listesi (Normal Zorluk)

Kabus = Level +50 (aynı bölgeler, karanlık palet), Cehennem = Level +75 (Kabus'tan sonra ölçek: Perde 1 Cehennem 75'ten başlar, Perde 4 Cehennem 100'de biter).

### Perde 1: Sisli Orman (Lv 1-12)

| # | Bölge | Lv | Canavarlar | Bölge Boss'u |
|---|---|---|---|---|
| 1 | Taşköprü Çayırları | 1-2 | Yeşil Slime, Tavşan | Dev Slime |
| 2 | Orman Kıyısı | 2-3 | Slime, Mantarcık, Yaban Domuzu | Kızgın Domuz Ana |
| 3 | Sisli Orman Yolu | 3-5 | Goblin Çırak, Mantarcık, Kurt | Goblin Gözcü Başı |
| 4 | Mantar Mağarası | 5-6 | Zehirli Mantar, Yarasa, Goblin | Kral Mantar |
| 5 | Goblin Kampı | 6-7 | Goblin Savaşçı, Goblin Okçu, Goblin Şaman | Goblin Şefi Grubnak |
| 6 | Unutulmuş Mezarlık | 7-8 | İskelet, Hayalet, Zombi | Mezar Bekçisi |
| 7 | Örümcek Yuvası | 8-9 | Örümcek, Örümcek Yumurtası, Koza Zombi | Kraliçe Örümcek Arakna |
| 8 | Kuşatılmış Değirmen | 9-10 | Goblin Süvari (kurt binici), Goblin Bombacı | Goblin Mühendis + Tank |
| 9 | Kadim Ağaç Kökleri | 10-11 | Ent Fidanı, Peri (düşman), Orman Ruhu | Çürük Ent |
| 10 | Goblin Kralı Tahtı | 11-12 | Goblin Elitleri | **PERDE BOSS: Goblin Kralı Grizzlecrown** |

### Perde 2: Donmuş Zirveler (Lv 12-25)

| # | Bölge | Lv | Canavarlar | Bölge Boss'u |
|---|---|---|---|---|
| 1 | Dağ Eteği Köyü (yıkık) | 12-13 | Kar Kurdu, Haydut | Haydut Reisi |
| 2 | Karlı Geçit | 13-15 | Yeti Yavrusu, Buz Slime | Yeti |
| 3 | Donmuş Göl | 15-16 | Buz Elementali, Penguen Savaşçı (komik) | Göl Canavarı |
| 4 | Kristal Mağaralar | 16-18 | Kristal Golem, Buz Yarasası | Kristal Örümcek |
| 5 | Cüce Madeni | 18-19 | Hortlak Madenci, Maden Arabası (yuvarlanan tuzak) | Lanetli Cüce Ustabaşı |
| 6 | Fırtına Tepesi | 19-20 | Harpi, Yıldırım Ruhu | Harpi Kraliçesi |
| 7 | Kuzey Kabileleri | 20-22 | Kuzey Savaşçısı (kontrollü), Kurt Binici | Bjorn ile düello (dostluk dövüşü, sonrasında katılır) |
| 8 | Buz Tapınağı Girişi | 22-23 | Buz Muhafızı, Kar Tanesi Perisi | Donmuş Şövalye |
| 9 | Ayna Salonu | 23-24 | Buz Kopyaları (partinin aynası!) | Ayna Partisi |
| 10 | Kış Cadısının Tahtı | 24-25 | Elitler | **PERDE BOSS: Buz Cadısı Isolde** |

### Perde 3: Yanık Çöller ve Antik Harabeler (Lv 25-38)

| # | Bölge | Lv | Canavarlar | Bölge Boss'u |
|---|---|---|---|---|
| 1 | Kum Limanı | 25-26 | Korsan, Kum Yengeci | Korsan Kaptan |
| 2 | Kızgın Kumullar | 26-28 | Akrep, Kum Solucanı, Kertenkele Adam | Dev Kum Solucanı |
| 3 | Vaha | 28-29 | Serap Ruhu, Kaktüs Canavarı | Serap Kraliçesi |
| 4 | Gömülü Şehir | 29-30 | Mumya, Scarab, Anubis Muhafız | Firavun Mumyası |
| 5 | Ateş Kanyonu | 30-32 | Ateş Elementali, Lav Slime, Ateş İmpi | Magma Golem |
| 6 | Öz Kulesi Kalıntıları | 32-33 | Bozuk Büyü Kitapları, Animasyonlu Zırh | Çılgın Simyacı |
| 7 | Arkana Kütüphanesi | 33-34 | Uçan Kitap, Mürekkep Slime | Kütüphane Muhafızı |
| 8 | Zaman Harabeleri | 34-36 | Saat Golemi, Zaman Hayaleti | Kum Saati Bekçisi |
| 9 | Hain Âlimin Laboratuvarı | 36-37 | Kimera, Homunculus | Kimera Alfa |
| 10 | Güneş Sunağı | 37-38 | Elitler | **PERDE BOSS: Hain Arşmag Corvus** |

### Perde 4: Uçurum Kapısı (Lv 38-50)

| # | Bölge | Lv | Canavarlar | Bölge Boss'u |
|---|---|---|---|---|
| 1 | Kül Ovaları | 38-39 | İblis İmp, Cehennem Köpeği | İblis Avcı |
| 2 | Kanlı Nehir | 39-41 | Kan Elementali, Boğulmuş Ölü | Nehir Kâbusu |
| 3 | Kemik Tarlaları | 41-42 | Kemik Ejder Yavrusu, İskelet Okçu | Kemik Kolosu |
| 4 | Kara Orman | 42-43 | Lanetli Ent, Gölge Kurt | Gölge Ent |
| 5 | Kültist Tapınağı | 43-45 | Kültist, Kurban Rahibi | Yüksek Kültist |
| 6 | Uçurum Kenarı | 45-46 | Hiçlik Yaratığı, Tentakül | Hiçlik Gözü |
| 7 | Kale Surları | 46-47 | Kara Şövalye, Gargoyle | Kara Şövalye Komutanı |
| 8 | Ziyafet Salonu | 47-48 | Vampir, Yarasa Sürüsü | Vampir Kontes |
| 9 | Taht Odası Koridoru | 48-49 | Morvath'ın Muhafızları | Uçurum Muhafızı İkizleri |
| 10 | Morvath'ın Tahtı | 49-50 | - | **FİNAL BOSS: Uçurum Kralı Morvath (3 faz)** |

## 18.4 Boss Mekanikleri (Perde Bossları)

Bosslar idle oyunda bile "izlemeye değer" olmalı. Her boss'un 2-3 telgraflanan (önceden uyarı veren) skill'i ve %50 HP'de faz değişimi vardır.

| Boss | Mekanik 1 | Mekanik 2 | Faz 2 (%50) | Oyuncu Çözümü |
|---|---|---|---|---|
| Goblin Kralı Grizzlecrown | Altın Yağmuru: alan hasarı | Goblin çağırma (her 15 sn 3 goblin) | Öfkelenir: +%50 saldırı hızı | Alan hasarlı sınıf, tank |
| Buz Cadısı Isolde | Buz Fırtınası: tüm partiye Donma | Buz Duvarı: 5 sn hasar bağışıklığı (kırılmalı: 10 vuruş) | Kar Fırtınası: görüş azalır (şerit beyazlaşır), kahraman kaçınması düşer | Ateş hasarı, Soğuk direnci, çok vuruşlu sınıflar |
| Hain Arşmag Corvus | Element değiştirme: 10 sn'de bir zayıflığı/direnci değişir | Meteor: telgraflı büyük hasar (kalkan gerekli) | Kopyalar: 2 sahte Corvus | Çok elementli parti, kalkan/iyileştirme |
| Uçurum Kralı Morvath | Faz 1: Kara Kılıç kombosu, tank kontrolü | Faz 2 (%66): Partiden bir kahramanı 6 sn "Hiçlik"e hapseder | Faz 3 (%33): Dev form, şeridin tamamını kaplar, her 20 sn "Kıyamet" (parti HP %80) | Dengeli parti, Rahibe nihai zamanlaması, yüksek DR |

**Telgraf görselleri:** Yerde kırmızı yanıp sönen alan (1.5 sn), boss'un üstünde ünlem ikonu, kısa ses uyarısı.

## 18.5 Gece/Gündüz ve Özel Canavarlar

- `TimeService` bilgisayar saatini okur: 06-17 Gündüz, 17-20 Gün Batımı, 20-05 Gece, 05-06 Şafak.
- Gece: Ölümsüz canavarlar %30 daha sık, "Gece Elitleri" (mor auralı), Gece Avcısı pasifleri aktif, nadir "Ay Tavşanı" (öldürülünce Ay Taşı tılsımı düşürür, %2).
- Hafta sonu: "Hazine Goblini" spawn şansı (%1 dalga başı; kaçmaya çalışır, 10 sn içinde öldürülürse 1 Destansı+ ve büyük altın).


# 19. Endgame İçerikleri

## 19.1 Sonsuz Kule (Tower)

- Lv 50'de açılır. Kat kat ilerleyen tek dalga + boss kat (her 10 kat). Kat zorluğu: `TowerLevel = 50 + Kat x 0.8` ölçekli canavarlar.
- Her kat ilk geçişte ödül (Yıldız Tozu, Lonca Nişanı). Her 25 katta özel ödül (kostüm, pet, tılsım).
- Haftalık **Steam Liderlik Tablosu**: en yüksek kat + süre.
- Kule'de "Kule Modifiye Edicileri": her hafta değişen 2 kural (ör. "Tüm düşmanlar Ateşe bağışık", "Kritikler iyileştirir").

## 19.2 Yarıklar (Rifts)

- Lv 70'te açılır. **Yarık Anahtarı** (boss'lardan düşer) ile girilir. Anahtar seviyesi 1-150.
- 3 dakikalık zaman sınırında 100% yarık ilerlemesi (öldürmelerle dolar) + Yarık Muhafızı boss'u.
- Süre içinde bitirilirse anahtar +1~+3 seviye yükselir; ödüller anahtar seviyesine göre (Mitik Öz, Gem yükseltme, Efsanevi garantisi).

## 19.3 Günlük ve Haftalık Görevler

| Tür | Örnek | Ödül |
|---|---|---|
| Günlük (3 adet) | 500 düşman öldür, 1 Nadir birleştir, 3 boss yen | Altın, Taverna Mührü |
| Haftalık (3 adet) | Kule'de 5 kat ilerle, Yarık Lv X bitir, 1 efsanevi bul | Lonca Nişanı, Yarık Anahtarı |
| Lonca Panosu Kontratları | "Kar Kurdu avı: 200 kar kurdu" | Bölgeye özel drop |

Günlük görevler offline ilerlemeyle de tamamlanabilir (oyuncu cezalandırılmaz). Kaçırılan günlükler 3 güne kadar birikir.

## 19.4 Dünya Boss'u (Haftalık)

- Her hafta sonu 48 saat: "Kadim Ejder Aethrax". Boss'un HP'si dev; parti 3 dakikalık denemelerde maksimum hasarı vurur (günlük 3 deneme). Toplam hasara göre ödül kademeleri.
- Opsiyonel Steam Liderlik Tablosu: tek denemede en yüksek hasar.

## 19.5 Paragon Sistemi (Lv 100 sonrası)

- 100'den sonra kazanılan XP **Paragon Seviyesi** verir (hesap genelinde, sınırsız; XP gereksinimi her paragon için %2 artar).
- Her Paragon seviyesi 1 Paragon Puanı: 4 tahta (Saldırı, Savunma, Servet, Yardımcı), her stat 50'şer puan max; sonra "Sonsuz" stat (+%0.1 tüm hasar / puan).

## 19.6 Sezonlar (Lansman Sonrası, Opsiyonel)

- 10-12 haftalık sezonlar: yeni karakter (sezon slotu), sezonluk tema mekaniği, sezonluk kostüm ödülleri. Sezon bitince karakter ana hesaba aktarılır. Tamamen opsiyonel; offline oyuncuları cezalandırmaz.



# 20. Arayüz (UI/UX), Açılış Sekansı ve Oyun Akışı

## 20.1 Savaş Şeridi HUD Yerleşimi (Mantıksal 320x70 + Kontrol Paneli 48x70)

```
+--------------------------------------------------------------------------------------+---------+
| [Bölge: Sisli Orman Yolu 1-6]        [Boss Zamanlayıcı 0:42]           [Sandık(!)]   | P S M Q |
| (o) Kasaba                                                                            | [Kahrmn]|
| (o) DPS     [PET][K1][K2][K3][K4][K5] ---->   [D][D][D][E]                [Portal]     | [Çanta] |
| (o) AUTO    ===== Parti HP barı =====          (hasar sayıları)                        | [Gelişm]|
|                                                                                        | [Dünya] |
| [XP barı - ince 2px, şeridin en altında]                                              |   [≡]   |
+--------------------------------------------------------------------------------------+---------+
```

- Sol butonlar (yuvarlak, 12x12): Kasaba (kırmızı), DPS/istatistik (yeşil), AUTO (mavi; açıkken döner animasyon).
- Kontrol paneli 2x2 buton ızgarası: **Kahraman / Çanta / Gelişim / Dünya** + üstte küçük ikonlar (Güç = Duraklat/Çıkış, Ayarlar, Posta/Bildirim, Görevler, Ses) + "≡" ek menü (Taverna, Kodeks, Başarımlar, Kostüm, Lonca Salonu).
- Bildirim noktaları: Butonlarda yeni içerik varsa küçük kırmızı/mavi nokta (ör. dağıtılmamış stat puanı).

## 20.2 Panel Listesi

| Panel | Açılış Kısayolu | Boyut | İçerik |
|---|---|---|---|
| Kahraman | H | Orta | Skill / Kostüm sekmeleri, skill ızgarası, parti şeridi (alt kısımda 5 kahraman portresi ile geçiş) |
| Statlar | C | Küçük | 4 sekme (Tümü/Saldırı/Savunma/Diğer), +/- stat dağıtma, Otomatik |
| Portre | (Kahraman ile açılır) | Küçük | Vitray önünde tam boy kahraman, Level, XP barı, ad, sınıf, yıldız |
| Envanter (Çanta) | I / B | Orta | Ekipman ızgarası (12 slot) + iksir slotları + filtreler (Tümü/Silah/Zırh/Kask/Takı/Malzeme) + 60-120 slot + Depo/Demirci/Kule/Takas kısayolları |
| Depo | (Envanterden) | Orta | 7 sekme, 6x6 |
| Demirci | (Kasaba/Envanter) | Orta | Birleştir/Sat/Üret/Güçlendir/Sök |
| Dünya | M | Geniş | Harita, zorluk, perdeler |
| Gelişim | G | Geniş | Lonca Salonu, Fraksiyon, Paragon, Kodeks sekmeleri |
| Taverna | T | Orta | Kahraman teklifleri, kahraman yıldız yükseltme |
| Görevler | J | Küçük | Hikaye, günlük, haftalık |
| Ayarlar | Esc | Orta | Bölüm 21.3 |
| DPS İstatistik | D | Küçük | Kahraman başına hasar payı (bar grafik), son 5 dk öldürme/dk, XP/saat, altın/saat |
| Sen Yokken | otomatik | Orta | Offline özeti |

## 20.3 Etkileşim Kuralları

- **Sürükle-bırak:** Item sürükleme, slotlar arası; sağ tık = hızlı kuşan / depoya at; Shift+sağ tık = sat; Ctrl+tık = kilitle (kilitli item asla satılmaz/sökülmez/birleştirilmez).
- **Tooltip:** 0.25 sn gecikme; Shift basılıyken kuşanılmışla karşılaştırma; Alt basılıyken affix aralıklarını ve kademelerini göster (T1-T7).
- **Bildirim kuyruğu:** Sağ alt köşede, max 3 bildirim, 4 sn.
- **Klavye:** Tüm paneller kısayol ile açılır/kapanır; Esc açık en üst paneli kapatır.
- **Erişilebilirlik:** Renk körü modu (nadirlik rengine ek ikon/şekil), UI ölçeği, yazı boyutu (pixel font 1x/2x), ekran sarsıntısı kapatma, yanıp sönme azaltma.

## 20.4 Açılış Sekansı (İlk Çalıştırma, Saniye Saniye)

| Zaman | Ne olur | Teknik not |
|---|---|---|
| 0.0 sn | Kenarlıksız küçük açılış penceresi ekranın ortasında (480x270): Stüdyo logosu pixel animasyonu (1.5 sn) | Ses: tek "ding" |
| 1.5 sn | Godot/"Made with" logosu (0.8 sn, atlanabilir) | |
| 2.5 sn | **Başlık ekranı**: Aynı pencerede, gece gökyüzü, uzakta kale, ön planda kamp ateşi etrafında 3 kahraman (Kael, Lyra, Pip) idle animasyonla oturuyor. Logo yukarıdan düşer (bounce). Müzik: ana tema (lavta + flüt). | Logo: "IDLE PARTY" büyük pixel yazı, altında "Desktop Legends" |
| | Butonlar: **Yeni Oyun / Devam Et / Ayarlar / Çıkış** | |
| Yeni Oyun | **Pencere Yerleşim Sihirbazı** (tek ekran): "Partin nerede yaşasın?" 3 seçenek kartı: (1) Görev çubuğunun üstü [önerilen], (2) Ekranın üstü, (3) Serbest. Ölçek seçimi 1x/2x/3x canlı önizleme. "Her zaman üstte" kutucuğu. | Taskbar algılama burada çalışır |
| +0 | **Giriş Ara Sahnesi** (5 panel, her biri 3 sn, tıklayınca geçer, "Atla" butonu): 1) Parlayan Dünya Kristali. 2) Morvath'ın gölgesi kristali kırar. 3) Parçalar dört diyara dağılır. 4) Taşköprü kasabası, boş bir lonca binası, "Satılık" tabelası. 5) Oyuncunun (görünmeyen) eli tabelayı "Gezgin Lonca" olarak değiştirir; Kael kapıyı çalar. | Pixel art paneller 320x180 |
| +15 sn | Başlık penceresi küçülerek **şerit** haline dönüşür ve seçilen konuma "kayar" (0.6 sn animasyon). Bu an oyunun imza anı: oyuncu konsepti hemen anlar. | Pencere tween'i |
| +16 sn | Şeritte Kael tek başına koşmaya başlar. Konuşma balonu: "Lonca kurmuşsun ha? İlk işimiz: şu slime'lar!" | |
| +20 sn | İlk dalga (3 Yeşil Slime). Tutorial oku: "Kahramanlar kendi kendine savaşır. Sen sadece güçlendir!" | Tutorial balonu kapatılabilir |
| +45 sn | İlk item düşer (garantili Büyülü kılıç). Sandık ikonu zıplar. Tutorial: "Sandığa tıkla!" → Envanter paneli şeridin üstünde açılır. Kuşan oku. | İlk panel açılışı: Tam mod öğretilir |
| +1:30 | Level 2: Stat puanı tutorial'ı (Stat paneli). "Otomatik Dağıt" butonu gösterilir. | |
| +2:30 | Lyra katılır (ara diyalog: ağaçtan iner, slime'ı vurur). Parti 2 kişi. | |
| +4:00 | Level 3: İlk skill puanı. Kahraman paneli tutorial'ı. Kael'e "Kalkan Darbesi" öğretilir ve kuşanılır. | |
| +5:00 | Pip katılır (yanlışlıkla iyileştirme büyüsü yerine şimşek atar - komik an). Parti 3. | |
| +6:00 | Bölge 1 Boss: Dev Slime. Boss uyarısı ve zamanlayıcı tutorial'ı. Yenilince ikiye bölünür (küçük sürpriz). | |
| +8:00 | Bölge 2 açılır. Dünya haritası tutorial'ı (Dünya butonu yanıp söner). AUTO butonu tanıtılır: "AUTO açıkken parti kendi ilerler." | |
| +10:00 | Tutorial biter. Son mesaj: "Artık işine dönebilirsin. Biz buradayız!" — Bu cümle oyunun felsefesidir. Şerit kendi kendine devam eder. | Patron Tuşu ipucu bildirimi |

## 20.5 Özellik Açılış Zaman Çizelgesi

Özellikler kademeli açılır ki oyuncu boğulmasın. Kilitli butonlar gri + kilit ikonu + "Lv X'te açılır" tooltip.

| Level / Olay | Açılan |
|---|---|
| Lv 1 | Şerit, Envanter, Statlar, Kahraman paneli |
| Lv 2 | Stat dağıtımı |
| Lv 3 | Skill sistemi |
| Lv 3 | Tüccar |
| Lv 5 | Demirci (Sat, Birleştir) |
| Lv 6 | Nova katılır (4. kahraman) |
| Lv 8 | Taverna (5. slot açılır: ilk kahramanı oyuncu seçer, 3 R kahramandan biri) |
| Lv 10 | Görevler (günlük), Depo sekme 2 satın alınabilir, AUTO otomatik ilerleme |
| Lv 12 | Bjorn katılır (yedek), Fraksiyon koleksiyonu |
| Lv 15 | Güçlendirme +1~+9, Ganimet filtresi |
| Lv 18 | Evcil hayvanlar (ilk yumurta Perde 1 Boss'tan) |
| Lv 20 | Lonca Salonu, Finn katılır |
| Lv 25 | Kuyumcu (gemler), Destansı birleştirme |
| Lv 30 | 1. Sınıf İlerlemesi (Kâhin görevi: kahraman başına küçük bir boss sınavı) |
| Lv 35 | Üretim (Craft) |
| Lv 40 | Güçlendirme +10~+12 |
| Lv 50 (Normal bitti) | Kabus zorluğu, Sonsuz Kule |
| Lv 60 | Efsanevi birleştirme, Kostüm koleksiyonu |
| Lv 70 | 2. Sınıf İlerlemesi (uzmanlık seçimi), Yarıklar |
| Lv 75 (Kabus bitti) | Cehennem zorluğu, Mitik dropları |
| Lv 85 | +13~+15 güçlendirme |
| Lv 100 | Paragon, Dünya Boss'u liderlik tablosu |

## 20.6 Oyunun Başı, Ortası, Sonu (Deneyim Tasarımı)

### Başlangıç (0-3 saat): "Merak ve hızlı ödül"

- Her 2-5 dakikada yeni bir şey: kahraman katılımı, yeni panel, yeni bölge.
- Level hızlı (ilk 10 level 25 dk).
- Bossları kolay, kazanma garantili; ilk efsanevi item Perde 1 Boss'tan **garantili** ("Goblin Şefinin Tacı").
- Duygusal hedef: "Bu küçük partiyi sevdim."

### Orta Oyun (3-25 saat): "Build ve strateji"

- Sınıf ilerlemeleri, set parçaları, demirci ekonomisi ve kahraman koleksiyonu devreye girer.
- Bosslar artık build kontrolü ister (Buz Cadısı: ateş/soğuk direnci).
- Oyuncu günde birkaç kez göz atar: "Sen Yokken" penceresi + 5 dakikalık düzenleme.
- Hikaye: Perde 3 ihanet twisti ve Perde 4 finali; **Normal zorluk sonu: Morvath'ın yenilmesi ve "Yansıma Dünyası"nın açılması** (büyük ara sahne, jenerik kısaltması).

### Geç Oyun (25-60 saat): "Ustalık"

- Kabus/Cehennem: aynı dünyanın karanlık versiyonları, yeni boss mekanikleri (bosslara 1 ek mekanik eklenir).
- 2. ilerleme uzmanlıkları, 6 parçalı setler, gemler.
- Cehennem Perde 4 sonu = **Gerçek Final:** Morvath'ın arkasındaki gerçek kötü "Boşluk Annesi" ortaya çıkar; yenildiğinde kristal saflaşır, final ara sahnesi (tüm toplanan kahramanlar kasabada şölende — oyuncunun koleksiyonuna göre dinamik sahne!).

### Endgame (60+ saat): "Sonsuz hedefler"

- Kule, Yarıklar, Paragon, Mitik itemler, 48 kahramanı 6 yıldıza çıkarma, kodeks tamamlama, liderlik tabloları, sezonlar.

## 20.7 Ses Tasarımı

| Müzik Parçası | Kullanım | Süre / Stil |
|---|---|---|
| Ana Tema "Gezgin Lonca" | Başlık | 2:30, lavta + flüt + yaylılar, chiptune katmanı |
| Taşköprü | Kasaba | 3:00 loop, sıcak, akustik |
| Sisli Orman | Perde 1 | 3:00 loop, hafif ve neşeli |
| Donmuş Zirveler | Perde 2 | Çan ve rüzgâr |
| Yanık Çöller | Perde 3 | Darbuka, ud, ney renkleri |
| Uçurum Kapısı | Perde 4 | Koyu koro, org |
| Boss Teması x2 | Boss savaşları | Hızlı tempo |
| Morvath Final | Final | Epik, 3 faz geçişli |
| Kule / Yarık | Endgame | Elektronik-chiptune hibrit |
| Gece Varyantı | Her perdede | Aynı melodinin yumuşak gece versiyonu |

- **Odak modu:** Pencere odakta değilken müzik -%60, SFX -%80 (ayarlanabilir). Varsayılan genel ses %40.
- SFX listesi (min. 80 adet): vuruşlar (her silah türü 3 varyant), büyüler (her element), item drop (nadirlik başına ayrı; efsanevi drop sesi imza ses olmalı), level up, UI tıklama/hover/açma/kapama, altın, birleştirme başarı/başarısızlık, boss uyarı, ölüm, diriliş, kahraman "hmm/ha!" vokal blipleri (kelime yok, Animal Crossing tarzı ses blipleri).
- Ses tekrarını önlemek için pitch varyasyonu ±%8 ve aynı ses için 60 ms limit.

## 20.8 Lokalizasyon

- Lansman dilleri: **İngilizce, Türkçe**, Basitleştirilmiş Çince, Japonca, Korece, Almanca, Fransızca, İspanyolca, Portekizce (BR), Rusça. (Bu tür Asya'da çok güçlü; CJK pixel font desteği kritik.)
- Tüm metinler `localization/*.csv` anahtarlarıyla. Sayı formatları yerel ayara göre.

## 20.9 Yayıncı (Streamer) Modu

- Şerit için yeşil ekran (chroma key) arka plan seçeneği, OBS'de kolay kesim.
- Telif güvenli müzik garantisi (tüm müzik orijinal).
- Opsiyonel: Twitch sohbet entegrasyonu (lansman sonrası): izleyiciler "!heal" ile Rahibe'yi tetikleyebilir.



# 21. Performans, Optimizasyon ve Ayarlar

## 21.1 Performans Bütçesi (Zorunlu)

| Metrik | Hedef (Widget modu, odak dışı) | Hedef (Tam mod, odakta) | Ölçüm |
|---|---|---|---|
| CPU | < %2 (4 çekirdek i5 8. nesil) | < %8 | Windows Görev Yöneticisi, 10 dk ortalama |
| GPU | < %3 | < %10 (entegre GPU'da) | |
| RAM | < 250 MB | < 350 MB | |
| FPS | 15 (odak dışı), 0 (gizli) | 60 | |
| Açılış süresi | < 3 sn (SSD) | | |
| Kurulum boyutu | < 300 MB | | |
| Pil (laptop) | Saatte < %3 ek tüketim | | |

## 21.2 Optimizasyon Teknikleri

- **Düşük işlemci modu:** `OS.low_processor_usage_mode = true` odak dışındayken; ekran sadece değişiklik olduğunda yeniden çizilir.
- **Dinamik FPS:** `Engine.max_fps` odak durumuna göre 60 / 15 / gizliyken render kapalı (`RenderingServer.render_loop_enabled = false`), simülasyon `Timer` ile devam.
- **Simülasyon ve render ayrımı:** Savaş mantığı 10 tick/sn; görsel interpolasyon.
- **Nesne havuzları:** Hasar rakamları, mermiler, VFX, düşen itemler, düşmanlar havuzlanır (oyun içinde `instantiate()` yok).
- **Texture atlasları:** Tüm UI ve item ikonları atlas; draw call < 100.
- **Parçacıklar:** `CPUParticles2D` (GL Compatibility uyumlu), max 40 parçacık / sistem; odak dışında parçacıklar yarı yoğunlukta.
- **Envanter UI:** Görünmeyen slotlar render edilmez; tooltip tek instance.
- **Kayıt:** Ana thread'i bloklamayan arka plan thread'inde JSON yazma.
- **Bellek:** Kullanılmayan perde arka planları ve müzikleri bölge değişiminde boşaltılır (ResourceLoader cache temizliği).
- **Profil testi:** Her milestone sonunda 8 saatlik "soak test": bellek sızıntısı olmamalı (RAM artışı < %5).

## 21.3 Ayarlar Menüsü

| Kategori | Ayarlar |
|---|---|
| Ekran | Ölçek (1x/2x/3x/4x), Şerit konumu (Alt/Üst/Serbest), Monitör seçimi, Her zaman üstte, Tam ekran uygulamada gizle, Şerit şeffaflığı (%50-100), Arka plan gizle (sadece karakterler) |
| Performans | Odakta FPS (30/60/144), Odak dışı FPS (5/10/15/30), Parçacık yoğunluğu, Hasar rakamları, Işık efektleri |
| Ses | Genel, Müzik, SFX, Odak dışı ses azaltma %, Kahraman sesleri, Sessiz başlat |
| Oynanış | AUTO ilerleme, Otomatik kuşanma, Ganimet filtresi, Boss'ta duraklat, Kahraman konuşma sıklığı, Bildirim türleri |
| Sistem | Windows ile başlat, Tepsiye küçült, Patron tuşu, Dil, Bulut kaydı, Kayıt yedekleri (Dışa/İçe aktar) |
| Erişilebilirlik | Renk körü modu, Yazı boyutu, Ekran sarsıntısı, Yanıp sönme azaltma, Yüksek kontrast UI |

## 21.4 Platform Notları

- **Windows:** Taskbar konumu `SHAppBarMessage(ABM_GETTASKBARPOS)` (GDExtension küçük C++ modülü veya `OS.execute` olmadan çözüm için Godot `DisplayServer.screen_get_usable_rect()` farkından hesaplanır). Tam ekran uygulama algılama: `SHQueryUserNotificationState` (QUNS_BUSY / QUNS_RUNNING_D3D_FULL_SCREEN).
- **macOS:** Dock'un üstü; menü çubuğu ikonu. Şeffaf pencere desteklenir.
- **Linux / Steam Deck:** Wayland'da always-on-top kısıtlı; Steam Deck'te "Tam Mod" varsayılan, kontrolcü desteği (D-pad ile panel navigasyonu).


# 22. Steam Entegrasyonu ve Yayın

## 22.1 Steamworks Özellikleri

- **GodotSteam** (GDExtension). `SteamService` Steam kapalıysa sessizce devre dışı (DRM-free build mümkün).
- Steam Cloud (Auto-Cloud: `%APPDATA%/Godot/app_userdata/IdleParty/saves/*`).
- Rich Presence: "Perde 2 - Donmuş Göl (Kabus) - Lv 63".
- Başarımlar (60), İstatistikler (toplam öldürme, efsanevi sayısı, kule katı).
- Liderlik Tabloları: Kule (haftalık + tüm zamanlar), Dünya Boss'u hasarı, Yarık anahtar seviyesi.
- Steam Trading Cards (lansmandan sonra, 8 kart: 8 sınıf), rozet, profil arka planları, emoji.
- Steam Deck: "Playable" hedefi.

## 22.2 Başarım Listesi (Seçki)

| ID | Ad | Koşul |
|---|---|---|
| ACH_FIRST_BLOOD | İlk Kan | İlk düşmanı öldür |
| ACH_FULL_PARTY | Tam Kadro | 5 kahramanlık partiyi tamamla |
| ACH_GOBLIN_KING | Taç Kimin? | Goblin Kralı'nı yen |
| ACH_ICE_WITCH | Bahar Geldi | Buz Cadısı Isolde'yi yen |
| ACH_TRAITOR | İhanet | Corvus'u yen |
| ACH_MORVATH | Kristal Kurtarıldı | Normal'de Morvath'ı yen |
| ACH_NIGHTMARE | Kâbuslardan Uyan | Kabus zorluğunu bitir |
| ACH_HELL | Cehennemden Dönen | Cehennem'i bitir |
| ACH_LV100 | Efsane | Bir kahramanı Lv 100 yap |
| ACH_FIRST_LEGENDARY | Turuncu Işık | İlk efsanevi itemini bul |
| ACH_FIRST_MYTHIC | İmkânsız Şans | İlk mitik itemini bul |
| ACH_SET_COMPLETE | Tam Takım | Bir seti 6/6 tamamla |
| ACH_ENHANCE_15 | Mükemmeliyet | Bir itemi +15 yap |
| ACH_COMBINE_PITY | Israrcı | Merhamet sayacıyla garantili birleştirme yap |
| ACH_FACTION_FULL | Sadakat | Bir fraksiyonu 8/8 tamamla |
| ACH_ALL_HEROES | Lonca Efsanesi | 48 kahramanın hepsini topla |
| ACH_6STAR | Altı Yıldız | Bir kahramanı 6 yıldız yap |
| ACH_TOWER_50 / 100 / 200 | Kule Tırmanıcısı I/II/III | Kule katı |
| ACH_RIFT_50 / 100 | Yarık Yürüyücüsü I/II | Yarık seviyesi |
| ACH_KILLS_10K / 100K / 1M | Katliam I/II/III | Toplam öldürme |
| ACH_GOLD_1M / 1B | Hazine I/II | Toplam altın |
| ACH_OFFLINE_12H | Uyuyan Lonca | 12 saatlik offline ödülü topla |
| ACH_NIGHT_OWL | Gece Kuşu | Gece saatlerinde 1 saat oyna |
| ACH_TREASURE_GOBLIN | Yakaladım! | Hazine Goblinini öldür |
| ACH_MOON_RABBIT | Ay Tavşanı | Ay Tavşanını yakala |
| ACH_BONBON | Bonbon'un Dostu | Vex ile 1000 iskelet çağır |
| ACH_NO_DEATH_BOSS | Kusursuz | Bir Perde boss'unu kimse ölmeden yen |
| ACH_PARAGON_100 | Sonsuzluk | Paragon 100 |

> İçerik AI notu: Toplam 60 başarım hedefle; aynı formatta tamamla (sınıf başına 2 adet "skill ustalığı" başarımı ekle).

## 22.3 Steam Mağaza Sayfası Varlıkları

| Varlık | Boyut | İçerik önerisi |
|---|---|---|
| Header Capsule | 920x430 | Logo + 5 kahraman koşarken (referans afiş tarzı) |
| Small Capsule | 462x174 | Sadece logo + 2 kahraman, okunaklı |
| Main Capsule | 1232x706 | Büyük kahraman ilüstrasyonu (yüksek detay pixel) + logo |
| Vertical Capsule | 748x896 | Dikey kompozisyon |
| Library Capsule | 600x900 | |
| Library Hero | 3840x1240 | Logo olmadan panorama |
| Library Logo | 1280x720 (şeffaf PNG) | |
| Ekran görüntüleri | 1920x1080 x 8 | 1) Masaüstünde şerit + gerçek masaüstü (Excel/kod editörü açık) — türü anlatan ana görsel; 2) 3 panel açık (Stat/Kahraman/Portre); 3) Envanter/Depo/Demirci; 4) Dünya haritası; 5) Boss savaşı; 6) Fraksiyon koleksiyonu; 7) Efsanevi drop anı; 8) Gece bölgesi |
| Fragman | 60-90 sn | İlk 5 sn: masaüstünde çalışan biri, alt kısımda şerit (konsepti anında anlat). Sonra özellikler hızlı kurgu. |

**Kısa açıklama (EN):** "Your party of five heroes fights, loots and grows on a tiny strip above your taskbar while you work. Open the menus anytime to master gear, skills and 48 collectible heroes."

**Etiketler:** Idler, RPG, Pixel Graphics, Cute, Loot, Auto Battler, Desktop Companion (varsa), Casual, Singleplayer, Fantasy, Character Customization, Hack and Slash, Relaxing.

## 22.4 Yayın Stratejisi

1. **Mağaza sayfası** erken açılır (geliştirmenin ~%40'ında) → wishlist toplama.
2. **Demo** (Perde 1, Lv 1-15, ilerleme tam oyuna aktarılır) → **Steam Next Fest**'e katılım.
3. Reddit (r/incremental_games, r/pixelart, r/IndieGaming), TikTok/YouTube Shorts: "Çalışırken oynanan oyun" kısa videoları.
4. Tür yayıncılarına ve idle oyun YouTuber'larına key gönderimi.
5. Lansman: %10-15 lansman indirimi, ilk 2 haftada 1 içerik yaması (QoL), 2. ayda ücretsiz "Perde 5" güncellemesi yol haritası duyurusu.
6. Supporter Pack DLC (2.99 USD): 6 kostüm + dijital artbook + OST.

## 22.5 Yasal ve Telif Notları

- Oyun adı ve karakter isimleri için ticari marka araştırması yap (Steam ve EUIPO/USPTO). "IDLE PARTY" çalışma adıdır.
- Hiçbir asset referans oyunlardan kopyalanmaz; tüm sanat ve müzik orijinal veya ticari lisanslı olmalı. AI ile üretilen sanat kullanılıyorsa Steam'in "AI Generated Content" beyan formunu doldur.
- Fontlar OFL lisanslı olmalı; lisans dosyaları `credits/` klasöründe.



# 23. Geliştirme Yol Haritası (Milestone'lar)

Toplam tahmini süre: **9-12 ay** (1 geliştirici + yapay zeka ajanları + 1 pixel artist veya AI destekli sanat). Her milestone sonunda çalışan bir build ve kısa bir değişiklik notu (`CHANGELOG.md`) olmalı.

## M0 - Kurulum (1 hafta)

**Görevler:**
1. Godot 4.3+ projesi oluştur, Bölüm 3.2 ayarlarını uygula, Bölüm 3.5 klasör yapısını kur.
2. Git + `.gitignore` + Git LFS (png, wav, ogg).
3. GUT veya gdUnit4 test framework; `tests/` klasörü, CI (GitHub Actions: headless test + Windows export).
4. Autoload iskeletleri (boş sınıflar + sinyaller).
5. `data/balance.json` ve şema doğrulayıcı (JSON yüklerken eksik alan hatası).

**Kabul Kriterleri:** Boş proje Windows'ta export edilip çalışıyor; testler CI'da yeşil.

## M1 - Pencere Sistemi Prototipi (2 hafta) — EN KRİTİK RİSK

**Görevler:**
1. Şeffaf, kenarlıksız, her zaman üstte şerit penceresi (320x70 mantıksal, integer scale).
2. Taskbar algılama ve otomatik konumlandırma; sürükleyerek taşıma; konum kaydetme.
3. Mouse passthrough: şeridin şeffaf alanları tıklamayı arkaya geçirir.
4. Ayrı native panel penceresi açma/kapama (`Window` node, `embed_subwindows=false`), panel sürükleme ve snap.
5. Odak/odak dışı FPS geçişi, gizleme (Patron tuşu), tray ikonu.
6. Çoklu monitör ve DPI testleri (100/125/150/200%).

**Kabul Kriterleri:** Şerit, Windows 10 ve 11'de taskbar üstünde doğru konumlanıyor; arkasındaki masaüstüne tıklanabiliyor; 2 panel aynı anda açılıp sürüklenebiliyor; odak dışında CPU < %2.

## M2 - Savaş Simülasyonu (3 hafta)

**Görevler:**
1. `BattleSim`: tick sistemi, lane tabanlı pozisyon, dalga spawn, hedefleme, menzil.
2. Hasar formülü (Bölüm 8.2) + birim testleri (DR %44 örneği dahil).
3. Placeholder sprite'larla (renkli kutular) 5 kahraman vs düşmanlar.
4. Durum etkileri, kalkan, iyileşme, ölüm/diriliş.
5. Aşama/bölge/boss akışı, AUTO ve farm modu.
6. Hasar rakamları havuzu.

**Kabul Kriterleri:** Bir bölge 10 aşama + boss olarak oynanıyor; tüm formül testleri geçiyor; 1 saatlik otomatik koşuda hata yok.

## M3 - Karakter, Stat, Level, Skill (3 hafta)

**Görevler:**
1. `classes.json`, `skills.json` (8 sınıf, temel 6 skill her biri) ve skill efekt sistemi (veri odaklı: `effect_type`, `multiplier`, `scaling_per_level`).
2. Stat sistemi (primary → derived), Stat paneli 4 sekme.
3. XP/level (Bölüm 10), stat ve skill puanı dağıtımı, sıfırlama.
4. Kahraman paneli: skill ızgarası, kuşanma, level atlama.
5. Nihai skill öfke barı.

**Kabul Kriterleri:** 8 sınıfın tüm temel skillleri çalışıyor ve tooltipleri doğru değer gösteriyor; stat paneli referans ekran düzeninde.

## M4 - Loot ve Envanter (3 hafta)

**Görevler:**
1. `items_base.json` (tüm taban türler, 7 kademe), `affixes.json`, `loot_tables.json`.
2. Item üretimi (nadirlik roll, affix roll, iLvl), Item Bulma etkisi.
3. Envanter paneli (12 ekipman slotu, 60 slot çanta, filtreler), Depo (7 sekme), sürükle-bırak, tooltip + karşılaştırma.
4. Ganimet filtresi, otomatik satış, kilitleme, "En iyisini giy".
5. Loot ışık sütunları ve sandık ikonu animasyonu.

**Kabul Kriterleri:** 10.000 item üretim testi nadirlik dağılımını ±%5 tutturuyor; envanter 120 itemle 60 FPS.

## M5 - Kayıt, Offline, Kasaba (2 hafta)

**Görevler:**
1. Kayıt/yükleme, yedek, checksum, migration.
2. Offline simülasyon ve "Sen Yokken" penceresi.
3. Kasaba sahnesi ve NPC panelleri (Tüccar, Demirci temel).
4. `TimeService` gündüz/gece.

**Kabul Kriterleri:** Oyun kapatılıp 8 saat sonra açıldığında doğru offline ödül; kayıt bozulmasında yedekten kurtarma testi.

## M6 - Sanat Üretimi Dalga 1 + Vertical Slice (4 hafta)

**Görevler:**
1. Sanat stil rehberi (Bölüm 4) ile 8 sınıf temel sprite seti (8 animasyon), 3 başlangıç kahramanı portresi.
2. Perde 1 arka planları (10 bölge x 4 katman), Perde 1 canavarları ve 10 boss.
3. UI kit (9-slice, butonlar, sekmeler, ikon setleri), fontlar.
4. VFX kütüphanesi ilk 12 efekt, shaderlar (hit flash, dissolve, outline, palette swap).
5. Açılış sekansı ve tutorial (Bölüm 20.4).
6. Müzik: ana tema + Perde 1 + boss; temel SFX.

**Kabul Kriterleri:** **Vertical Slice:** Perde 1 baştan sona (Lv 1-12, ~3 saat) final kalite görsellerle oynanabilir. 5 dış oyuncuyla test; "ilk 10 dakika" anketi.

## M7 - İçerik Genişletme (8 hafta)

**Görevler:**
1. Perde 2-4 (bölgeler, canavarlar, bosslar, mekanikler, hikaye diyalogları, ara sahneler).
2. Sınıf ilerlemeleri (Lv 30, Lv 70), tüm skiller.
3. 48 kahraman, Taverna, yıldız sistemi, fraksiyon koleksiyonu, bark sistemi.
4. Demirci tam (Birleştir/merhamet, Güçlendir, Üret, Sök), gemler, kuyumcu.
5. 80 efsanevi, 8 set, evcil hayvanlar, kostümler.
6. Kabus/Cehennem zorlukları.

**Kabul Kriterleri:** Normal→Cehennem tam oynanış; otomatik "bot koşusu" (hızlandırılmış simülasyon x100) ile Lv 100'e ulaşma süresi 45-60 saat aralığında.

## M8 - Endgame ve Steam (4 hafta)

**Görevler:**
1. Sonsuz Kule, Yarıklar, Dünya Boss'u, Paragon, günlük/haftalık görevler, Lonca Salonu, Kodeks.
2. GodotSteam: başarımlar, bulut, rich presence, liderlik tabloları.
3. Ayarlar menüsü tamamı, erişilebilirlik, lokalizasyon altyapısı (TR + EN tam).

**Kabul Kriterleri:** Tüm Steam özellikleri Steamworks test ortamında çalışıyor.

## M9 - Demo, Cila ve Denge (6 hafta)

**Görevler:**
1. Demo build (Perde 1, ilerleme aktarımı) → Steam Next Fest.
2. Denge geçişi (bkz. Bölüm 25 tabloları, telemetri isteğe bağlı ve anonim — oyuncu onayı ile).
3. Performans soak testleri, bellek sızıntısı, düşük donanım testi (entegre GPU laptop).
4. Juice: ses varyasyonları, animasyon cilası, UI geçişleri.
5. Diğer diller (profesyonel çeviri veya AI + native kontrol).

## M10 - Lansman (2 hafta) ve Sonrası

- Release Candidate, Steam inceleme süreci (build review ~3-5 iş günü), lansman fragmanı, basın kiti.
- Lansman sonrası 30 gün: haftalık hotfix, topluluk geri bildirimi, Discord.
- Yol haritası: Perde 5 (Gökyüzü Adaları), 2 yeni sınıf (Mühendis, Samuray), Sezonlar, Twitch entegrasyonu, Steam Workshop (kostüm modları).

## 23.1 Risk Tablosu

| Risk | Olasılık | Etki | Önlem |
|---|---|---|---|
| Şeffaf/çoklu pencere platform hataları | Orta | Çok yüksek | M1'de çözülür, erken prototip; olmazsa tek pencere + iç paneller fallback |
| Sanat tutarlılığı (AI üretimi) | Yüksek | Yüksek | Stil rehberi + palet kilidi + katmanlı sprite + insan rötuş |
| Denge (çok hızlı / çok yavaş) | Yüksek | Orta | Hızlandırılmış bot simülasyonu, veri odaklı katsayılar |
| İçerik miktarı | Orta | Orta | Varyant sistemi (palet swap, kademe), Perde 5 lansman sonrası |
| CPU/pil tüketimi şikâyetleri | Orta | Yüksek | Performans bütçesi her milestone'da test |


# 24. Veri Şemaları (JSON Örnekleri)

## 24.1 Sınıf

```json
{
  "id": "knight",
  "name_key": "CLASS_KNIGHT",
  "primary_stat": "STR",
  "weapon_types": ["sword", "mace", "greatsword"],
  "offhand_types": ["shield"],
  "armor_weight": "heavy",
  "base": { "hp": 220, "hp_per_lv": 38, "atk": 14, "atk_per_lv": 3.0,
            "def": 20, "def_per_lv": 4.0, "threat": 1 },
  "preferred_slots": ["front1", "front2"],
  "auto_stat_template": { "STR": 0.4, "VIT": 0.5, "DEX": 0.1 },
  "item_weights": { "STR": 1.0, "VIT": 0.9, "def_pct": 0.8, "crit": 0.3 },
  "skill_tree": ["knight_shield_bash", "knight_recovery", "..."],
  "advancements": [
    { "level": 30, "id": "knight_paladin_aspirant", "skills": ["..."] },
    { "level": 70, "choices": ["knight_holy_paladin", "knight_fortress"] }
  ]
}
```

## 24.2 Skill

```json
{
  "id": "archer_earth_strike",
  "class": "archer",
  "type": "active",
  "max_level": 5,
  "cooldown": 8.2,
  "cooldown_per_level": 0,
  "requires": [{ "skill": "archer_multishot", "level": 1 }],
  "targeting": { "mode": "enemies_in_range", "range": 3.5, "max_targets": 3 },
  "effects": [
    { "type": "damage", "element": "physical",
      "multiplier": 1.30, "multiplier_per_level": 0.325 }
  ],
  "vfx": "vfx_earth_spike", "sfx": "sfx_earth_strike",
  "anim": "skill", "impact_frame": 5,
  "icon": "skill_archer_earth_strike"
}
```

## 24.3 Taban Item ve Üretilmiş Item

```json
{ "id": "bow_t3", "slot": "weapon", "type": "bow", "tier": 3, "req_level": 25,
  "name_key": "ITEM_BOW_T3", "base_atk": 14, "aps": 1.0,
  "implicit": [{ "stat": "attack_speed_pct", "value": 5 }],
  "classes": ["archer"], "icon": "item_weapon_bow_t3" }
```

```json
{ "uid": "it_8f2a91", "base": "bow_t3", "ilvl": 31, "rarity": "rare",
  "affixes": [
    { "id": "flat_attack", "tier": 3, "value": 62 },
    { "id": "crit_chance", "tier": 3, "value": 1.9 },
    { "id": "dex", "tier": 2, "value": 9 }
  ],
  "enhance": 4, "sockets": [], "locked": false, "legendary_id": null }
```

## 24.4 Düşman ve Bölge

```json
{ "id": "a1_goblin_warrior", "type": "normal", "family": "goblin",
  "hp_mult": 1.0, "atk_mult": 1.0, "range": 18, "aps": 0.9,
  "targeting": "front", "resists": { "fire": 0, "cold": 0 },
  "drops": "lt_a1_goblin", "xp_mult": 1.0, "sprite": "enemy_a1_goblin_warrior" }
```

```json
{ "id": "a1_z03", "act": 1, "index": 3, "name_key": "ZONE_MISTY_FOREST_PATH",
  "level_range": [3, 5], "stages": 10, "waves_per_stage": 5,
  "enemies": [ { "id": "a1_goblin_apprentice", "weight": 50 },
               { "id": "a1_mushroom", "weight": 30 },
               { "id": "a1_wolf", "weight": 20 } ],
  "elite_chance": 0.2, "boss": "a1_goblin_scout_chief", "boss_time": 60,
  "background": "bg_a1_z03", "music": "mus_act1", "weather": "fog",
  "legendary_pool": ["leg_goblin_crown"] }
```

## 24.5 Kahraman

```json
{ "id": "lyra", "class": "archer", "faction": "wildlands", "rarity": "R",
  "visual": { "base": "hero_archer_base", "hair": "ponytail_long",
              "palette": "pal_lyra", "accessory": "elf_ears" },
  "signature": { "id": "elf_eye", "stat": "crit_chance", "values": [5, 6, 7, 8, 10, 12] },
  "barks": "barks_lyra", "unlock": "story_a1_z01" }
```


# 25. Denge Tabloları

## 25.1 Canavar Ölçekleme (Normal zorluk)

| Lv | Normal HP | Normal Saldırı | Elit HP | Boss HP | Altın/Öldürme |
|---|---|---|---|---|---|
| 1 | 43 | 9 | 150 | 1,075 | 4 |
| 5 | 57 | 11 | 200 | 1,425 | 9 |
| 10 | 82 | 15 | 287 | 2,050 | 19 |
| 20 | 170 | 28 | 595 | 4,250 | 42 |
| 30 | 350 | 53 | 1,225 | 8,750 | 70 |
| 40 | 722 | 99 | 2,527 | 18,050 | 100 |
| 50 | 1,488 | 186 | 5,208 | 37,200 | 132 |
| 60 | 3,066 | 350 | 10,731 | 76,650 | 167 |
| 70 | 6,319 | 657 | 22,116 | 157,975 | 203 |
| 80 | 13,024 | 1,233 | 45,584 | 325,600 | 241 |
| 90 | 26,842 | 2,315 | 93,947 | 671,050 | 281 |
| 100 | 55,323 | 4,346 | 193,630 | 1,383,075 | 321 |

## 25.2 Denge Hedefleri

- Normal düşman, aynı leveldeki "ortalama ekipmanlı" partiye karşı **1.2-2.0 sn** içinde ölmeli.
- Boss, uygun leveldeki partiye karşı **25-45 sn**'de ölmeli (zaman sınırı 60 sn).
- Parti, kendi levelindeki normal dalgada ölmemeli; 3 level üstü bölgede %10-30 ölüm şansı (zorluk sinyali).
- Ortalama ekipmanlı Lv L kahramanın DPS'i ≈ `EnemyHP(L) x 4 / 1.6` (4 düşmanlık dalgayı ~6 sn'de temizleyen parti). Bot simülasyonu bu hedefi her 10 levelde doğrular.
- Efsanevi item ilk bulma süresi: Perde 1 Boss garantisi hariç, ortalama 4-6 saatte bir (Normal), 1-2 saatte bir (Cehennem).

## 25.3 Kahraman Güç Kontrol Listesi (Her Sınıf İçin)

- Tek hedef DPS, alan DPS, hayatta kalma ve destek puanları 1-5 skalasında; hiçbir sınıf tüm alanlarda 4+ olamaz.
- Her sınıf en az 2 uygulanabilir build'e sahip olmalı (uzmanlık A ve B).


# 26. Yapay Zeka Prompt Kütüphanesi

## 26.1 Kod AI'ı İçin Görev Şablonu

```
ROL: Kıdemli Godot 4 (GDScript, statik tipli) oyun geliştiricisi.
BAĞLAM: "IDLE PARTY: Desktop Legends" GDD'si. Şu an Milestone M<x>, görev <y>.
KURALLAR:
- Veri odaklı: değerleri data/*.json'dan oku, koda sabit yazma.
- Simülasyon (scripts/sim) render'dan bağımsız; UI sadece EventBus sinyallerini dinler.
- Her yeni sistem için tests/ altına birim testi yaz.
- Performans bütçesi: odak dışında CPU < %2. Process fonksiyonlarında tahsis (allocation) yapma.
- Kod, değişken ve dosya adları İngilizce; oyuncuya görünen metin tr()/lokalizasyon anahtarı.
ÇIKTI: Değişen dosyaların tam içeriği + kısa açıklama + test sonucu.
GÖREV: <görev metni ve kabul kriterleri buraya>
```

## 26.2 Pixel Art AI'ı İçin Ana Stil Promptu (İngilizce)

```
Cute 16-bit style pixel art, chibi proportions (head:body = 1:1.5), 32x32 pixel
canvas, character around 22 pixels tall, clean 1px dark purple-brown outline
(#2B1B2E, not pure black), limited palette (max 16 colors per sprite), 3-tone cel
shading with hue shifting (cool shadows, warm highlights), light from top-left,
readable silhouette at small size, no anti-aliasing, no gradients, no blur, no
dithering noise, transparent background, side view facing right, consistent with
a cozy fantasy idle RPG like "My Party Is Grinding".
```

**Sınıf sprite örneği:**

```
[ANA STİL PROMPTU] + Knight hero: young man with messy black hair, silver plate
armor with blue cape, round shield on left arm, short sword in right hand.
Sprite sheet, 6 frames horizontal strip, attack animation: anticipation (pull
back), swing, impact frame 4 with motion arc, follow-through, recover.
Each frame 32x32, no spacing between frames.
```

**Portre örneği (Kahraman paneli):**

```
Detailed pixel art full-body character portrait, 96x144 pixels, realistic
anime proportions (1:6), standing pose, elf archer girl with long blonde
ponytail, pink and white light armor, holding a longbow, quiver on back,
confident smile. Background: none (transparent). 32-color palette, clean dark
outlines, soft cel shading, high-quality 16-bit JRPG portrait style.
```

**Arka plan örneği:**

```
Pixel art parallax background layer, 480x70 pixels, seamlessly tileable
horizontally, misty forest with tall pine trees, muted desaturated greens and
blues (lower contrast than characters), soft morning fog, layer: MID (trees only,
transparent sky). Cozy fantasy idle RPG style, no characters.
```

**Item ikonu örneği:**

```
Pixel art item icon, 16x16 pixels, 1px padding, legendary golden longbow with
glowing orange runes, dark outline, 3-tone shading, transparent background,
inventory icon style, top-left light.
```

**UI kit örneği:**

```
Pixel art game UI kit, dark brown wood and iron frame, 9-slice panel with 8px
corners and gold rivets, ornate title plaque centered on top edge, orange active
tab button, brown inactive tab, blue secondary button, red square close button
with white X, dark semi-transparent inner background (#1E1A1F). Fantasy RPG.
```

## 26.3 Müzik AI'ı İçin Prompt

```
Cozy fantasy RPG background music, lute, wooden flute, light strings and soft
chiptune arpeggios, 90 BPM, warm and relaxing but adventurous, seamless loop,
3 minutes, no vocals, suitable for playing quietly while working.
```

## 26.4 Sanat Tutarlılık Kontrol Listesi

- [ ] Tuval boyutu doğru (32x32 / 16x16 / 96x144)?
- [ ] Kontur rengi #2B1B2E, 1 px, kesintisiz?
- [ ] Anti-aliasing / yarı saydam kenar pikseli yok mu?
- [ ] Palet ana paletten mi (palet kilidi scripti ile kontrol: `tools/palette_check.py`)?
- [ ] Işık sol üstten mi?
- [ ] Silüet 2x ölçekte, 1 metre uzaktan tanınıyor mu?
- [ ] Karakterler arka plandan daha doygun mu?
- [ ] Kare sayısı ve impact frame dokümana uygun mu?


# 27. Kalite Güvence (QA) Kontrol Listesi

| Alan | Test |
|---|---|
| Pencere | Win10/Win11, taskbar alt/üst/sol/sağ, otomatik gizlenen taskbar, 2 monitör farklı DPI, uyku modundan dönüş |
| Performans | 8 saat soak test, odak dışı CPU, laptop pil modu, entegre GPU |
| Kayıt | Elektrik kesintisi simülasyonu (kayıt sırasında süreci öldür), bulut çakışması, eski sürüm kaydı migration |
| Offline | Saat geri alma hilesi (sistem saati geri alınırsa offline ödül 0), 12/24 saat sınırı |
| Oynanış | Tüm sınıf/skill kombinasyonları, boss mekanikleri, ölüm döngüsü, envanter doluyken loot |
| Ekonomi | Altın/malzeme taşması (int64), birleştirme merhamet sayacı, güçlendirme olasılık doğrulama (10.000 deneme) |
| UI | Tüm diller metin taşması, 1x-4x ölçek, renk körü modu, klavye kısayolları |
| Steam | Başarımlar, bulut, Steam kapalıyken çalışma, Steam Deck |

---

**Doküman sonu.** Bu GDD canlı bir dokümandır. Yapay zeka ajanı, uygulama sırasında aldığı her tasarım kararını `docs/DECISIONS.md` dosyasına, her denge değişikliğini `data/balance.json` değişiklik notuna kaydetmelidir.
