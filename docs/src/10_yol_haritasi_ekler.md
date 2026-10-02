\pagebreak

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

\pagebreak

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

\pagebreak

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

\pagebreak

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

\pagebreak

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
