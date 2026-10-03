# Teknik Kararlar (Decision Log)

GDD'deki yol haritası uygulanırken alınan kararlar ve nedenleri. Yeni bir geliştirici (insan ya da
yapay zeka) projeye katılmadan önce bu dosyayı okumalı.

## Motor ve pencereler
- **Godot 4.4.1, GL Compatibility.** Eski/entegre GPU'larda da çalışsın, şerit sürekli açık kalacağı için düşük güç tüketimi.
- **Tek şeffaf overlay penceresi.** Şerit, paneller ve tooltip aynı kenarlıksız, her zaman üstte, şeffaf pencerede
  Control olarak çizilir; pencere kullanılabilir ekran alanını (görev çubuğu hariç) kaplar. Windows + OpenGL'de şeffaf ikincil
  pencereler siyah/görünmez çıktığı için çoklu native pencereden vazgeçildi.
- **Tıklama geçirgenliği:** `mouse_passthrough_polygon`, görünür UI dikdörtgenlerinin birleşim dış hattıdır
  (`WindowManager.union_outline`: koordinat sıkıştırma → yönlü sınır kenarları → sıfır genişlikli köprülerle birleşen döngüler;
  hem even-odd hem nonzero kuralında doğru). Windows'ta bu bir pencere bölgesidir, dışındaki her şey masaüstüne geçer.
- **Ölçek:** `content_scale_mode=canvas_items`, tam sayı `ui_scale` (1920x1080/1200 → 3x, 2560x1440 → 4x, 1366x768 → 2x).
  Yazılar ve vektör çerçeveler native çözünürlükte çizildiği için keskin kalır.
- **Yerleşim:** şerit görev çubuğunun hemen üstünde, ortada. Paneller kendi "ev" konumlarında açılır, doluysa en yakın boş yere kayar.
  Başlık çubuğundan sürüklenir, kenarlara yapışır, ekrandan taşmaz; kapatılıp açılan panel ev konumuna döner. Esc en üstteki paneli kapatır.
- **Yerleşik tooltip'ler kapalı** (`gui/timers/tooltip_delay_sec`). `WindowManager._route_tooltips` aynı `tooltip_text`'i
  overlay içindeki kendi tooltip Control'ümüzde gösterir.
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
- **Görsel hedef: TBH: Task Bar Hero kalitesi.** Kompakt şerit (360x72 mantıksal, 1080p'de 2x), küçük chibi
  karakterler, gerçek kare animasyonu, demir çerçeveli paneller ve kırmızı başlık kurdeleleri.
- **Savaş sprite'ları: animasyonlu chibi sheet'ler** (`assets/hd/anim/`). Her birim için tek AI görseli
  (gpt_image_2_5, referans = birimin HD illüstrasyonu): 6x4 kare — idle, koşu, saldırı, hasar+ölüm.
  `tools/art/ai_sheets.py` promptları ve iş kayıtlarını tutar, `tools/art/import_sheets.py` arka planı ayıklar,
  kareleri böler ve ayak noktasına hizalar (titreme yok). Sheet'i olmayan birimler HD illüstrasyon + prosedürel
  harekete düşer.
- `UnitView` saldırı karesini simülasyonun vuruş anına (`act_impact`) senkronlar; yakın dövüşçüler hedefe atılır,
  menzilliler geri teper; vuruşta flaş, geri itme, kritikte vuruş donması (hit-stop) ve sarsıntı.
- Ekipman ikonları: iki AI ikon sayfasından (`art_src/urls_items.json`, `tools/art/import_items.py`) 36 tip x 2 görünüm;
  tier 0-2 sade, tier 3+ süslü/büyülü. Slot arka planı nadirlik rengiyle dolu (TBH tarzı).
- HD illüstrasyonlar portre, kahraman penceresi ve sinematik girişte kullanılır; arka planlar JPEG.
- UI: `UISkin` (tamamen vektör: demir panel, kurdele, bronz madalyon, ahşap buton, nadirlik renkli slot),
  `GameStyleBox` ile tüm Button'lara uygulanır. Fontlar Cinzel/Nunito (OFL).
- Ses: `tools/audio/build_sfx_hd.py` katmanlı vuruş sesleri (darbe + gövde + metal tınısı + oda yankısı),
  `tools/audio/build_music_hd.py` lavta/arp, yaylı pad, flüt, davul ve salon yankısıyla döngüsel müzikler.

## Bilinen sınırlamalar / sonraki adımlar
- **Steam:** `SteamService` şimdilik stub (başarım ve skor çağrıları loglanır). GodotSteam eklentisi eklenince doldurulacak.
- **Kostümler:** 6 hesap çapında kostüm, kahramanın ana renk rampasını shader ile yeniden renklendirir (yeni sprite gerekmez). Kalıp/aksesuar değiştiren kostümler henüz yok.
- macOS export preset'i yok (imzalama/notarization gerektirir).
- Yalnızca TR/EN dil desteği.
- **Animasyon sheet'i eksik birimler:** 27/48 kahraman ve 16/112 düşman-boss sheet'li (kredi sınırı). Kalanlar
  `ai_sheets.py batch` + `import_sheets.py` ile aynı boru hattından üretilebilir (~0.25 kredi/sheet).

## Taskbar mode, chests, runes, status (TBH parity round)
- Minimising never pauses: the overlay window is restored at once as a slim framed battle bar sitting on
  the taskbar left of the tray (offset ~300 px * DPI, draggable along the taskbar, remembered). The window is
  re-raised above the taskbar every 1.5 s; the click-through region keeps only the bar (and the chest bubble)
  visible. Toggle: Settings → "Taskbar mode when minimised".
- Chests: five vector-drawn rarities (wood, iron, gold, crystal, royal). Drop chance per kill by enemy type
  (normal 0.45 %, elite 6 %, boss 60 %, act boss 100 %), rarity table by type, "Chest Find" from runes.
  Rewards scale with the kill level: gold worth N normal kills, items with a guaranteed minimum rarity, mats.
- Rune tree: account-wide gold sink (46 nodes, 4 branches) on a pannable board; a node opens when a linked
  node has a rank. Costs grow 2.3x per ring and 1.6x per rank. Bonuses feed account_mods.
- Status panel replaces the separate skills window: parchment stat sheet + skill tiers on a red level rail
  at the real unlock levels (1 / 30 advancement / 70 specialisation).
