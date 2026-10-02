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
- **Karakterler ve arka planlar yapay zeka ile üretildi** (Higgsfield, `gpt_image_2_5`), tek bir stil tarifiyle:
  yüksek çözünürlüklü, detaylı anime pixel-art. Boru hattı:
  `tools/art/ai_prompts.py` (promptlar) → `tools/art/ai_jobs.py` (iş/URL kaydı, `art_src/jobs_*.json`, `urls_*.json`) →
  `tools/art/import_ai_art.py <heroes|enemies|pets|bg>` (indir, kırp, ayak hizası, portre 560px, yüz ortalı ikon) →
  `game/assets/hd/...` + `meta.json`. Ham indirmeler `art_src/raw/` altında (git dışı).
- Arka planlar 21:9 panoramadan alt bant kesilerek 336px (şeridin 4 katı) yüksekliğe indirilir; `strip_view.gd` aynalı
  tekrarla kaydırır. HD arka plan yoksa eski prosedürel parallax katmanları kullanılır.
- **HD birimler tek görsel + prosedürel animasyon** (idle/koşu/saldırı/yetenek/vuruş/ölüm/zafer), pivot ayaklarda.
  `unit.gdshader` `texel_scale` ile dış hat/çözülme efektlerini mantıksal piksel boyutunda tutar; kostümler aynı shader ile renk değiştirir.
- UI: Cinzel/Nunito (OFL, Türkçe karakterli) fontlar, `UIFrame` vektör çerçeveler, `tools/art/build_ui_hd.py` ile HD ikon/küre/slot.
- Eski prosedürel pixel-art boru hattı (`tools/art/pixelrig.py`, `chars.py`) yedek olarak duruyor; HD görseli olmayan birimler onu kullanır.
- Bir karakteri yeniden üretmek: promptunu `ai_prompts.py` içinde düzenle, yeni işin URL'sini `urls_<tür>.json`'a yaz,
  `import_ai_art.py <tür> <id>` çalıştır.

## Bilinen sınırlamalar / sonraki adımlar
- **Steam:** `SteamService` şimdilik stub (başarım ve skor çağrıları loglanır). GodotSteam eklentisi eklenince doldurulacak.
- **Kostümler:** 6 hesap çapında kostüm, kahramanın ana renk rampasını shader ile yeniden renklendirir (yeni sprite gerekmez). Kalıp/aksesuar değiştiren kostümler henüz yok.
- macOS export preset'i yok (imzalama/notarization gerektirir).
- Yalnızca TR/EN dil desteği.
