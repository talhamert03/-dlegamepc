\pagebreak

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

\pagebreak

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

\pagebreak

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
