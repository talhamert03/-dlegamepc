# IDLE PARTY: Desktop Legends

Ekranın altında ince bir şerit olarak çalışan, masaüstü widget tarzı **idle / auto-battler pixel RPG**.
Partin sen çalışırken kendi kendine savaşır, loot toplar ve seviye atlar; panelleri açıp ekipman,
skill, parti ve lonca gelişimini yönetirsin. Godot 4.4 ile yazıldı, tüm sanat ve sesler
`tools/` altındaki betiklerle prosedürel olarak üretilir.

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
  art/           prosedürel pixel-art üreticileri (kahraman, düşman, evcil, arka plan, UI, ikon, harita)
  audio/         prosedürel SFX/müzik üretici (ffmpeg ile ogg)
  data/          dünya/düşman/bölge verisi üretici
docs/            GDD (PDF + Markdown) ve teknik kararlar
```

Sanat varlıklarını yeniden üretmek: `python3 tools/art/build_heroes.py`, `build_enemies.py`,
`build_backgrounds.py`, `build_ui.py`, `build_icons.py`, `build_maps.py`; ses için `python3 tools/audio/build_audio.py`.

## Dokümanlar

- `docs/IdleParty_GDD.pdf` / `.md` — tam oyun tasarım dokümanı ve yapay zeka yol haritası
- `docs/DECISIONS.md` — geliştirme sırasında alınan teknik kararlar ve bilinen sınırlamalar
