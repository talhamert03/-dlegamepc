# IDLE PARTY: Desktop Legends

Ekranın altında ince bir şerit olarak çalışan, masaüstü widget tarzı **idle / auto-battler pixel RPG**.
Partin sen çalışırken kendi kendine savaşır, loot toplar ve seviye atlar; panelleri açıp ekipman,
skill, parti ve lonca gelişimini yönetirsin. Godot 4.4 ile yazıldı, tüm sanat ve sesler
`tools/` altındaki betiklerle prosedürel olarak üretilir.

## Oyunu indir ve oyna (Windows)

> Yeşil **Code → Download ZIP** düğmesi oyunu değil, **kaynak kodu** indirir; içinde `.exe` yoktur.

1. GitHub'a giriş yap ve **Actions** sekmesini aç:
   https://github.com/talhamert03/-dlegamepc/actions?query=branch%3Aclaude%2Fparty-grinding-game-design-kdffl4
2. En üstteki yeşil tikli **CI** çalışmasına tıkla.
3. Sayfanın en altındaki **Artifacts** bölümünden **IdleParty-windows**'u indir (~245 MB).
4. Zip'e sağ tık → **Tümünü ayıkla**, sonra klasördeki **IdleParty.exe**'yi çalıştır
   (tek dosya; oyunun tüm verisi exe'nin içinde).
5. SmartScreen "Windows bilgisayarınızı korudu" derse: **Ek bilgi → Yine de çalıştır**.

Kaynak koddan çalıştırmak için: Godot **4.4.1**'i indir, **Import** ile `game/project.godot`'u aç, **F5**.

## Hızlı başlangıç

```bash
# Godot 4.4.1 gerekli (https://godotengine.org)
cd game
godot                        # oyunu çalıştır (ilk açılışta başlık ekranı + giriş hikayesi)
godot -- --title             # başlık ekranını zorla
./run_tests.sh               # headless test paketi
godot --headless res://tests/BalanceBot.tscn -- --hours=8   # denge botu (simüle oyun süresi)
```

**Windows/Linux build:** GitHub Actions (`.github/workflows/ci.yml`) her push'ta testleri ve 2 saatlik
denge botunu çalıştırır, ardından `IdleParty-windows` ve `IdleParty-linux` artifact'lerini üretir.
Yerelde: export template'lerini kurup `godot --headless --export-release "Windows Desktop" ../export/windows/IdleParty.exe`.

## Kısayollar

| Tuş | Panel |
|---|---|
| H / C | Kahraman (statlar + ekipman + portre) |
| I / B | Çanta |
| M | Dünya haritası / Sonsuz Kule |
| G | Gelişim (lonca salonu) |
| P | Parti |
| T | Taverna |
| E | Evcil dostlar |
| J | Görevler |
| D | DPS ölçer |
| Ctrl+Shift+H | Tüm pencereleri gizle/göster |

## İçerik

- 12 sınıf, 48 kahraman (6 fraksiyon, R/SR/SSR), 120 skill, 2 sınıf ilerlemesi + uzmanlık
- 4 perde, 40 bölge, 74 düşman türü, 40 boss (perde bossları mekanikli), 3 zorluk (Normal / Kabus / Cehennem)
- Loot: 6 nadirlik + set + efsanevi, demirci (geliştirme, yeniden dövme, parçalama), sandık
- Offline ilerleme, taverna, görevler, 41 başarım, kodeks, lonca salonu ağacı
- **Sonsuz Kule** (Sv 50 / Kabus açılınca), **10 evcil dost** (boss ve kule düşüşleri), **6 kostüm**, hikaye girişi ve finali
- TR/EN dil, 21 SFX + 7 müzik parçası
- Tek şeffaf overlay penceresi: şerit + sürüklenebilir paneller, boş alanlar tıklamayı masaüstüne geçirir

## Proje yapısı

```
game/
  data/          tüm denge ve içerik JSON dosyaları (balance, classes, skills, heroes, items, enemies, zones, pets...)
  scripts/core   autoload'lar (EventBus, DataDB, GameState, WindowManager, AudioManager...)
  scripts/sim    deterministik savaş simülasyonu (UI'dan bağımsız, 0.1 sn tick)
  scripts/systems formüller, loot, stat hesaplama, offline, demirci, taverna, görevler
  scripts/ui     şerit görünümü, panel pencereleri, başlık/final ekranları
  tests/         birim testleri + denge botu
tools/
  art/           yapay zeka görsel boru hattı (ai_prompts, ai_jobs, import_ai_art), HD UI üretici (build_ui_hd)
                 ve yedek prosedürel pixel-art üreticileri
  audio/         prosedürel SFX/müzik üretici (ffmpeg ile ogg)
  data/          dünya/düşman/bölge verisi üretici
docs/            GDD (PDF + Markdown) ve teknik kararlar
```

Karakter ve arka plan görselleri yapay zeka ile üretildi (`game/assets/hd/`, ayrıntı: `docs/DECISIONS.md` → Sanat).
HD UI: `python3 tools/art/build_ui_hd.py`. Yedek prosedürel varlıklar: `python3 tools/art/build_heroes.py`, `build_enemies.py`,
`build_backgrounds.py`, `build_ui.py`, `build_icons.py`, `build_maps.py`; ses için `python3 tools/audio/build_audio.py`.

## Dokümanlar

- `docs/IdleParty_GDD.pdf` / `.md` — tam oyun tasarım dokümanı ve yapay zeka yol haritası
- `docs/DECISIONS.md` — geliştirme sırasında alınan teknik kararlar ve bilinen sınırlamalar
